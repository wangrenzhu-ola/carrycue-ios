import Foundation

public enum CueLevel: String, Codable, CaseIterable, Identifiable {
    case independent = "Independent"
    case semantic = "Semantic cue"
    case firstSound = "First-sound cue"
    case model = "Clinician model"

    public var id: String { rawValue }
}

public struct PracticeCard: Codable, Identifiable, Equatable {
    public var id: UUID
    public var patientLabel: String
    public var targetPhrase: String
    public var observedResponse: String
    public var cueLevel: CueLevel
    public var practiceGoal: String
    public var caregiverPrompt: String
    public var cueSequence: String
    public var stopCondition: String
    public var isApproved: Bool
    public var updatedAt: Date

    public init(
        id: UUID = UUID(), patientLabel: String = "", targetPhrase: String = "",
        observedResponse: String = "", cueLevel: CueLevel = .semantic,
        practiceGoal: String = "", caregiverPrompt: String = "",
        cueSequence: String = "", stopCondition: String = "",
        isApproved: Bool = false, updatedAt: Date = Date()
    ) {
        self.id = id
        self.patientLabel = patientLabel
        self.targetPhrase = targetPhrase
        self.observedResponse = observedResponse
        self.cueLevel = cueLevel
        self.practiceGoal = practiceGoal
        self.caregiverPrompt = caregiverPrompt
        self.cueSequence = cueSequence
        self.stopCondition = stopCondition
        self.isApproved = isApproved
        self.updatedAt = updatedAt
    }

    public var isObservationComplete: Bool {
        [patientLabel, targetPhrase, observedResponse, practiceGoal].allSatisfy {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    public var isHandoffComplete: Bool {
        [caregiverPrompt, cueSequence, stopCondition].allSatisfy {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

public enum CardDrafting {
    public static func manualDraft(from card: PracticeCard) -> PracticeCard {
        var draft = card
        draft.caregiverPrompt = "Invite them to say “\(card.targetPhrase)”. Give time before helping."
        draft.cueSequence = "Wait 5 seconds → use the \(card.cueLevel.rawValue.lowercased()) → model once if needed."
        draft.stopCondition = "Stop after three calm attempts or sooner if frustration appears."
        draft.isApproved = false
        draft.updatedAt = Date()
        return draft
    }
}
