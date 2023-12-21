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
        
        logger.info("SetKeychain \(item.key) level: \(level) - Start")
        defer { logger.info("SetKeychain \(item.key) level: \(level) - Done") }
        
        var backupItem = item
        backupItem.key = backupKey(originKey: item.key)
        let backupQuery = try storeQuery(item: backupItem, withSecurityLevel: level)
        
        var resultCode = SecItemAdd(backupQuery, nil)
        logger.info("SetKeychain - Add \(backupItem.key) result code \(resultCode)")
        
        if resultCode != errSecSuccess {
            let error = KeychainError(error: resultCode)
            logger.info("SetKeychain - Error \(backupItem.key) Warn \(resultCode) \(error.localizedDescription)")
            throw error
        }
        
        let query = try storeQuery(item: item, withSecurityLevel: level)
        
        try delete(withKey: item.key, forService: item.service)
        
        resultCode = SecItemAdd(query, nil)
        logger.info("SetKeychain - Add \(item.key) result code \(resultCode)")
        
        if resultCode == errSecSuccess {
            try delete(withKey: backupItem.key, forService: item.service)
        } else {
            let error = KeychainError(error: resultCode)
            logger.info("SetKeychain - Error \(item.key) Warn \(resultCode) \(error.localizedDescription)")
            throw error
        }
    }
}

//MARK: - Read
extension KeychainIO {
    func getItem(withKey key: String, forService service: String) throws -> KeychainItem? {
        
        logger.info("Get Keychain Item k: \(key) s:\(service) - Start")
        defer { logger.info("Get Keychain Item k: \(key) s:\(service) - Done") }
        
        if let item = try fetchItem(withKey: key, forService: service) {
            return item
        }
        if let item = try fetchItem(withKey: backupKey(originKey: key), forService: service) {
            logger.info("Get Item withKey \(key) - warn using backup key")
            return item
        }
        return nil
    }
    
    func getAllItem(service: String) throws -> [String: KeychainItem] {
        
        logger.info("Get All Keychain Item s:\(service) - Start")
        defer { logger.info("Get All Keychain Item s:\(service) - Done") }
        
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
                    logger.info("GetAllKeychainItem s:\(service) - Warn convert to [[String:Any]]")
                    throw KeychainError.dataConvert
                }
                
                for result in results {
                    
                    let item = try convert(result: result)
                    
                    fullResult[item.key] = item
                }
                
                logger.info("GetAllKeychainItem - \(itemClass) Done rc:\(results.count)")
                
            } else if status == errSecNoSuchAttr {
                let error = KeychainError(error: status)
                logger.info("GetAllKeychainItem - \(itemClass) \(status) \(error.localizedDescription)")
            } else if status == errSecItemNotFound {
                let error = KeychainError(error: status)
                logger.info("GetAllKeychainItem - \(itemClass) \(status) \(error.localizedDescription)")
            } else {
                let error = KeychainError(error: status)
                logger.info("GetAllKeychainItem - Warn \(itemClass) \(status) \(error.localizedDescription)")
                throw error
            }
        }
        
        return fullResult
    }
}

//MARK: - Delete
extension KeychainIO {
    func delete(withKey key: String, forService service: String) throws {
        logger.info("DeleteKeychain \(key) - Start")
        defer { logger.info("DeleteKeychain \(key) - Done") }
        
        var query = [String: Any]()
        
        query[kSecAttrAccount as String] = key as CFString
        query[kSecAttrService as String] = service
        query[kSecClass as String] = kSecClassGenericPassword
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            logger.info("DeleteKeychain \(key) - errSecSuccess")
        } else if status == errSecItemNotFound {
            logger.info("DeleteKeychain \(key) - errSecItemNotFound")
        } else {
            let error = KeychainError(error: status)
            logger.info("DeleteKeychain k:\(key) s:\(service) - Warn \(status) \(error.localizedDescription)")
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
                logger.info("GetKeychainItem k:\(key) s:\(service) - Warn convert to [String:Any]")
                throw KeychainError.dataConvert
            }
            
            return try convert(result: result)
            
        } else if status == errSecItemNotFound {
            return nil
        } else {
            let error = KeychainError(error: status)
            logger.info("GetKeychainItem k:\(key) s:\(service) - Warn \(status) \(error.localizedDescription)")
            throw error
        }
    }
    
    private func convert(result: [String: Any]) throws -> KeychainItem {
        guard let key = result[kSecAttrAccount as String] as? String else {
            logger.info("Convert result - Warn parsing kSecAttrAccount")
            throw KeychainError.dataConvert
        }
        
        guard let service = result[kSecAttrService as String] as? String else {
            logger.info("Convert result k:\(key) - Warn parsing kSecAttrService")
            throw KeychainError.dataConvert
        }
        
        guard var value = result[kSecValueData as String] as? Data else {
            logger.info("Convert result k:\(key) s:\(service) - Warn parsing kSecValueData")
            throw KeychainError.dataConvert
        }
        
        if let description = result[kSecAttrDescription as String] as? String{
            if description == KeychainSecurityLevel.high.attrDescription {
                value = try secureEnclave.decrypt(value)
            }
        } else {
            logger.info("GetKeychainItem k:\(key) s:\(service) - Warn parsing kSecAttrDescription")
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
            logger.info("Keychain Security - need delay until \(executableTime)")
            Thread.sleep(until: executableTime)
        }
        
        lastReadTime = Date.now
    }
}