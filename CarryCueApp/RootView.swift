import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationView { CardLibraryView() }
                .tabItem { Label("Cards", systemImage: "rectangle.stack") }
            NavigationView { PrivacyView() }
                .tabItem { Label("Privacy", systemImage: "hand.raised") }
        }
        .accentColor(Color("InkGreen"))
    }
}

struct CardLibraryView: View {
    @EnvironmentObject private var repository: CardRepository
    @State private var editorCard: PracticeCard?
    @State private var showingDrafts = false
    @State private var errorMessage: AlertMessage?

    private var visibleCards: [PracticeCard] {
        showingDrafts ? repository.draftCards : repository.approvedCards
    }

    var body: some View {
        List {
            LibraryHeader(approvedCount: repository.approvedCards.count, draftCount: repository.draftCards.count)
                .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 12, trailing: 20))
                .listRowBackground(Color("WarmPaper"))

            Picker("Card status", selection: $showingDrafts) {
                Text("Approved").tag(false)
                Text("Needs review").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .listRowBackground(Color("WarmPaper"))

            if visibleCards.isEmpty {
                EmptyLibraryState(showingDrafts: showingDrafts, create: createCard)
                    .listRowBackground(Color("WarmPaper"))
            } else {
                ForEach(visibleCards) { card in
                    Button { editorCard = card } label: { CardRow(card: card) }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Open \(card.targetPhrase), \(card.isApproved ? "approved" : "needs review")")
                }
                .onDelete(perform: deleteCards)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("CarryCue")
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(action: createCard) { Image(systemName: "plus") }.accessibilityLabel("Create practice card") } }
        .sheet(item: $editorCard) { card in CardEditorView(card: card) }
        .alert(item: $errorMessage) { message in Alert(title: Text("Couldn’t update cards"), message: Text(message.text)) }
    }

    private func createCard() { editorCard = PracticeCard() }

    private func deleteCards(at offsets: IndexSet) {
        do { for index in offsets { try repository.delete(id: visibleCards[index].id) } }
        catch { errorMessage = AlertMessage(error.localizedDescription) }
    }
}

private struct LibraryHeader: View {
    let approvedCount: Int
    let draftCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Session → home, without losing the cue")
                .font(.system(.title2, design: .rounded)).fontWeight(.bold)
                .foregroundColor(Color("DeepInk"))
            Text("Turn today’s observed phrase into a caregiver-ready card. Nothing is approved until you say so.")
                .font(.subheadline).foregroundColor(.secondary)
            HStack(spacing: 20) {
                Label("\(approvedCount) approved", systemImage: "checkmark.seal.fill")
                Label("\(draftCount) to review", systemImage: "pencil.and.outline")
            }
            .font(.caption).foregroundColor(Color("InkGreen"))
        }
    }
}

private struct EmptyLibraryState: View {
    let showingDrafts: Bool
    let create: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: showingDrafts ? "checkmark.circle" : "quote.bubble")
                .font(.system(size: 36)).foregroundColor(Color("Clay"))
            Text(showingDrafts ? "No cards need review" : "Preserve the cue while it’s fresh").font(.headline)
            Text(showingDrafts ? "Drafts appear here until you approve them." : "Capture one target phrase, what happened, and the cue that helped.")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            if !showingDrafts { Button("Create first card", action: create).buttonStyle(PrimaryButtonStyle()) }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 34)
    }
}

private struct CardRow: View {
    let card: PracticeCard

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 3).fill(card.isApproved ? Color("InkGreen") : Color("Clay")).frame(width: 5)
            VStack(alignment: .leading, spacing: 6) {
                Text("“\(card.targetPhrase)”").font(.headline).foregroundColor(Color("DeepInk"))
                Text("\(card.patientLabel) · \(card.cueLevel.rawValue)").font(.caption).foregroundColor(.secondary)
                Text(card.isApproved ? "Approved for home practice" : "Draft — clinician review required")
                    .font(.caption2).fontWeight(.semibold).foregroundColor(card.isApproved ? Color("InkGreen") : Color("Clay"))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundColor(.white).padding(.horizontal, 18).padding(.vertical, 12)
            .background(Color("InkGreen").opacity(configuration.isPressed ? 0.75 : 1)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AlertMessage: Identifiable {
    let id = UUID()
    let text: String
    init(_ text: String) { self.text = text }
}
