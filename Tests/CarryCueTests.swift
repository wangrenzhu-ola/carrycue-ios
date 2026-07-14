import XCTest
@testable import CarryCue

final class CarryCueTests: XCTestCase {
    func testApprovalGateAndManualFallback() {
        let observation = PracticeCard(patientLabel: "P-17", targetPhrase: "call my daughter", observedResponse: "Needed semantic cue", cueLevel: .semantic, practiceGoal: "Use full phrase")
        let draft = CardDrafting.manualDraft(from: observation)
        XCTAssertTrue(draft.isHandoffComplete)
        XCTAssertFalse(draft.isApproved)
        XCTAssertTrue(draft.caregiverPrompt.contains(observation.targetPhrase))
    }
}
