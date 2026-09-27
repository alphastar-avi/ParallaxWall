import Foundation
import IOKit
import IOKit.hid
import Combine
import CoreMotion

public enum MotionSource: String, CaseIterable, Identifiable {
    case mac = "Mac"
    case airpods = "AirPods"
    
    public var id: String { rawValue }
    
    public var displayName: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .mac:
            return "macbook"
        case .airpods:
            return "airpods.pro"
        }
    }
}

public enum MotionEngineState: String, CaseIterable {
    case active = "Active"
    case resting = "Resting"
    case occluded = "Paused (Occluded)"
    
    public var badgeTitle: String {
        switch self {
        case .active: return "Tracking"
        case .resting: return "Resting (0% CPU)"
        case .occluded: return "Covered (Paused)"
        }
    }
}

class SensorManager: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate {
    // Internal and direct read for rotation coordinates
    public private(set) var rotation = (x: Double(0), y: Double(0), z: Double(0))
    
    // High-frequency stream for parallax rendering without triggering full-view SwiftUI re-evaluations
    public let rotationPublisher = PassthroughSubject<(x: Double, y: Double, z: Double), Never>()
    
    @Published var baseRotation = (x: Double(0), y: Double(0), z: Double(0))
    
    // Configurable Low-pass filter smoothing factor (0.01 = Ultra Smooth, 0.25 = Raw/Direct)
    @Published var smoothing: Double = 0.05
    
    // User-facing smoothing property (0.0 = Raw/Direct, 1.0 = Ultra Smooth)
    var userSmoothing: Double {
        get {
            let clamped = max(0.01, min(0.25, smoothing))
            return (0.25 - clamped) / 0.24
        }
        set {
            let clampedUser = max(0.0, min(1.0, newValue))
            smoothing = 0.25 - (clampedUser * 0.24)
            objectWillChange.send()
        }
    }
    
    // Configurable sampling rate in Hz (5 Hz - 100 Hz). Default: 30 Hz.
    @Published var targetSamplingRate: Double = {
        let saved = UserDefaults.standard.double(forKey: "sensorSamplingRate")
        return saved >= 5.0 && saved <= 100.0 ? saved : 30.0
    }() {
        didSet {
            UserDefaults.standard.set(targetSamplingRate, forKey: "sensorSamplingRate")
            updateSamplingTimer()
        }
    }
    
    // Configurable idle noise deadzone (5.0 - 1000.0 units). Default: 150.0 units.
    @Published var idleDeadzone: Double = {
        let saved = UserDefaults.standard.double(forKey: "sensorIdleDeadzone")
        return saved >= 5.0 && saved <= 1000.0 ? saved : 150.0
    }() {
        didSet {
            UserDefaults.standard.set(idleDeadzone, forKey: "sensorIdleDeadzone")
        }
    }
    
    // Full-screen app / Stage manager occlusion state
    @Published var isOccluded: Bool = false {
        didSet {
            updateSamplingTimer()
        }
    }
    
    // Current runtime engine state for Dev / Tuning UI
    @Published var engineState: MotionEngineState = .resting
    
    // Motion Source selection (Mac Hardware vs. AirPods Spatial Motion)
    @Published var motionSource: MotionSource = .mac {
        didSet {
            switchMotionSource(to: motionSource)
        }
    }
    
    @Published var isAirPodsAvailable: Bool = false
    @Published var isAirPodsConnected: Bool = false
    
    // Resting baseline & raw hardware cache
    private var baselineX: Double = 0
    private var baselineY: Double = 0
    private var baselineZ: Double = 0
    private var hasBaseline: Bool = false
    
    private var latestRawX: Double = 0
    private var latestRawY: Double = 0
    private var latestRawZ: Double = 0
    
    private var settleCounter: Int = 0
    private var lastSampleX: Double = 0
    private var lastSampleY: Double = 0
    private var sampleTimer: Timer?
    
    private var hidDevice: IOHIDDevice?
    private var reportBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
    private let headphoneManager = CMHeadphoneMotionManager()
    
    override init() {
        super.init()
        setupSensor()
        setupAirPodsMotion()
        updateSamplingTimer()
    }
    
    deinit {
        sampleTimer?.invalidate()
        if let device = hidDevice {
            IOHIDDeviceClose(device, 0)
        }
        reportBuffer.deallocate()
        stopAirPodsMotion()
    }
    
    func calibrate() {
        self.baseRotation = self.rotation
        self.baselineX = self.latestRawX
        self.baselineY = self.latestRawY
        self.baselineZ = self.latestRawZ
        self.hasBaseline = true
        self.engineState = .resting
        self.rotationPublisher.send(self.rotation)
    }
    
    func resetPerformanceDefaults() {
        targetSamplingRate = 30.0
        idleDeadzone = 150.0
        userSmoothing = 0.5
    }
    
    // MARK: - Smart Rate-Limited Motion Sampling Engine
    
    private func updateSamplingTimer() {
        sampleTimer?.invalidate()
        sampleTimer = nil
        
        if isOccluded {
            engineState = .occluded
            return
        }
        
        let interval = 1.0 / max(5.0, min(100.0, targetSamplingRate))
        sampleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tickSampling()
        }
    }
    
    private func tickSampling() {
        guard !isOccluded else {
            if engineState != .occluded { engineState = .occluded }
            return
        }
        
        if !hasBaseline {
            if latestRawX != 0 || latestRawY != 0 || latestRawZ != 0 {
                baselineX = latestRawX
                baselineY = latestRawY
                baselineZ = latestRawZ
                hasBaseline = true
                rotation = (x: baselineX, y: baselineY, z: baselineZ)
                lastSampleX = baselineX
                lastSampleY = baselineY
                if engineState != .resting {
                    engineState = .resting
                }
            }
            return
        }
        
        let rawDeltaX = latestRawX - baselineX
        let rawDeltaY = latestRawY - baselineY
        let rawDist = sqrt(rawDeltaX * rawDeltaX + rawDeltaY * rawDeltaY)
        
        // Desk Rest Deadzone: If total jitter/motion from baseline is within deadzone, hold completely still
        if rawDist <= idleDeadzone {
            if engineState == .resting {
                settleCounter = 0
                return // Zero CPU, zero publisher emissions when resting on desk!
            }
            
            // If we were active, smooth back down to baseline
            let diffX = baselineX - rotation.x
            let diffY = baselineY - rotation.y
            if abs(diffX) < 3.0 && abs(diffY) < 3.0 {
                rotation = (x: baselineX, y: baselineY, z: baselineZ)
                rotationPublisher.send(rotation)
                engineState = .resting
                settleCounter = 0
                return
            }
            
            let newX = rotation.x + diffX * smoothing
            let newY = rotation.y + diffY * smoothing
            rotation = (x: newX, y: newY, z: baselineZ)
            rotationPublisher.send(rotation)
            return
        }
        
        // Active Motion: Movement exceeds desk deadzone!
        if engineState != .active {
            engineState = .active
        }
        
        // Continuous Deadband tracking: Start smoothly from 0 offset past deadzone to eliminate stair-step jumps
        let excess = rawDist - idleDeadzone
        let dirX = rawDeltaX / rawDist
        let dirY = rawDeltaY / rawDist
        let targetX = baselineX + dirX * excess
        let targetY = baselineY + dirY * excess
        
        let diffX = targetX - rotation.x
        let diffY = targetY - rotation.y
        let newX = rotation.x + diffX * smoothing
        let newY = rotation.y + diffY * smoothing
        let newZ = latestRawZ
        
        // Settle check: If user holds device steady at new tilt angle for ~0.35s, lock new baseline
        let stepVelocity = sqrt(pow(newX - lastSampleX, 2) + pow(newY - lastSampleY, 2))
        lastSampleX = newX
        lastSampleY = newY
        
        if stepVelocity < max(1.5, idleDeadzone * 0.05) {
            settleCounter += 1
            let settleFramesRequired = max(3, Int(targetSamplingRate * 0.35))
            if settleCounter >= settleFramesRequired {
                baselineX = newX
                baselineY = newY
                rotation = (x: newX, y: newY, z: newZ)
                rotationPublisher.send(rotation)
                engineState = .resting
                settleCounter = 0
                return
            }
        } else {
            settleCounter = 0
        }
        
        rotation = (x: newX, y: newY, z: newZ)
        rotationPublisher.send(rotation)
    }
    
    // MARK: - Mac Hardware SPU Sensor Setup
    
    func setupSensor() {
        // 1. Wake up the SPU drivers
        wakeSPUDrivers()
        
        // 2. Find the Accelerometer HID device
        guard let device = findAccelerometerDevice() else {
            print("Failed to find accelerometer device")
            return
        }
        
        self.hidDevice = device
        
        // 3. Open the device
        let kr = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard kr == kIOReturnSuccess else {
            print("Failed to open HID device: \(kr)")
            return
        }
        
        // 4. Register callback
        let callback: IOHIDReportCallback = { (context, result, sender, type, reportID, report, reportLength) in
            guard let context = context else { return }
            let manager = Unmanaged<SensorManager>.fromOpaque(context).takeUnretainedValue()
            manager.handleReport(report: report, length: reportLength)
        }
        
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device, reportBuffer, 64, callback, context)
        
        // 5. Schedule with run loop
        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        
        print("Sensor Manager initialized and reading data")
    }
    
    private func wakeSPUDrivers() {
        let matching = IOServiceMatching("AppleSPUHIDDriver")
        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        
        if kr == kIOReturnSuccess {
            var service = IOIteratorNext(iterator)
            while service != 0 {
                let props: [(String, Int32)] = [
                    ("SensorPropertyReportingState", 1),
                    ("SensorPropertyPowerState", 1),
                    ("ReportInterval", 10000) // 10ms
                ]
                
                for (key, val) in props {
                    let cfKey = key as CFString
                    var mutableVal = val
                    let cfVal = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &mutableVal)
                    IORegistryEntrySetCFProperty(service, cfKey, cfVal)
                }
                
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
    }
    
    private func findAccelerometerDevice() -> IOHIDDevice? {
        let matching = IOServiceMatching("AppleSPUHIDDevice")
        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        
        if kr == kIOReturnSuccess {
            var service = IOIteratorNext(iterator)
            while service != 0 {
                let usagePage = getIntProperty(service: service, key: "PrimaryUsagePage")
                let usage = getIntProperty(service: service, key: "PrimaryUsage")
                
                if usagePage == 0xFF00 && usage == 3 {
                    let device = IOHIDDeviceCreate(kCFAllocatorDefault, service)
                    IOObjectRelease(service)
                    IOObjectRelease(iterator)
                    return device
                }
                
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
        return nil
    }
    
    private func getIntProperty(service: io_service_t, key: String) -> Int32 {
        let cfKey = key as CFString
        if let property = IORegistryEntryCreateCFProperty(service, cfKey, kCFAllocatorDefault, 0) {
            var value: Int32 = 0
            if CFNumberGetValue((property.takeRetainedValue() as! CFNumber), .sInt32Type, &value) {
                return value
            }
        }
        return 0
    }
    
    private func handleReport(report: UnsafeMutablePointer<UInt8>, length: Int) {
        guard motionSource == .mac, !isOccluded else { return }
        
        if length >= 18 {
            let offset = 6
            let x = Double(readInt32(report: report, offset: offset))
            let y = Double(readInt32(report: report, offset: offset + 4))
            let z = Double(readInt32(report: report, offset: offset + 8))
            
            latestRawX = x
            latestRawY = y
            latestRawZ = z
        }
    }
    
    private func readInt32(report: UnsafePointer<UInt8>, offset: Int) -> Int32 {
        var value: Int32 = 0
        memcpy(&value, report.advanced(by: offset), 4)
        return value
    }
    
    // MARK: - AirPods CMHeadphoneMotionManager Setup
    
    private func setupAirPodsMotion() {
        headphoneManager.delegate = self
        isAirPodsAvailable = headphoneManager.isDeviceMotionAvailable
    }
    
    func switchMotionSource(to source: MotionSource) {
        if source == .airpods {
            startAirPodsMotion()
        } else {
            stopAirPodsMotion()
        }
    }
    
    func startAirPodsMotion() {
        guard headphoneManager.isDeviceMotionAvailable else {
            isAirPodsConnected = false
            return
        }
        
        headphoneManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else {
                self?.isAirPodsConnected = false
                return
            }
            
            self.isAirPodsConnected = true
            if self.motionSource == .airpods {
                self.handleAirPodsMotion(motion)
            }
        }
    }
    
    func stopAirPodsMotion() {
        headphoneManager.stopDeviceMotionUpdates()
        isAirPodsConnected = false
    }
    
    private func handleAirPodsMotion(_ motion: CMDeviceMotion) {
        guard !isOccluded else { return }
        let scaleFactor: Double = 30000.0
        latestRawX = motion.attitude.roll * scaleFactor
        latestRawY = motion.attitude.pitch * scaleFactor
        latestRawZ = motion.attitude.yaw * scaleFactor
    }
    
    // MARK: - CMHeadphoneMotionManagerDelegate
    
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        DispatchQueue.main.async {
            self.isAirPodsConnected = true
        }
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        DispatchQueue.main.async {
            self.isAirPodsConnected = false
        }
    }
}
