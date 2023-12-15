import Foundation

public struct KeychainItem: Hashable {
    public init(key: String, service: String, value: Data) {
        self.key = key
        self.service = service
        self.value = value
    }

    init(withMock key: String, service: String) {
        self.key = key + "MockKey"
        self.service = service
        self.value = UUID().uuidString.data(using: .utf8)!
    }

    public var key: String
    public var service: String
    public var value: Data
}
