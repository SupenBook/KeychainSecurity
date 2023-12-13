import Foundation

public enum KeychainError: Error, LocalizedError {
    case unimplemented
    case io
    case opWr
    case param
    case allocate
    case userCanceled
    case badReq
    case notAvailable
    case duplicateItem
    case itemNotFound
    case noSuchAttr
    case interactionNotAllowed
    case decode
    case authFailed
    case dataConvert
    case accessControl(String)
    case createPrivateKey(String)
    case createPublicKey
    case algorithmNotSupported
    case missSecureEnclavePrivateKey
    case secureEnclaveEncrypt(String)
    case secureEnclaveDecrypt(String)
    case secKeyCreateWithData(String)
    case secKeyCopyExternalRepresentation(String)
    case unowned(OSStatus)

    init(error: OSStatus) {
        switch error {
        case errSecUnimplemented:
            self = .unimplemented
        case errSecIO:
            self = .io
        case errSecOpWr:
            self = .opWr
        case errSecParam:
            self = .param
        case errSecAllocate:
            self = .allocate
        case errSecUserCanceled:
            self = .userCanceled
        case errSecBadReq:
            self = .badReq
        case errSecNotAvailable:
            self = .notAvailable
        case errSecDuplicateItem:
            self = .duplicateItem
        case errSecItemNotFound:
            self = .itemNotFound
        case errSecNoSuchAttr:
            self = .noSuchAttr
        case errSecInteractionNotAllowed:
            self = .interactionNotAllowed
        case errSecDecode:
            self = .decode
        case errSecAuthFailed:
            self = .authFailed
        default:
            self = .unowned(error)
            logger.info("Undefined OSStatus \(error)")
        }
    }

    public var errorDescription: String? {
        switch self {
        case .unimplemented:
            return "Function or operation not implemented."
        case .io:
            return "I/O error."
        case .opWr:
            return "File already open with with write permission."
        case .param:
            return "One or more parameters passed to a function where not valid."
        case .allocate:
            return "Failed to allocate memory."
        case .userCanceled:
            return "User canceled the operation."
        case .badReq:
            return "Bad parameter or invalid state for operation."
        case .notAvailable:
            return "No keychain is available. You may need to restart your computer."
        case .duplicateItem:
            return "The specified item already exists in the keychain."
        case .itemNotFound:
            return "The specified item could not be found in the keychain."
        case .noSuchAttr:
            return "The specified item NoSuchAttr."
        case .interactionNotAllowed:
            return "User interaction is not allowed."
        case .decode:
            return "Unable to decode the provided data."
        case .authFailed:
            return "The user name or passphrase you entered is not correct. Check is run at iOS 15 Simulator"
        case .dataConvert:
            return "Data convert error"
        case .accessControl:
            return "Error generating accessControl"
        case .createPrivateKey(let desc):
            return "createPrivateKey \(desc)"
        case .algorithmNotSupported:
            return "algorithmNotSupported"
        case .secureEnclaveEncrypt(let desc):
            return "secureEnclaveEncrypt \(desc)"
        case .secureEnclaveDecrypt(let desc):
            return "secureEnclaveDecrypt \(desc)"
        case .unowned(let error):
            return "\(error)"
        case .missSecureEnclavePrivateKey:
            return "missSecureEnclavePrivateKey"
        case .secKeyCreateWithData(let desc):
            return "secKeyCreateWithData \(desc)"
        case .secKeyCopyExternalRepresentation(let desc):
            return "secKeyCopyExternalRepresentation \(desc)"
        case .createPublicKey:
            return "createPublicKey error"
        }
    }
}
