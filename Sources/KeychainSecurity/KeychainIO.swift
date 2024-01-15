//
//  File.swift
//
//
//  Created by Book on 2023/12/21.
//

import Foundation

class KeychainIO {
    private lazy var secureEnclave: SecureEnclave = .init()
    
    private var lastReadTime: Date = .distantPast
    
}

//MAKR: - Create & Update
extension KeychainIO {
    
    func store(item: KeychainItem,
               withSecurityLevel level: KeychainSecurityLevel) throws {
        
        logger.info("KeychainIO store \(item.key) level: \(level) - Start")
        defer { logger.info("KeychainIO store \(item.key) level: \(level) - Done") }
        
        var backupItem = item
        backupItem.key = backupKey(originKey: item.key)
        let backupQuery = try storeQuery(item: backupItem, withSecurityLevel: level)
        
        var resultCode = SecItemAdd(backupQuery, nil)
        logger.info("KeychainIO store - Add \(backupItem.key) result code \(resultCode)")
        
        if resultCode != errSecSuccess {
            let error = KeychainError(error: resultCode)
            logger.info("KeychainIO store - Error \(backupItem.key) Warn \(resultCode) \(error.localizedDescription)")
            throw error
        }
        
        let query = try storeQuery(item: item, withSecurityLevel: level)
        
        try delete(withKey: item.key, forService: item.service)
        
        resultCode = SecItemAdd(query, nil)
        logger.info("KeychainIO store - Add \(item.key) result code \(resultCode)")
        
        if resultCode == errSecSuccess {
            try delete(withKey: backupItem.key, forService: item.service)
        } else {
            let error = KeychainError(error: resultCode)
            logger.info("KeychainIO store - Error \(item.key) Warn \(resultCode) \(error.localizedDescription)")
            throw error
        }
    }
}

//MARK: - Read
extension KeychainIO {
    func getItem(withKey key: String, forService service: String, shouldDecryptIfNeeded: Bool) throws -> KeychainItem? {
        
        logger.info("KeychainIO getItem Item k: \(key) s:\(service) - Start")
        defer { logger.info("KeychainIO getItem Item k: \(key) s:\(service) - Done") }
        
        if let item = try fetchItem(withKey: key, forService: service, shouldDecryptIfNeeded: shouldDecryptIfNeeded) {
            return item
        }
        if let item = try fetchItem(withKey: backupKey(originKey: key), forService: service, shouldDecryptIfNeeded: shouldDecryptIfNeeded) {
            logger.info("KeychainIO getItem withKey \(key) - warn using backup key")
            return item
        }
        return nil
    }
    
    func getAllItem(service: String?, shouldDecryptIfNeeded: Bool) throws -> [String: KeychainItem] {
        
        logger.info("KeychainIO getAllItem Keychain Item s:\(service) - Start")
        defer { logger.info("KeychainIO getAllItem Keychain Item s:\(service) - Done") }
        
        delayIfNeeded(delayTimeInSeconds: 2)
        
        var fullResult: [String: KeychainItem] = [:]
        
        let itemClasses: [CFString] = [kSecClassGenericPassword,
                                       kSecClassInternetPassword,
                                       kSecClassCertificate,
                                       kSecClassKey,
                                       kSecClassIdentity]
        
        var query = [String: Any]()
        query[kSecAttrService as String] = service
        query[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        
        for itemClass in itemClasses {
            query[kSecClass as String] = itemClass
            
            var queryResult: AnyObject?
            let status = withUnsafeMutablePointer(to: &queryResult) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }
            
            if status == noErr {
                
                guard let results: [[String: Any]] = queryResult as? [[String: Any]] else {
                    logger.info("KeychainIO getAllItem s:\(service) - Warn convert to [[String:Any]]")
                    throw KeychainError.dataConvert
                }
                
                for result in results {
                    
                    let item = try convert(result: result, shouldDecryptIfNeeded: shouldDecryptIfNeeded)
                    
                    fullResult[item.key] = item
                }
                
                logger.info("KeychainIO getAllItem - \(itemClass) Done rc:\(results.count)")
                
            } else if status == errSecNoSuchAttr {
                let error = KeychainError(error: status)
                logger.info("KeychainIO getAllItem - \(itemClass) \(status) \(error.localizedDescription)")
            } else if status == errSecItemNotFound {
                let error = KeychainError(error: status)
                logger.info("KeychainIO getAllItem - \(itemClass) \(status) \(error.localizedDescription)")
            } else {
                let error = KeychainError(error: status)
                logger.info("KeychainIO getAllItem - Warn \(itemClass) \(status) \(error.localizedDescription)")
                throw error
            }
        }
        
        return fullResult
    }
}

//MARK: - Delete
extension KeychainIO {
    func delete(withKey key: String, forService service: String) throws {
        logger.info("KeychainIO delete \(key) - Start")
        defer { logger.info("KeychainIO delete \(key) - Done") }
        
        var query = [String: Any]()
        
        query[kSecAttrAccount as String] = key as CFString
        query[kSecAttrService as String] = service
        query[kSecClass as String] = kSecClassGenericPassword
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            logger.info("KeychainIO delete \(key) - errSecSuccess")
        } else if status == errSecItemNotFound {
            logger.info("KeychainIO delete \(key) - errSecItemNotFound")
        } else {
            let error = KeychainError(error: status)
            logger.info("KeychainIO delete k:\(key) s:\(service) - Warn \(status) \(error.localizedDescription)")
            throw error
        }
    }
}

extension KeychainIO {
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
            let encryptData = try secureEnclave.encrypt(item.value)
            query[kSecValueData as String] = encryptData as CFData
            isBiometricRequired = true
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
    
    private func fetchItem(withKey key: String,
                           forService service: String,
                           shouldDecryptIfNeeded: Bool) throws -> KeychainItem? {
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
                logger.info("KeychainIO FetchItem k:\(key) s:\(service) - Warn convert to [String:Any]")
                throw KeychainError.dataConvert
            }
            
            return try convert(result: result, shouldDecryptIfNeeded: shouldDecryptIfNeeded)
            
        } else if status == errSecItemNotFound {
            return nil
        } else {
            let error = KeychainError(error: status)
            logger.info("KeychainIO FetchItem k:\(key) s:\(service) - Warn \(status) \(error.localizedDescription)")
            throw error
        }
    }
    
    private func convert(result: [String: Any], shouldDecryptIfNeeded: Bool) throws -> KeychainItem {
        guard let key = result[kSecAttrAccount as String] as? String else {
            logger.info("KeychainIO convert - Warn parsing kSecAttrAccount")
            throw KeychainError.dataConvert
        }
        
        guard let service = result[kSecAttrService as String] as? String else {
            logger.info("KeychainIO convert k:\(key) - Warn parsing kSecAttrService")
            throw KeychainError.dataConvert
        }
        
        guard var value = result[kSecValueData as String] as? Data else {
            logger.info("KeychainIO convert k:\(key) s:\(service) - Warn parsing kSecValueData")
            throw KeychainError.dataConvert
        }
        
        if shouldDecryptIfNeeded,
           let description = result[kSecAttrDescription as String] as? String{
            if description == KeychainSecurityLevel.high.attrDescription {
                value = try secureEnclave.decrypt(value)
            }
        } else {
            logger.info("KeychainIO convert k:\(key) s:\(service) - Warn parsing kSecAttrDescription")
        }
        
        return .init(key: key, service: service, value: value)
    }
    
    private func backupKey(originKey: String) -> String {
        return originKey + "_backup"
    }
    
    private func delayIfNeeded(delayTimeInSeconds: TimeInterval) {
        
        let executableTime = lastReadTime.advanced(by: delayTimeInSeconds)
        
        let currentTime = Date.now
        
        if currentTime < executableTime {
            logger.info("KeychainIO delayIfNeeded - need delay until \(executableTime)")
            Thread.sleep(until: executableTime)
        }
        
        lastReadTime = Date.now
    }
}
