import SwiftUI

struct PrivacyView: View {
    var body: some View {
        List {
            Section(header: Text("Your boundary")) {
                PrivacyRow(icon: "iphone", title: "Cards stay on this device", detail: "Practice cards use local app storage. CarryCue has no account or cloud sync.")
                PrivacyRow(icon: "person.crop.circle.badge.xmark", title: "Pseudonyms, not identifiers", detail: "Use a short patient label. Do not enter names, contact details, record numbers, diagnoses, or audio.")
                PrivacyRow(icon: "cloud", title: "Cloud AI is per-card and optional", detail: "Only four typed fields are sent after consent. Manual creation, approval, revision, and deletion work without it.")
            }
            Section(header: Text("Clinical control")) {
                Text("AI drafts are editable and remain unapproved. A clinician must review and explicitly approve every caregiver-facing card.")
                Text("CarryCue does not diagnose, recommend treatment, or replace professional judgment.")
            }
            Section(header: Text("Device permissions")) {
                Text("CarryCue does not request camera, microphone, photo library, contacts, location, or tracking access.")
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Privacy & safety")
    }
}

private struct PrivacyRow: View {
    let icon: String
    let title: String
    let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).frame(width: 24).foregroundColor(Color("InkGreen"))
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline); Text(detail).font(.subheadline).foregroundColor(.secondary) }
        }.padding(.vertical, 5)
    }
}
