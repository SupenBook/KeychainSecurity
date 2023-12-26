//
//  File.swift
//
//
//  Created by Book on 2023/12/21.
//

import Foundation

struct KeychainCache {
    
    private var services: [String: Service] = [:]
    private let lock = NSLock()
    
    func service(serviceName: String) -> Service? {
        logger.info("KeychainCache service(serviceName:\(serviceName)) - Start")
        lock.lock()
        defer {
            lock.unlock()
            logger.info("KeychainCache service(serviceName:\(serviceName)) - Done")
        }
        return services[serviceName]
    }
    
    mutating func set(serviceName: String, item: KeychainItem) throws {
        logger.info("KeychainCache set(serviceName:\(serviceName) key:\(item.key) - Start")
        lock.lock()
        defer {
            lock.unlock()
            logger.info("KeychainCache set(serviceName:\(serviceName) key:\(item.key) - Done")
        }
        var service: Service = services[serviceName] ?? .init(serviceName: serviceName)
        try service.set(item: item)
    }
    
    mutating func replace(serviceName: String, items: [String: KeychainItem]) throws {
        logger.info("KeychainCache replace(serviceName:\(serviceName) items:\(items.count) - Start")
        lock.lock()
        defer {
            lock.unlock()
            logger.info("KeychainCache replace(serviceName:\(serviceName) items:\(items.count) - Done")
        }
        var service: Service = .init(serviceName: serviceName)
        try service.set(items: items)
        services[serviceName] = service
        
    }
    
    mutating func delete(serviceName: String, key: String) {
        logger.info("KeychainCache delete(serviceName:\(serviceName) key:\(key) - Start")
        lock.lock()
        defer {
            lock.unlock()
            logger.info("KeychainCache delete(serviceName:\(serviceName) key:\(key) - Done")
        }
        guard var service = self.services[serviceName] else { return }
        service.delete(key: key)
        self.services[serviceName] = service
    }
    
    struct Service {
        
        let serviceName: String
        
        private var items: [String: KeychainItem] = [:]
        
        private var needEncrypt: Bool = true
        
        fileprivate init(serviceName: String) {
            self.serviceName = serviceName
        }
        
        func item(key: String) throws -> KeychainItem? {
            guard var item = items[key] else { return nil }
            if needEncrypt {
                item.value = try SecureEnclave().decrypt(item.value)
                return item
            } else {
                return item
            }
        }
        
        func allItems() throws -> [String: KeychainItem] {
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
