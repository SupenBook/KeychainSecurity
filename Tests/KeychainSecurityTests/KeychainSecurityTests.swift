import XCTest
@testable import KeychainSecurity

final class KeychainSecurityTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(KeychainSecurity().text, "Hello, World!")
    }
}
