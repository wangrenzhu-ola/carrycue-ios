import Foundation

public enum DraftingError: LocalizedError {
    case notConfigured, invalidResponse

    public var errorDescription: String? {
        switch self {
        case .notConfigured: return "Cloud drafting is not configured. Continue with the manual editor."
        case .invalidResponse: return "The draft could not be read. Your observation is still available for manual editing."
        }
    }
}

public protocol AIDraftProviding {
    func draft(for card: PracticeCard) async throws -> PracticeCard
}

public struct KimiDraftClient: AIDraftProviding {
    private let apiKey: String?
    private let session: URLSession

    public init(apiKey: String? = Bundle.main.object(forInfoDictionaryKey: "KIMI_API_KEY") as? String,
                session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func draft(for card: PracticeCard) async throws -> PracticeCard {
        guard let apiKey, !apiKey.isEmpty, !apiKey.contains("$(") else { throw DraftingError.notConfigured }
        var request = URLRequest(url: URL(string: "https://api.moonshot.cn/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let minimumNecessary = "Target: \(card.targetPhrase)\nObserved response: \(card.observedResponse)\nCue: \(card.cueLevel.rawValue)\nGoal: \(card.practiceGoal)"
        let body: [String: Any] = [
            "model": "moonshot-v1-8k",
            "messages": [
                ["role": "system", "content": "Return JSON only with caregiverPrompt, cueSequence, stopCondition. Do not diagnose or recommend treatment."],
                ["role": "user", "content": minimumNecessary]
            ],
            "temperature": 0.2
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = root["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8),
              let fields = try JSONSerialization.jsonObject(with: contentData) as? [String: String] else {
            throw DraftingError.invalidResponse
        }
        var draft = card
        draft.caregiverPrompt = fields["caregiverPrompt"] ?? ""
        draft.cueSequence = fields["cueSequence"] ?? ""
        draft.stopCondition = fields["stopCondition"] ?? ""
        draft.isApproved = false
        return draft
    }
}
