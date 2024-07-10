import XCTest
import SwiftDemangle

private let kCommonSymbol = "s:10DriverCore28AddPhoneVerifyViewControllerC28resendCodeViaVoiceCallButton33_3079D27A166598D3B3B79EAC945873F9LLSo8UIButtonCSgvp"
private let kExtensionUSR = "s:e:s:14Unidirectional14EffectProducerV10Onboarding7LyftKit13NonemptyStackVyAD0D5StateV_yAD9GuestUserOctGRszAD0D10ActionMask_pRs_rlE010submitNameB0ACyAldM_pGvpZ"

final class SwiftDemangleTests: XCTestCase {

    func testDemangle() throws {
        let demangler = Demangler()
        let root = try XCTUnwrap(demangler.demangle(symbol: kCommonSymbol))
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

    func testSwiftExtensionUSR() throws {
        let demangler = Demangler()
        let root = try XCTUnwrap(demangler.demangle(symbol: kExtensionUSR))
        let textNodes = Set(root.breadthFirstSequence().compactMap { $0.text })
        XCTAssertEqual(textNodes, [
            "EffectProducer",
            "GuestUser",
            "LyftKit",
            "NonemptyStack",
            "Onboarding",
            "OnboardingActionMask",
            "OnboardingState",
            "submitNameEffect",
            "Unidirectional",
        ])
    }

    func testBreathFirstSequence() throws {
        let demangler = Demangler()
        let root = try XCTUnwrap(demangler.demangle(symbol: kCommonSymbol))
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
