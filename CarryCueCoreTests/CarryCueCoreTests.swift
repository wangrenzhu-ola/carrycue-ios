import XCTest
@testable import CarryCueCore

final class CarryCueCoreTests: XCTestCase {
    func testManualDraftPreservesTargetCueAndIsUnapproved() {
        let observation = PracticeCard(patientLabel: "P-17", targetPhrase: "call my daughter", observedResponse: "Paused after call", cueLevel: .semantic, practiceGoal: "Use the full phrase")
        let draft = CardDrafting.manualDraft(from: observation)
        XCTAssertTrue(draft.caregiverPrompt.contains("call my daughter"))
        XCTAssertTrue(draft.cueSequence.contains("semantic"))
        XCTAssertFalse(draft.stopCondition.isEmpty)
        XCTAssertFalse(draft.isApproved)
    }

    func testDraftDoesNotAppearAsApprovedAndPersists() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("cards.json")
        let repository = CardRepository(fileURL: url)
        var card = CardDrafting.manualDraft(from: PracticeCard(patientLabel: "P-17", targetPhrase: "call my daughter", observedResponse: "Needed a cue", practiceGoal: "Complete phrase"))
        try repository.upsert(card)
        XCTAssertEqual(repository.approvedCards.count, 0)
        card.isApproved = true
        try repository.upsert(card)
        XCTAssertEqual(CardRepository(fileURL: url).approvedCards.first?.targetPhrase, "call my daughter")
    }

    func testDeleteRemovesPersistedCard() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("cards.json")
        let repository = CardRepository(fileURL: url)
        let card = PracticeCard(
            patientLabel: "P-22",
            targetPhrase: "good morning",
            observedResponse: "Independent",
            practiceGoal: "Repeat twice",
            caregiverPrompt: "Invite the full phrase, then wait.",
            cueSequence: "Wait five seconds before one model.",
            stopCondition: "Stop after three calm attempts.",
            isApproved: true
        )
        try repository.upsert(card)
        try repository.delete(id: card.id)
        XCTAssertTrue(CardRepository(fileURL: url).cards.isEmpty)
    }
}
