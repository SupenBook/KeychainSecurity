import Foundation

public protocol KeychainAccess {
    
    func store(item: KeychainItem,
               withSecurityLevel level: KeychainSecurityLevel) throws
    
    func getItem(withKey key: String,
                 forService service: String,
                 shouldDecryptIfNeeded: Bool) throws -> KeychainItem?
    
    func getAllItem(service: String,
                    shouldDecryptIfNeeded: Bool) throws -> [String: KeychainItem]
    
    func delete(withKey key: String, forService service: String) throws
}

public extension KeychainAccess {
    func getItem(withKey key: String,
                 forService service: String,
                 shouldDecryptIfNeeded: Bool = false) throws -> KeychainItem? {
        return try getItem(withKey: key, forService: service, shouldDecryptIfNeeded: shouldDecryptIfNeeded)
    }
    
    func getAllItem(service: String,
                    shouldDecryptIfNeeded: Bool = false) throws -> [String: KeychainItem] {
        return try getAllItem(service: service, shouldDecryptIfNeeded: shouldDecryptIfNeeded)
    }
}

public class KeychainSecurity: KeychainAccess {
    
    public static let shared: KeychainSecurity = .init()
    
    private init() {
        
    }
    
    private let keychainIO: KeychainIO = .init()
    
    public func store(item: KeychainItem,
                      withSecurityLevel level: KeychainSecurityLevel) throws {
        logger.info("KeychainSecurity store \(item.key) level: \(level) - Start")
        defer { logger.info("KeychainSecurity store \(item.key) level: \(level) - Done") }
        
        try keychainIO.store(item: item, withSecurityLevel: level)
    }
    
    public func getItem(withKey key: String,
                        forService service: String,
                        shouldDecryptIfNeeded: Bool = false) throws -> KeychainItem? {
        logger.info("KeychainSecurity getItem Item k: \(key) s:\(service) - Start")
        defer { logger.info("KeychainSecurity getItem Item k: \(key) s:\(service) - Done") }
        
        return try keychainIO.getItem(withKey: key,
                                      forService: service,
                                      shouldDecryptIfNeeded: shouldDecryptIfNeeded)
    }
    
    public func getAllItem(service: String,
                           shouldDecryptIfNeeded: Bool = false) throws -> [String: KeychainItem] {
        logger.info("KeychainSecurity getAllItem Keychain Item s:\(service) - Start")
        defer { logger.info("KeychainSecurity getAllItem Keychain Item s:\(service) - Done") }
        
        return try keychainIO.getAllItem(service: service,
                                         shouldDecryptIfNeeded: shouldDecryptIfNeeded)
    }
    
    public func delete(withKey key: String, forService service: String) throws {
        logger.info("KeychainSecurity delete \(key) - Start")
        defer { logger.info("KeychainSecurity delete \(key) - Done") }
        
        try keychainIO.delete(withKey: key, forService: service)
    }
}
