import Foundation
import os.log

private let log = Logger(subsystem: loggerSubsystem, category: #fileID)

func outputFromLaunching(
    executableURL: URL,
    arguments: [String],
    environment: [String: String]? = nil
) async throws -> Data? {
    return try await withCheckedThrowingContinuation { c in
        outputFromLaunching(
            executableURL: executableURL,
            arguments: arguments,
            environment: environment,
            continuation: c
        )
    }
}

func outputFromLaunching(
    executableURL: URL,
    arguments: [String],
    environment: [String: String]? = nil,
    continuation c: CheckedContinuation<Data?, Error>
) {
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments
    process.environment = environment
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    process.terminationHandler = { process in
        let r = Result {
            try checkTerminationStatusAndAccumulateOutput(
                process,
                stdout: stdoutPipe.fileHandleForReading,
                stderr: stderrPipe.fileHandleForReading
            )
        }
        c.resume(with: r)
    }
    let argsFormatted = arguments.joined(separator: " ")
    let executablePath = executableURL.standardizedFileURL.path
    do {
        try process.run()
        let pid = process.processIdentifier
        log.debug("Launched (\(pid)): \(executablePath) \(argsFormatted)")
    } catch {
        log.error("Launch failed: \(executablePath) \(argsFormatted)")
        c.resume(throwing: error)
    }
}

func checkTerminationStatusAndAccumulateOutput(
    _ process: Process,
    stdout: FileHandle,
    stderr: FileHandle
) throws -> Data? {
    let pid = process.processIdentifier
    log.debug("Terminated (\(pid))")
    let stdoutData = try stdout.readToEnd()
    let stdoutDump = formatData(stdoutData)
    log.debug("Stdout (\(pid)):\n\(stdoutDump, privacy: .public)")
    let stderrData = try stderr.readToEnd()
    let stderrDump = formatData(stderrData)
    log.debug("Stderr (\(pid)):\n\(stderrDump, privacy: .public)")
    let terminationReason = process.terminationReason
    guard case .exit = terminationReason else {
        log.error("Exec failed (\(pid)). Not exited normally: \(String(describing: terminationReason))")
        log.error("Stderr (\(pid)):\n\(stderrDump, privacy: .public)")
        throw OutputFromLaunchingError.badTerminationReason(terminationReason)
    }
    let terminationStatus = process.terminationStatus
    guard 0 == terminationStatus else {
        log.error("Exec failed (\(pid)). Exit status: \(terminationStatus)")
        log.error("Stderr (\(pid)):\n\(stderrDump, privacy: .public)")
        throw OutputFromLaunchingError.badTerminationStatus(terminationStatus)
    }
    log.debug("Succeeded (\(pid))")
    return stdoutData
}

enum OutputFromLaunchingError: Error {
    case badTerminationReason(Process.TerminationReason)
    case badTerminationStatus(Int32)
}

func formatData(_ data: Data?) -> String {
    guard let data else {
        return "<null>"
    }
    guard let dump = String(data: data, encoding: .utf8) else {
        return "<redacted.non-utf-8>"
    }
    return dump
}
