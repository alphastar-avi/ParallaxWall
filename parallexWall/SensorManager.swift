import Foundation
import IOKit
import IOKit.hid
import Combine

class SensorManager: ObservableObject {
    @Published var rotation = (x: Double(0), y: Double(0), z: Double(0))
    
    private var hidDevice: IOHIDDevice?
    private var reportBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
    
    init() {
        setupSensor()
    }
    
    deinit {
        if let device = hidDevice {
            IOHIDDeviceClose(device, 0)
        }
        reportBuffer.deallocate()
    }
    
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
                // Set reporting properties
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
                
                // Vendor Page: 0xFF00, Accel Usage: 3
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
        // IMUDataOffset is 6 as per Go code. X, Y, Z are 32-bit floats/ints at +0, +4, +8
        // Actually the Go code says ParseIMUReport pulls 32-bit integers.
        // Let's use the layout from the Go reference.
        
        if length >= 18 {
            let offset = 6
            let x = readInt32(report: report, offset: offset)
            let y = readInt32(report: report, offset: offset + 4)
            let z = readInt32(report: report, offset: offset + 8)
            
            // Normalize these values. Max is usually around 16383 or something for these sensors.
            // Let's just track raw for now and normalize in the view.
            DispatchQueue.main.async {
                self.rotation = (x: Double(x), y: Double(y), z: Double(z))
            }
        }
    }
    
    private func readInt32(report: UnsafePointer<UInt8>, offset: Int) -> Int32 {
        var value: Int32 = 0
        memcpy(&value, report.advanced(by: offset), 4)
        return value
    }
}
