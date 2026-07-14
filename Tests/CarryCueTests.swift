import XCTest
@testable import CarryCue

final class CarryCueTests: XCTestCase {
    func testAC1DraftPreservesPhraseCueAndRequiredHandoffFields() {
        let observation = PracticeCard(patientLabel: "P-17", targetPhrase: "call my daughter", observedResponse: "Needed semantic cue", cueLevel: .semantic, practiceGoal: "Use full phrase")
        let draft = CardDrafting.manualDraft(from: observation)
        XCTAssertTrue(draft.isHandoffComplete)
        XCTAssertFalse(draft.isApproved)
        XCTAssertTrue(draft.caregiverPrompt.contains(observation.targetPhrase))
        XCTAssertTrue(draft.cueSequence.localizedCaseInsensitiveContains("semantic"))
        XCTAssertFalse(draft.stopCondition.isEmpty)
    }

    func testAC2UnapprovedEditStaysOutsideApprovedList() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("cards.json")
        let repository = CardRepository(fileURL: url)
        var draft = CardDrafting.manualDraft(from: PracticeCard(patientLabel: "P-17", targetPhrase: "call my daughter", observedResponse: "Needed semantic cue", practiceGoal: "Use full phrase"))
        draft.caregiverPrompt = "Please invite the full phrase, then wait."
        try repository.upsert(draft)
        XCTAssertEqual(repository.draftCards.first?.caregiverPrompt, draft.caregiverPrompt)
        XCTAssertTrue(repository.approvedCards.isEmpty)
    }

    func testAC3MissingCloudConfigurationKeepsManualWorkflowUsable() async {
        let observation = PracticeCard(patientLabel: "P-17", targetPhrase: "call my daughter", observedResponse: "Needed semantic cue", practiceGoal: "Use full phrase")
        do {
            _ = try await KimiDraftClient(apiKey: nil).draft(for: observation)
            XCTFail("Expected missing configuration")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Cloud drafting is not configured. Continue with the manual editor.")
        }
        XCTAssertTrue(CardDrafting.manualDraft(from: observation).isHandoffComplete)
    }

    func testAC4ApprovedCardReopensAndCanBeRevisedThenDeleted() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("cards.json")
        let repository = CardRepository(fileURL: url)
        var card = CardDrafting.manualDraft(from: PracticeCard(patientLabel: "P-17", targetPhrase: "call my daughter", observedResponse: "Needed semantic cue", practiceGoal: "Use full phrase"))
        card.isApproved = true
        try repository.upsert(card)
        var reopened = try XCTUnwrap(CardRepository(fileURL: url).approvedCards.first)
        XCTAssertEqual(reopened.targetPhrase, "call my daughter")
        reopened.caregiverPrompt = "Revised caregiver prompt"
        try repository.upsert(reopened)
        XCTAssertEqual(CardRepository(fileURL: url).approvedCards.first?.caregiverPrompt, "Revised caregiver prompt")
        try repository.delete(id: card.id)
        XCTAssertTrue(CardRepository(fileURL: url).cards.isEmpty)
    }
}
