import XCTest
@testable import KeychainSecurity

final class KeychainSecurityLevelTests: XCTestCase {

    var keychain: KeychainAccess = KeychainSecurity.shared
    var helper:KeychainTestHelper = .init()
    
    var lowUser:String = "lowUser"
    var middleUser:String = "middleUser"
    var highUser:String = "highUser"
    
    func testLevelLow() {
        cleanEnv()
        let expectItem = KeychainItem(withMock: lowUser)
        
        try! keychain.store(item: expectItem,
                            withSecurityLevel: .low)
        
        let testItem = try! keychain.getItem(withKey: expectItem.key,
                                             forService: expectItem.service)
        
        XCTAssertEqual(testItem, expectItem)
    }
    
    func testLevelMiddle() {
        cleanEnv()
        
        let expectItem = KeychainItem(withMock: middleUser)
        
        try! keychain.store(item: expectItem,
                            withSecurityLevel: .middle)
        
        let testItem = try! keychain.getItem(withKey: expectItem.key,
                                             forService: expectItem.service)
        
        XCTAssertEqual(testItem, expectItem)
    }
    
    func testLevelHigh() {
        cleanEnv()
        
        let expectItem = KeychainItem(withMock: highUser)
        
        try! keychain.store(item: expectItem,
                            withSecurityLevel: .high)
        
        let testItem = try! keychain.getItem(withKey: expectItem.key,
                                             forService: expectItem.service)
        
        XCTAssertEqual(testItem, expectItem)
    }
    
    private func cleanEnv() {
        helper.clearKeychain(service: lowUser)
        helper.clearKeychain(service: middleUser)
        helper.clearKeychain(service: highUser)
    }
}

