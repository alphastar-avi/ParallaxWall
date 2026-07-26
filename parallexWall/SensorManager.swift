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

class SensorManager: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate {
    @Published var rotation = (x: Double(0), y: Double(0), z: Double(0))
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
    
    // Motion Source selection (Mac Hardware vs. AirPods Spatial Motion)
    @Published var motionSource: MotionSource = .mac {
        didSet {
            switchMotionSource(to: motionSource)
        }
    }
    
    @Published var isAirPodsAvailable: Bool = false
    @Published var isAirPodsConnected: Bool = false
    
    private var hidDevice: IOHIDDevice?
    private var reportBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
    private let headphoneManager = CMHeadphoneMotionManager()
    
    override init() {
        super.init()
        setupSensor()
        setupAirPodsMotion()
    }
    
    deinit {
        if let device = hidDevice {
            IOHIDDeviceClose(device, 0)
        }
        reportBuffer.deallocate()
        stopAirPodsMotion()
    }
    
    func calibrate() {
        self.baseRotation = self.rotation
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
        guard motionSource == .mac else { return }
        
        if length >= 18 {
            let offset = 6
            let x = readInt32(report: report, offset: offset)
            let y = readInt32(report: report, offset: offset + 4)
            let z = readInt32(report: report, offset: offset + 8)
            
            DispatchQueue.main.async {
                let targetX = Double(x)
                let targetY = Double(y)
                let targetZ = Double(z)
                
                if self.rotation.x == 0 && self.rotation.y == 0 && self.rotation.z == 0 {
                    self.rotation = (x: targetX, y: targetY, z: targetZ)
                } else {
                    let newX = self.rotation.x + (targetX - self.rotation.x) * self.smoothing
                    let newY = self.rotation.y + (targetY - self.rotation.y) * self.smoothing
                    let newZ = self.rotation.z + (targetZ - self.rotation.z) * self.smoothing
                    self.rotation = (x: newX, y: newY, z: newZ)
                }
            }
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
        // Attitude radians (-pi to +pi). Scale factor maps radians to ~30,000 unit range for smooth parallax
        let scaleFactor: Double = 30000.0
        let targetX = motion.attitude.roll * scaleFactor
        let targetY = motion.attitude.pitch * scaleFactor
        let targetZ = motion.attitude.yaw * scaleFactor
        
        DispatchQueue.main.async {
            if self.rotation.x == 0 && self.rotation.y == 0 && self.rotation.z == 0 {
                self.rotation = (x: targetX, y: targetY, z: targetZ)
            } else {
                let newX = self.rotation.x + (targetX - self.rotation.x) * self.smoothing
                let newY = self.rotation.y + (targetY - self.rotation.y) * self.smoothing
                let newZ = self.rotation.z + (targetZ - self.rotation.z) * self.smoothing
                self.rotation = (x: newX, y: newY, z: newZ)
            }
        }
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
