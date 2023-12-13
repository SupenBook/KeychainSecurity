import Logging

let logger: Logger = {
    var logger = Logger(label: "keychain-security")
    logger.logLevel = .debug
    return logger
}()

//public protocol Loggable {
//    typealias Message = String
//
//    func log(level: LoggerLevel, _ message: @autoclosure () -> Message, file: String, function: String, line: UInt)
//}
//
//extension Loggable {
//    func log(level: LoggerLevel,
//             _ message: @autoclosure () -> Message,
//             source: @autoclosure () -> String? = nil,
//             file: String = #file, function: String = #function, line: UInt = #line) {
//        log(level: level, message(), file: file, function: function, line: line)
//    }
//
//    func debug(_ message: @autoclosure () -> Message,
//               source: @autoclosure () -> String? = nil,
//               file: String = #file, function: String = #function, line: UInt = #line) {
//        log(level: .debug, message(), file: file, function: function, line: line)
//    }
//
//    func info(_ message: @autoclosure () -> Message,
//              source: @autoclosure () -> String? = nil,
//              file: String = #file, function: String = #function, line: UInt = #line) {
//        log(level: .info, message(), file: file, function: function, line: line)
//    }
//
//    func error(_ message: @autoclosure () -> Message,
//               source: @autoclosure () -> String? = nil,
//               file: String = #file, function: String = #function, line: UInt = #line) {
//        log(level: .error, message(), file: file, function: function, line: line)
//    }
//}
