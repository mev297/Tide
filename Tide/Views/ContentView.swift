
//  VIEW
//  The four tabs at the bottom of the app. Also shows the "That's a short
//  gap" alert, which can be triggered from both the Today and Calendar tabs,
//  better for it to live on one place. i can use it elsewhere if i want
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: CycleViewModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "drop.fill") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.primary)
        .alert("That's a short gap", isPresented: $viewModel.showShortGapAlert) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelPendingLog()
            }
            Button("Log anyway") {
                viewModel.confirmPendingLog()
            }
        } message: {
            Text(viewModel.shortGapMessage)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CycleViewModel())
}
