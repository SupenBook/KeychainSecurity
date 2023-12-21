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
        cache.set(serviceName: item.service, item: item)
        try keychainIO.store(item: item, withSecurityLevel: level)
    }
    
    public func getItem(withKey key: String,
                        forService service: String,
                        isUsingCache: Bool = true) throws -> KeychainItem? {
        if isUsingCache,
           let item = cache.service(serviceName: service)?.item(key: key) {
            return item
        } else {
            guard let item = try keychainIO.getItem(withKey: key, forService: service) else {
                return nil
            }
            cache.set(serviceName: service, item: item)
            return item
        }
    }
    
    public func getAllItem(service: String,
                           isUsingCache: Bool = true) throws -> [String: KeychainItem] {
        if isUsingCache,
           let items = cache.service(serviceName: service)?.allItems() {
            return items
        } else {
            let items = try keychainIO.getAllItem(service: service)
            cache.replace(serviceName: service, items: items)
            return items
        }
    }
    
    public func delete(withKey key: String, forService service: String) throws {
        cache.delete(serviceName: service, key: key)
        try keychainIO.delete(withKey: key, forService: service)
    }
}
