import XCTest
import SwiftDemangle

final class SwiftDemangleTests: XCTestCase {
    private static let CommonSymbol = "s:10DriverCore28AddPhoneVerifyViewControllerC28resendCodeViaVoiceCallButton33_3079D27A166598D3B3B79EAC945873F9LLSo8UIButtonCSgvp"

    func testDemangle() throws {
        let demangler = Demangler()
        let root = try XCTUnwrap(demangler.demangle(symbol: Self.CommonSymbol))
        let moduleNode = root.children[0].children[0].children[0]
        try XCTAssertEqual(XCTUnwrap(moduleNode.text), "DriverCore")
        let classNode = root.children[0].children[0].children[1]
        try XCTAssertEqual(XCTUnwrap(classNode.text), "AddPhoneVerifyViewController")
    }

    func testObjCUSR() {
        let demangler = Demangler()
        let symbol = "c:objc(cs)CIVector"
        XCTAssertNil(demangler.demangle(symbol: symbol))
    }

    func testBreathFirstSequence() throws {
        let demangler = Demangler()
        let root = try XCTUnwrap(demangler.demangle(symbol: Self.CommonSymbol))
        let textNodes = root.breadthFirstSequence().compactMap { $0.text }
        XCTAssertEqual(textNodes, [
            "DriverCore",
            "AddPhoneVerifyViewController",
            "_3079D27A166598D3B3B79EAC945873F9",
            "resendCodeViaVoiceCallButton",
            "Swift",
            "Optional",
            "__C",
            "UIButton",
        ])
    }
}
