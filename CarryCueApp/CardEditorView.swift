import SwiftUI

struct CardEditorView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var repository: CardRepository
    @State private var card: PracticeCard
    @State private var consented = false
    @State private var isDrafting = false
    @State private var errorMessage: AlertMessage?
    @State private var savedMessage: AlertMessage?

    init(card: PracticeCard) { _card = State(initialValue: card) }

    var body: some View {
        NavigationView {
            Form {
                ObservationSection(card: $card)
                DraftingSection(card: $card, consented: $consented, isDrafting: isDrafting, draftWithAI: draftWithAI, draftManually: draftManually)
                HandoffSection(card: $card)
                ApprovalSection(card: $card)
            }
            .navigationTitle(card.targetPhrase.isEmpty ? "New observation" : card.targetPhrase)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { presentationMode.wrappedValue.dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!card.isObservationComplete || !card.isHandoffComplete) }
            }
            .alert(item: $errorMessage) { Alert(title: Text("Draft unavailable"), message: Text($0.text), dismissButton: .default(Text("Use manual editor"), action: draftManually)) }
            .alert(item: $savedMessage) { Alert(title: Text("Saved"), message: Text($0.text), dismissButton: .default(Text("Done")) { presentationMode.wrappedValue.dismiss() }) }
        }
    }

    private func draftManually() { card = CardDrafting.manualDraft(from: card) }

    private func draftWithAI() {
        guard consented else { errorMessage = AlertMessage("Review and accept the per-card cloud drafting consent first."); return }
        isDrafting = true
        Task {
            defer { isDrafting = false }
            do {
                let draft = try await KimiDraftClient().draft(for: card)
                guard !Task.isCancelled else { return }
                card = draft
            }
            catch { errorMessage = AlertMessage(error.localizedDescription) }
        }
    }

    private func save() {
        do {
            try repository.upsert(card)
            savedMessage = AlertMessage(card.isApproved ? "This card is approved and appears in the home-practice list." : "This remains a draft and will not appear among approved cards.")
        } catch { errorMessage = AlertMessage(error.localizedDescription) }
    }
}

private struct ObservationSection: View {
    @Binding var card: PracticeCard
    var body: some View {
        Section(header: Text("What happened today"), footer: Text("Use a pseudonymous label. Do not enter a diagnosis, contact detail, or record number.")) {
            TextField("Patient label, e.g. P-17", text: $card.patientLabel).accessibilityLabel("Pseudonymous patient label")
            TextField("Target phrase", text: $card.targetPhrase)
            TextField("Observed response", text: $card.observedResponse)
            Picker("Cue that helped", selection: $card.cueLevel) { ForEach(CueLevel.allCases) { Text($0.rawValue).tag($0) } }
            TextField("Practice goal", text: $card.practiceGoal)
        }
    }
}

private struct DraftingSection: View {
    @Binding var card: PracticeCard
    @Binding var consented: Bool
    let isDrafting: Bool
    let draftWithAI: () -> Void
    let draftManually: () -> Void

    var body: some View {
        Section(header: Text("Start the handoff"), footer: Text("Cloud drafting sends only the target, observed response, cue, and goal. It never saves or approves the result.")) {
            Toggle("I consent to send these four typed fields for this card", isOn: $consented)
            Button(isDrafting ? "Drafting…" : "Draft with AI", action: draftWithAI).disabled(isDrafting || !card.isObservationComplete)
            Button("Create manual starting point", action: draftManually).disabled(!card.isObservationComplete)
        }
    }
}

private struct HandoffSection: View {
    @Binding var card: PracticeCard
    var body: some View {
        Section(header: Text("Caregiver practice card"), footer: Text("Edit every line. Keep the instruction within your clinical judgment.")) {
            TextField("Caregiver prompt", text: $card.caregiverPrompt)
            TextField("Cue sequence", text: $card.cueSequence)
            TextField("When to stop", text: $card.stopCondition)
        }
    }
}

private struct ApprovalSection: View {
    @Binding var card: PracticeCard
    var body: some View {
        Section(header: Text("Clinician decision"), footer: Text(card.isApproved ? "Approved cards are ready for caregiver handoff." : "Unapproved cards stay in Needs Review.")) {
            Toggle("I reviewed and approve this card", isOn: $card.isApproved).disabled(!card.isHandoffComplete)
        }
    }
}
