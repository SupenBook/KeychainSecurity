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

extension KeychainAccess {
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
    
    private init() {}
    
    private let keychainIO: KeychainIO = .init()
    
    public func store(item: KeychainItem,
                      withSecurityLevel level: KeychainSecurityLevel) throws {
        try keychainIO.store(item: item, withSecurityLevel: level)
    }
    
    public func getItem(withKey key: String,
                        forService service: String,
                        isUsingCache: Bool = true) throws -> KeychainItem? {
        try keychainIO.getItem(withKey: key, forService: service)
    }
    
    public func getAllItem(service: String,
                           isUsingCache: Bool = true) throws -> [String: KeychainItem] {
        try keychainIO.getAllItem(service: service)
    }
    
    public func delete(withKey key: String, forService service: String) throws {
        try keychainIO.delete(withKey: key, forService: service)
    }
}
