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
            
            let expectItem = KeychainItem(withMock: testService)
            
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
            
            var expectItem = KeychainItem(withMock: testService)
            
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
            
            var expectItem = KeychainItem(withMock: testService)
            
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
}
