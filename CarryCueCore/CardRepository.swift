import Foundation

public final class CardRepository: ObservableObject {
    @Published public private(set) var cards: [PracticeCard] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.fileURL = fileURL ?? base.appendingPathComponent("CarryCue/cards.json")
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    public var approvedCards: [PracticeCard] { cards.filter(\.isApproved) }
    public var draftCards: [PracticeCard] { cards.filter { !$0.isApproved } }

    public func upsert(_ card: PracticeCard) throws {
        var updated = card
        updated.updatedAt = Date()
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = updated
        } else {
            cards.append(updated)
        }
        cards.sort { $0.updatedAt > $1.updatedAt }
        try persist()
    }

    public func delete(id: UUID) throws {
        cards.removeAll { $0.id == id }
        try persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([PracticeCard].self, from: data) else { return }
        cards = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func persist() throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(cards).write(to: fileURL, options: .atomic)
    }
}
