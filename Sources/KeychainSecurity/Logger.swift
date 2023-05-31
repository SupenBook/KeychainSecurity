
public func setup(logger instance: Loggable) {
    logger = instance
}

public enum LoggerLevel: String {
    /// Appropriate for messages that contain information normally of use only when
    /// tracing the execution of a program.
    case trace

    /// Appropriate for messages that contain information normally of use only when
    /// debugging a program.
    case debug

    /// Appropriate for informational messages.
    case info

    /// Appropriate for conditions that are not error conditions, but that may require
    /// special handling.
    case notice

    /// Appropriate for messages that are not error conditions, but more severe than
    /// `.notice`.
    case warning

    /// Appropriate for error conditions.
    case error

    /// Appropriate for critical error conditions that usually require immediate
    /// attention.
    ///
    /// When a `critical` message is logged, the logging backend (`LogHandler`) is free to perform
    /// more heavy-weight operations to capture system state (such as capturing stack traces) to facilitate
    /// debugging.
    case critical
}

var logger: Loggable = Logger()

public protocol Loggable {
    typealias Message = String

    func log(level: LoggerLevel, _ message: @autoclosure () -> Message, file: String, function: String, line: UInt)
}

extension Loggable {
    func log(level: LoggerLevel,
             _ message: @autoclosure () -> Message,
             source: @autoclosure () -> String? = nil,
             file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: level, message(), file: file, function: function, line: line)
    }

    func debug(_ message: @autoclosure () -> Message,
               source: @autoclosure () -> String? = nil,
               file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .debug, message(), file: file, function: function, line: line)
    }

    func info(_ message: @autoclosure () -> Message,
              source: @autoclosure () -> String? = nil,
              file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .info, message(), file: file, function: function, line: line)
    }

    func error(_ message: @autoclosure () -> Message,
               source: @autoclosure () -> String? = nil,
               file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .error, message(), file: file, function: function, line: line)
    }
}

struct Logger: Loggable {
    func log(level: LoggerLevel, _ message: @autoclosure () -> String, file: String, function: String, line: UInt) {
        debugPrint("[\(level)][Persistent] \(message())")
    }
}
