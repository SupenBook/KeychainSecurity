import XCTest
@testable import KeychainSecurity

final class KeychainCRUDTest: XCTestCase {

    var keychain: KeychainAccess = KeychainSecurity.shared
    var helper:KeychainTestHelper = .init()
    let securityLevels: [KeychainSecurityLevel] = [.low, .middle, .high]
    let testService: String = "TestService"
    
    func testCreateRead() {
        securityLevels.forEach { level in
            helper.clearKeychain(service: testService)
            
            let expectItem = KeychainItem(withMock: testService, service: testService)
            
            try! keychain.store(item: expectItem,
                                withSecurityLevel: level)
            
            let testItem = try! keychain.getItem(withKey: expectItem.key,
                                                 forService: expectItem.service)
            
            XCTAssertEqual(testItem, expectItem)
        }
    }
    
    func testUpdate() {
        securityLevels.forEach { level in
            helper.clearKeychain(service: testService)
            
            var expectItem = KeychainItem(withMock: testService, service: testService)
            
            try! keychain.store(item: expectItem,
                                withSecurityLevel: level)
            
            expectItem.value = "Updated".data(using: .utf8)!
            try! keychain.store(item: expectItem,
                                withSecurityLevel: level)
            
            let testItem = try! keychain.getItem(withKey: expectItem.key,
                                                 forService: expectItem.service)
            
            XCTAssertEqual(testItem, expectItem)
        }
    }
    
    func testDelete() {
        securityLevels.forEach { level in
            helper.clearKeychain(service: testService)
            
            let expectItem = KeychainItem(withMock: testService, service: testService)
            
            try! keychain.store(item: expectItem,
                                withSecurityLevel: level)
            
            var testItem = try! keychain.getItem(withKey: expectItem.key,
                                                 forService: expectItem.service)
            
            XCTAssertEqual(testItem, expectItem)
            
            try! keychain.delete(withKey: expectItem.key,
                                forService: expectItem.service)
            
            testItem = try! keychain.getItem(withKey: expectItem.key,
                                                 forService: expectItem.service)
            
            XCTAssertEqual(testItem, nil)
        }
    }
    
    func testReadAll() {
        helper.clearKeychain(service: testService)
        
        var expectItems: [String: KeychainItem] = [:]
        
        for i in 0...100 {
            let item = KeychainItem(key: "\(i)MockKey", service: testService, value: UUID().uuidString.data(using: .utf8)!)
            expectItems[item.key] = item
        }
        
        for item in expectItems {
            try! keychain.store(item: item.value, withSecurityLevel: .middle)
        }
        
        let resultItems = try! keychain.getAllItem(service: testService)
        
        XCTAssertEqual(resultItems.count, expectItems.count)
        XCTAssertEqual(resultItems, expectItems)
        for item in expectItems {
            XCTAssertEqual(item.value, resultItems[item.key])
        }
    }
}
