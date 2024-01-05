//
//  File.swift
//
//
//  Created by Book on 2023/12/21.
//

import Foundation

public struct KeychainCache {
    
    private var services: [String: Service] = [:]
    private let lock = NSLock()
    
    private let isNeedEncrypt: Bool
    
    public init(isNeedEncrypt: Bool = true) {
#if targetEnvironment(simulator)
        self.needEncrypt = false
#else
        self.isNeedEncrypt = isNeedEncrypt
#endif
    }
    
    public func service(serviceName: String) -> Service? {
        lock.lock()
        logger.info("KeychainCache service(serviceName:\(serviceName)) - Start")
        defer {
            lock.unlock()
            logger.info("KeychainCache service(serviceName:\(serviceName)) - Done")
        }
        return services[serviceName]
    }
    
    public mutating func set(serviceName: String, item: KeychainItem) throws {
        lock.lock()
        logger.info("KeychainCache set(serviceName:\(serviceName) key:\(item.key) - Start")
        defer {
            lock.unlock()
            logger.info("KeychainCache set(serviceName:\(serviceName) key:\(item.key) - Done")
        }
        var service: Service = services[serviceName] ?? .init(serviceName: serviceName,
                                                              needEncrypt: isNeedEncrypt)
        try service.set(item: item)
        services[serviceName] = service
    }
    
    public mutating func replace(serviceName: String, items: [String: KeychainItem]) throws {
        lock.lock()
        logger.info("KeychainCache replace(serviceName:\(serviceName) items:\(items.count) - Start")
        defer {
            lock.unlock()
            logger.info("KeychainCache replace(serviceName:\(serviceName) items:\(items.count) - Done")
        }
        var service: Service = .init(serviceName: serviceName,
                                     needEncrypt: isNeedEncrypt)
        try service.set(items: items)
        services[serviceName] = service
        
    }
    
    public mutating func delete(serviceName: String, key: String) {
        lock.lock()
        logger.info("KeychainCache delete(serviceName:\(serviceName) key:\(key) - Start")
        defer {
            lock.unlock()
            logger.info("KeychainCache delete(serviceName:\(serviceName) key:\(key) - Done")
        }
        guard var service = self.services[serviceName] else { return }
        service.delete(key: key)
        self.services[serviceName] = service
    }
    
    public struct Service {
        
        let serviceName: String
        
        private var items: [String: KeychainItem] = [:]
        
        private let needEncrypt: Bool
        
        fileprivate init(serviceName: String, needEncrypt: Bool) {
            self.needEncrypt = needEncrypt
            self.serviceName = serviceName
        }
        
        public func item(key: String) throws -> KeychainItem? {
            logger.info("KeychainCache item(key:\(key) - Start")
            defer {
                logger.info("KeychainCache item(key:\(key) - Done")
            }
            guard var item = items[key] else { return nil }
            if needEncrypt {
                item.value = try SecureEnclave().decrypt(item.value)
                return item
            } else {
                return item
            }
        }
        
        public func allItems() throws -> [String: KeychainItem] {
            logger.info("KeychainCache allItems - Start")
            defer {
                logger.info("KeychainCache allItems - Done")
            }
            var result: [String: KeychainItem] = [:]
            for key in items.keys {
                result[key] = try item(key: key)
            }
            return result
        }
        
        fileprivate mutating func set(item: KeychainItem) throws {
            var item = item
            if needEncrypt {
                item.value = try SecureEnclave().encrypt(item.value)
            }
            items[item.key] = item
        }
        
        fileprivate mutating func set(items: [String: KeychainItem]) throws {
            for item in items {
                try set(item: item.value)
            }
        }
        
        fileprivate mutating func delete(key: String) {
            items[key] = nil
        }
    }
}
