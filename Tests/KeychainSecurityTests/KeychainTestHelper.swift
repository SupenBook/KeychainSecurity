import Foundation

struct KeychainTestHelper {
  func clearKeychain(service:String?) {
    let secItemClasses = [kSecClassGenericPassword,
                          kSecClassInternetPassword,
                          kSecClassCertificate,
                          kSecClassKey,
                          kSecClassIdentity]
    for itemClass in secItemClasses {
      var spec = [String:Any]()
      spec[kSecClass as String] = itemClass
      spec[kSecAttrService as String] = service
      SecItemDelete(spec as CFDictionary)
    }
  }
}
