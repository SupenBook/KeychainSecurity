import Foundation

// 1. Low:        Keychain WhenUnlockedThisDeviceOnly （no face id check)
// 2. Middle:    Keychain WhenUnlockedThisDeviceOnly + biometryAny （every time get will check faceID)
// 3. High:    Keychain WhenUnlockedThisDeviceOnly  + secure enclave （data is encrypted && every time get will check faceID)
public enum KeychainSecurityLevel {
    case low
    case middle
    case high

    var attrDescription: String {
        switch self {
        case .low:
            return "low"
        case .middle:
            return "middle"
        case .high:
            return "high"
        }
    }
}
