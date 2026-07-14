import SwiftUI

@main
struct CarryCueApp: App {
    @StateObject private var repository = CardRepository()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(repository)
        }
    }
}
