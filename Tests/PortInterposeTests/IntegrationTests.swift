import Testing
import Foundation

struct IntegrationTests {
    @Test
    func sanity() async throws {
        try await expectScriptSuccess(resourcePath: "Scripts/TestSanity", arguments: [])
    }
    
    @Test
    func interpose() async throws {
        let dylibPath = try dylibPath()
        try await expectScriptSuccess(resourcePath: "Scripts/TestInterpose", arguments: [dylibPath])
    }
    
    func expectScriptSuccess(resourcePath: String, arguments: [String], sourceLocation: SourceLocation = #_sourceLocation) async throws {
        let bundle = Bundle.module
        let executableURL = try #require(
            bundle.url(forResource: resourcePath, withExtension: nil),
            "Could not locate \(resourcePath) in test resources",
            sourceLocation: sourceLocation
        )
        let outputData = try await outputFromLaunching(executableURL: executableURL, arguments: arguments)
        let output: String? = if let outputData { String(data: outputData, encoding: .utf8) } else { nil }
        #expect(output == nil)
    }
}

func dylibPath(sourceLocation: SourceLocation = #_sourceLocation) throws -> String {
    let dylibURL = try #require(
        lookupFile(inDirectory: builtProductsDirectory(), paths:  [
            "libPortInterpose.dylib",
            "PackageFrameworks/PortInterpose.framework/PortInterpose"
        ]),
        "Could not locate PortInterpose .dylib",
        sourceLocation: sourceLocation
    )
    return dylibURL.path
}

func builtProductsDirectory() -> URL {
    class BundleTag {}
    let testBundleURL = Bundle(for: BundleTag.self).bundleURL
    let builtProductsDirectory = testBundleURL.deletingLastPathComponent()
    return builtProductsDirectory
}

func lookupFile(inDirectory directory: URL, paths: [String]) -> URL? {
    for path in paths {
        let testURL = directory.appendingPathComponent(path)
        if FileManager.default.fileExists(atPath: testURL.path) {
            return testURL
        }
    }
    return nil
}
