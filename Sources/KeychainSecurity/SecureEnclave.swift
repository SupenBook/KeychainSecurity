import Foundation

public class SecureEnclave {

    public init() {}
    
    private lazy var secureEnclavePrivateKeyTag = "secureEnclavePrivateKeyTag"
    
    public func encrypt(_ message: Data) throws -> Data {
        var privateKey = try fetchPrivateKey(tag: secureEnclavePrivateKeyTag)
        
        if privateKey == nil {
            privateKey = try generatePrivateKey(tag: secureEnclavePrivateKeyTag)
        }
        
        guard let publicKey = createPublicKey(privateKey!) else {
            throw KeychainError.createPublicKey
        }
        
        let result = try encrypt(message, publicKey: publicKey)
        
        return result
    }
    
    public func decrypt(_ message: Data) throws -> Data {
        guard let privateKey = try fetchPrivateKey(tag: secureEnclavePrivateKeyTag) else {
            throw KeychainError.missSecureEnclavePrivateKey
        }
        
        let result = try decrypt(message: message, privateKey: privateKey)
        
        return result
    }
}

// MARK: - Keys
extension SecureEnclave {
    private func generatePrivateKey(tag: String) throws -> SecKey {

        logger.info("SE generatePrivateKey - Start")
        defer { logger.info("SE generatePrivateKey - Done") }
        
        let accessControl = SecAccessControlCreateWithFlags(nil,
                                                            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                            [.privateKeyUsage],
                                                            nil)!
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag.data(using: .utf8)!,
                kSecAttrAccessControl as String: accessControl
            ] as [String: Any],
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            let errorDescription = CFErrorCopyDescription(error!.takeRetainedValue()) as String
            throw KeychainError.createPrivateKey(errorDescription)
        }

        return privateKey
    }

    private func fetchPrivateKey(tag: String) throws -> SecKey? {
        
        logger.info("SE fetchPrivateKey - Start")
        defer { logger.info("SE fetchPrivateKey - Done") }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag.data(using: .utf8)!,
            kSecReturnRef as String: true,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess {
            if CFGetTypeID(item) == SecKeyGetTypeID() {
                    let key = item as! SecKey
                    return key
            } else {
                throw KeychainError.dataConvert
            }
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw KeychainError(error: status)
        }
    }

    private func createPublicKey(_ privateKey: SecKey) -> SecKey? {
        SecKeyCopyPublicKey(privateKey)
    }
}

// MARK: - encrypt & decrypt
extension SecureEnclave {
    private func encrypt(_ message: Data, publicKey: SecKey) throws -> Data {

        logger.info("SE encrypt - Start")
        defer { logger.info("SE encrypt - Done") }

        var error: Unmanaged<CFError>?

        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA512AESGCM

        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw KeychainError.algorithmNotSupported
        }

        guard let result = SecKeyCreateEncryptedData(publicKey, algorithm, message as CFData, &error) else {
            let errorDescription = CFErrorCopyDescription(error!.takeRetainedValue()) as String
            throw KeychainError.secureEnclaveEncrypt(errorDescription)
        }

        let resultData = result as Data

        return resultData
    }

    private func decrypt(message: Data,
                        privateKey: SecKey) throws -> Data {
        
        logger.info("SE decrypt - Start")
        defer { logger.info("SE decrypt - Done") }

        var error: Unmanaged<CFError>?

        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA512AESGCM

        guard let result = SecKeyCreateDecryptedData(privateKey,
                                               algorithm,
                                               message as CFData,
                                                     &error) else {
            let errorDescription = CFErrorCopyDescription(error!.takeRetainedValue()) as String
            throw KeychainError.secureEnclaveDecrypt(errorDescription)
        }

        let resultData = result as Data

        return resultData
    }
}
