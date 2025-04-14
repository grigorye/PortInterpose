import Foundation
import os.log

private let log = Logger(subsystem: logSubsystem, category: #fileID)

private typealias JsonPortMap = [String: String]
typealias PortMap = [UInt16: UInt16]

func portMapFromEnvVarValue(_ value: String) throws -> PortMap {
    typealias Error = PortMapEnvVarError
    let jsonPortMap = try JSONDecoder().decode(JsonPortMap.self, from: value.data(using: .utf8)!)
    return try Dictionary(uniqueKeysWithValues: jsonPortMap.map { (key: String, value: String) in
        guard let key = PortMap.Key(key), let value = PortMap.Value(value) else {
            throw Error.invalidStringForParsing(key, value)
        }
        return (key, value)
    })
}

enum PortMapEnvVarError: Swift.Error {
    case invalidStringForParsing(String, String)
}

let portMap: PortMap? = {
    guard let envValue = ProcessInfo().environment[EnvironmentVariables.portMap] else {
        log.info("Map not found")
        return nil
    }
    log.debug("Map in environment: \(envValue, privacy: .public)")
    do {
        let portMap = try portMapFromEnvVarValue(envValue)
        log.info("Parsed map: \(portMap, privacy: .public)")
        return portMap
    } catch {
        log.error("Could not parse map: \(error, privacy: .public)")
        return nil
    }
}()
