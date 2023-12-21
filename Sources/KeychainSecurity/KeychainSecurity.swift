import Foundation

public protocol KeychainAccess {
    func store(item: KeychainItem,
               withSecurityLevel level: KeychainSecurityLevel) throws
    
    func getItem(withKey key: String,
                 forService service: String,
                 isUsingCache: Bool) throws -> KeychainItem?
    
    func getAllItem(service: String,
                    isUsingCache: Bool) throws -> [String: KeychainItem]
    
    func delete(withKey key: String, forService service: String) throws
}

public extension KeychainAccess {
    func getItem(withKey key: String,
                 forService service: String,
                 isUsingCache: Bool = true) throws -> KeychainItem? {
        return try getItem(withKey: key, forService: service, isUsingCache: isUsingCache)
    }
    
    func getAllItem(service: String,
                    isUsingCache: Bool = true) throws -> [String: KeychainItem] {
        return try getAllItem(service: service, isUsingCache: isUsingCache)
    }
}

public class KeychainSecurity: KeychainAccess {
    
    public static let shared: KeychainSecurity = .init()
    
    private init() {
        
    }
    
    private let keychainIO: KeychainIO = .init()
    
    private lazy var secureEnclave: SecureEnclave = .init()
    
    private lazy var cache: KeychainCache = .init()
    
    public func store(item: KeychainItem,
                      withSecurityLevel level: KeychainSecurityLevel) throws {
        logger.info("KeychainSecurity store \(item.key) level: \(level) - Start")
        defer { logger.info("KeychainSecurity store \(item.key) level: \(level) - Done") }
        
        try cache.set(serviceName: item.service, item: item)
        try keychainIO.store(item: item, withSecurityLevel: level)
    }
    
    public func getItem(withKey key: String,
                        forService service: String,
                        isUsingCache: Bool = true) throws -> KeychainItem? {
        logger.info("KeychainSecurity getItem Item k: \(key) s:\(service) - Start")
        defer { logger.info("KeychainSecurity getItem Item k: \(key) s:\(service) - Done") }
        
        if isUsingCache,
           let item = try cache.service(serviceName: service)?.item(key: key) {
            return item
        } else {
            guard let item = try keychainIO.getItem(withKey: key, forService: service) else {
                return nil
            }
            try cache.set(serviceName: service, item: item)
            return item
        }
    }
    
    public func getAllItem(service: String,
                           isUsingCache: Bool = true) throws -> [String: KeychainItem] {
        logger.info("KeychainSecurity getAllItem Keychain Item s:\(service) - Start")
        defer { logger.info("KeychainSecurity getAllItem Keychain Item s:\(service) - Done") }
        
        if isUsingCache,
           let items = try cache.service(serviceName: service)?.allItems() {
            return items
        } else {
            let items = try keychainIO.getAllItem(service: service)
            try cache.replace(serviceName: service, items: items)
            return items
        }
    }
    
    public func delete(withKey key: String, forService service: String) throws {
        logger.info("KeychainSecurity delete \(key) - Start")
        defer { logger.info("KeychainSecurity delete \(key) - Done") }
        
        cache.delete(serviceName: service, key: key)
        try keychainIO.delete(withKey: key, forService: service)
    }
}
