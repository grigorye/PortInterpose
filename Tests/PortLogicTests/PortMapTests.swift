@testable import PortLogic
import Testing
import Foundation

struct PortMapTests {
    @Test func validEnvironmentValue() throws {
        try #expect(portMapFromEnvVarValue(#"{"7381": "7382"}"#) == [7381: 7382])
    }
    
    @Test func invalidEnvironmentValue() throws {
        #expect(throws: (any Error).self) {
            try portMapFromEnvVarValue(#"{"7381" : "738x2"}"#)
        }
        #expect(throws: (any Error).self) {
            try portMapFromEnvVarValue(#"{"7381" : 7382}"#)
        }
    }
}
