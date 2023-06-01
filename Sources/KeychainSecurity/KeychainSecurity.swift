import Foundation

public protocol KeychainAccess {
    func store(item: KeychainItem, withSecurityLevel level: KeychainSecurityLevel) throws
    
    func getItem(withKey key: String, forService service: String) throws -> KeychainItem?
    
    func delete(withKey key: String, forService service: String) throws
}

public class KeychainSecurity: KeychainAccess {
    
    public static let shared: KeychainSecurity = .init()
    
    private init() {}
    
    private lazy var secureEnclave: SecureEnclave = .init()
    private lazy var secureEnclavePrivateKeyTag = "secureEnclavePrivateKeyTag"
    
    public func store(item: KeychainItem, withSecurityLevel level: KeychainSecurityLevel) throws {
        
        Logger().info("SetKeychain \(item.key) level: \(level) - Start")
        defer { Logger().info("SetKeychain \(item.key) level: \(level) - Done") }
        
        var backupItem = item
        backupItem.key = backupKey(originKey: item.key)
        let backupQuery = try storeQuery(item: backupItem, withSecurityLevel: level)
        
        var resultCode = SecItemAdd(backupQuery, nil)
        Logger().info("SetKeychain - Add \(backupItem.key) result code \(resultCode)")
        
        if resultCode != errSecSuccess {
            let error = KeychainError(error: resultCode)
            Logger().info("SetKeychain - Error \(backupItem.key) Warn \(resultCode) \(error.localizedDescription)")
            throw error
        }
        
        let query = try storeQuery(item: item, withSecurityLevel: level)
        
        try delete(withKey: item.key, forService: item.service)
        
        resultCode = SecItemAdd(query, nil)
        Logger().info("SetKeychain - Add \(item.key) result code \(resultCode)")
        
        if resultCode == errSecSuccess {
            try delete(withKey: backupItem.key, forService: item.service)
        } else {
            let error = KeychainError(error: resultCode)
            Logger().info("SetKeychain - Error \(item.key) Warn \(resultCode) \(error.localizedDescription)")
            throw error
        }
    }
    
    public func getItem(withKey key: String, forService service: String) throws -> KeychainItem? {
        if let item = try fetchItem(withKey: key, forService: service) {
            return item
        }
        if let item = try fetchItem(withKey: backupKey(originKey: key), forService: service) {
            Logger().info("Get Item withKey \(key) - warn using backup key")
            return item
        }
        return nil
    }
    
    public func delete(withKey key: String, forService service: String) throws {
        Logger().info("DeleteKeychain \(key) - Start")
        defer { Logger().info("DeleteKeychain \(key) - Done") }
        
        var query = [String: Any]()
        
        query[kSecAttrAccount as String] = key as CFString
        query[kSecAttrService as String] = service
        query[kSecClass as String] = kSecClassGenericPassword
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            Logger().info("DeleteKeychain \(key) - errSecSuccess")
        } else if status == errSecItemNotFound {
            Logger().info("DeleteKeychain \(key) - errSecItemNotFound")
        } else {
            let error = KeychainError(error: status)
            Logger().info("DeleteKeychain k:\(key) s:\(service) - Warn \(status) \(error.localizedDescription)")
            throw error
        }
    }
}

extension KeychainSecurity {
    private func storeQuery(item: KeychainItem, withSecurityLevel level: KeychainSecurityLevel) throws -> CFDictionary {
        var error: Unmanaged<CFError>?
        
        var query = [String: Any]()
        query[kSecAttrAccount as String] = item.key as CFString
        query[kSecValueData as String] = item.value as CFData
        query[kSecAttrService as String] = item.service
        query[kSecAttrDescription as String] = level.attrDescription
        query[kSecClass as String] = kSecClassGenericPassword
        
        var isBiometricRequired = false
        switch level {
        case .low:
            break
        case .middle:
            isBiometricRequired = true
        case .high:
            let encryptData = try encrypt(item.value)
            query[kSecValueData as String] = encryptData as CFData
        }
        /*
         Touch ID must be available and enrolled with at least one finger, or Face ID must be available and enrolled. The item is still accessible by Touch ID if fingers are added or removed, or by Face ID if the user is re-enrolled.
         */
        guard let accessControl =
                SecAccessControlCreateWithFlags(
                    kCFAllocatorDefault,
                    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                    isBiometricRequired ? .biometryAny : [],
                    &error) else {
            let errorDescription = CFErrorCopyDescription(error!.takeRetainedValue()) as String
            throw KeychainError.accessControl(errorDescription)
        }
        query[kSecAttrAccessControl as String] = accessControl
        
        return query as CFDictionary
    }
    
    private func fetchItem(withKey key: String, forService service: String) throws -> KeychainItem? {
        var query = [String: Any]()
        query[kSecAttrAccount as String] = key as CFString
        query[kSecAttrService as String] = service
        query[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecClass as String] = kSecClassGenericPassword
        
        var queryResult: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &queryResult)
        
        if status == errSecSuccess {
            
            guard let result = queryResult as? [String: Any] else {
                Logger().info("GetKeychainItem k:\(key) s:\(service) - Warn convert to [String:Any]")
                throw KeychainError.dataConvert
            }
            
            guard let key = result[kSecAttrAccount as String] as? String else {
                Logger().info("GetKeychainItem - Warn parsing kSecAttrAccount")
                throw KeychainError.dataConvert
            }
            
            guard let service = result[kSecAttrService as String] as? String else {
                Logger().info("GetKeychainItem k:\(key) - Warn parsing kSecAttrService")
                throw KeychainError.dataConvert
            }
            
            guard var value = result[kSecValueData as String] as? Data else {
                Logger().info("GetKeychainItem k:\(key) s:\(service) - Warn parsing kSecValueData")
                throw KeychainError.dataConvert
            }
            
            guard let description = result[kSecAttrDescription as String] as? String else {
                Logger().info("GetKeychainItem k:\(key) s:\(service) - Warn parsing kSecAttrDescription")
                throw KeychainError.dataConvert
            }
            
            if description == KeychainSecurityLevel.high.attrDescription {
                value = try decrypt(value)
            }
            
            return .init(key: key, service: service, value: value)
            
        } else if status == errSecItemNotFound {
            return nil
        } else {
            let error = KeychainError(error: status)
            Logger().info("GetKeychainItem k:\(key) s:\(service) - Warn \(status) \(error.localizedDescription)")
            throw error
        }
    }
    
    private func backupKey(originKey: String) -> String {
        return originKey + "_backup"
    }
}

// MARK: - Encrypt & Decrypt
extension KeychainSecurity {
    private func encrypt(_ message: Data) throws -> Data {
        var privateKey = try secureEnclave.fetchPrivateKey(tag: secureEnclavePrivateKeyTag)
        
        if privateKey == nil {
            privateKey = try secureEnclave.generatePrivateKey(tag: secureEnclavePrivateKeyTag)
        }
        
        guard let publicKey = secureEnclave.createPublicKey(privateKey!) else {
            throw KeychainError.createPublicKey
        }
        
        let result = try secureEnclave.encrypt(message, publicKey: publicKey)
        
        return result
    }
    
    private func decrypt(_ message: Data) throws -> Data {
        guard let privateKey = try secureEnclave.fetchPrivateKey(tag: secureEnclavePrivateKeyTag) else {
            throw KeychainError.missSecureEnclavePrivateKey
        }
        
        let result = try secureEnclave.decrypt(message: message, privateKey: privateKey)
        
        return result
    }
}
