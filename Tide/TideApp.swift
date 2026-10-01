
//
//  The starting point of the app. It creates the one CycleViewModel and
//  hands it to every screen with .environmentObject.
//

import SwiftUI

@main
struct TideApp: App {

    /// The single ViewModel the whole app shares.
    @StateObject private var viewModel = CycleViewModel()

    /// Tells us when the app opens, goes to the background, etc.
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Sets up the "Log Period Start" button on reminder notifications.
        NotificationManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                    // Lets the notification button log through the ViewModel
                    // while the app is open, so the screen updates right away.
                    NotificationManager.shared.viewModel = viewModel
                }
                .onChange(of: scenePhase) { _, newPhase in
                    // When you come back to the app, reload the data in case
                    // you logged a period from the widget or a notification.
                    if newPhase == .active {
                        viewModel.reload()
                    }
                }
        }
    }
}
