import Testing
import Foundation

struct IntegrationTests {
    @Test
    func sanity() async throws {
        try await test(sourcePort: 33333, mappedPort: 33333, envExtras: [:])
    }

    @Test
    func mapping() async throws {
        guard let dylibPath = dylibPath() else {
            #expect(Bool(false))
            return
        }
        let sourcePort = 2345
        let mappedPort = 5432
        let interposeEnvironment: [String: String] = [
            "DYLD_INSERT_LIBRARIES": dylibPath,
            "DYLD_FORCE_FLAT_NAMESPACE": "1",
            "PORT_INTERPOSE_MAP": "{ \"\(sourcePort)\" : \"\(mappedPort)\" }"
        ]
        try await test(sourcePort: sourcePort, mappedPort: mappedPort, envExtras: interposeEnvironment)
    }
    
    func test(sourcePort: Int, mappedPort: Int, envExtras: [String: String]) async throws {
        let bundle = Bundle.module
        guard let testExecutableURL = bundle.url(forResource: "TestInterpose", withExtension: nil) else {
            #expect(Bool(false))
            return
        }
        // We invoke the shell script with a bash from Homebrew, standard bash executable is protected from
        // DYLD_ injections.
        let args = ["-c", "\(testExecutableURL.absoluteURL.path) \(sourcePort) \(mappedPort)"]
        let bashURL = URL(filePath: "/opt/homebrew/bin/bash")!
        let outputData = try await outputFromLaunching(executableURL: bashURL, arguments: args, environment: envExtras)
        let output: String? = if let outputData { String(data: outputData, encoding: .utf8) } else { nil }
        #expect(output == nil)
    }
}

func dylibPath() -> String? {
    class BundleTag {}
    let testBundleURL = Bundle(for: BundleTag.self).bundleURL
    let builtProductsURL = testBundleURL.deletingLastPathComponent()
    let dylibURL: URL? = {
        let pathsToLookup = [
            "libPortInterpose.dylib",
            "PackageFrameworks/PortInterpose.framework/PortInterpose"
        ]
        for path in pathsToLookup {
            let testURL = builtProductsURL.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: testURL.path) {
                return testURL
            }
        }
        return nil
    }()
    return dylibURL?.path
}
