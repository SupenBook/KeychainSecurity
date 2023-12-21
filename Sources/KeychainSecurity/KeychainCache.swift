//
//  File.swift
//  
//
//  Created by Book on 2023/12/21.
//

import Foundation

struct KeychainCache {
    private var services: [String: Service] = [:]
    
    func service(serviceName: String) -> Service? {
        return services[serviceName]
    }
    
    mutating func set(serviceName: String, item: KeychainItem) {
        var service: Service = services[serviceName] ?? .init(serviceName: serviceName)
        service.set(item: item)
        services[serviceName] = service
    }
    
    mutating func replace(serviceName: String, items: [String: KeychainItem]) {
        services[serviceName] = .init(serviceName: serviceName, items: items)
    }
    
    mutating func delete(serviceName: String, key: String) {
        guard var service = services[serviceName] else { return }
        service.delete(key: key)
        services[serviceName] = service
    }
    
    struct Service {
        let serviceName: String
        private var items: [String: KeychainItem] = [:]
        
        init(serviceName: String, items: [String: KeychainItem] = [:]) {
            self.serviceName = serviceName
            self.items = items
        }
        
        func allItems() -> [String: KeychainItem] {
            return items
        }
        
        func item(key: String) -> KeychainItem? {
            return items[key]
        }
        
        fileprivate mutating func set(item: KeychainItem) {
            items[item.key] = item
        }
        
        fileprivate mutating func delete(key: String) {
            items[key] = nil
        }
    }
}
