import Foundation

enum DeviceActivityThreshold {
    static var `default`: DateComponents {
        #if DEBUG
        DateComponents(minute: 5)
        #else
        DateComponents(hour: 3)
        #endif
    }
}
