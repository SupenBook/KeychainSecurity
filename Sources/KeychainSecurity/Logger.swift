import Logging

let logger: Logger = {
    var logger = Logger(label: "keychain-security")
    logger.logLevel = .debug
    return logger
}()
