
//  VIEW
//  The "Settings" tab: your own cycle and period lengths, and the time of
//  day the reminder fires.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: CycleViewModel

    // What's typed in the boxes. Kept as text while you type, and only
    // turned into numbers and saved when you're done editing.
    @State private var cycleLengthText = ""
    @State private var periodLengthText = ""
    @State private var reminderTime = Date()

    @State private var showSavedMessage = false

    /// True while the keyboard is up on one of the number boxes.
    @FocusState private var isTyping: Bool

    var body: some View {
        NavigationStack {
            Form {
                lengthsSection
                automaticSection
                reminderSection
            }
            .navigationTitle("Settings")
            .onAppear {
                loadFields()
            }
            // Save the numbers as soon as you leave the boxes.
            .onChange(of: isTyping) { _, typing in
                if !typing {
                    saveLengths()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isTyping = false
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTyping = false
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var lengthsSection: some View {
        Section {
            HStack {
                Text("Average cycle length")
                Spacer()
                TextField("28", text: $cycleLengthText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .focused($isTyping)
                Text("days").foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Text("Average period length")
                Spacer()
                TextField("5", text: $periodLengthText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .focused($isTyping)
                Text("days").foregroundStyle(Theme.inkSoft)
            }
        } header: {
            HStack {
                Text("Cycle settings")
                if showSavedMessage {
                    Spacer()
                    Text("Saved ✓")
                        .foregroundStyle(Theme.bambooGreen)
                }
            }
        } footer: {
            Text("Tide calculates these automatically from your logged history. Enter your own numbers here if you know them better, or use the button below to go back to automatic. Changes save when you tap Done.")
        }
    }

    private var automaticSection: some View {
        Section {
            Button("Use automatic calculation") {
                isTyping = false
                viewModel.useAutomaticLengths()
                loadFields()
                flashSavedMessage()
            }
            .foregroundStyle(Theme.primary)
            .fontWeight(.semibold)
        }
    }

    private var reminderSection: some View {
        Section {
            DatePicker("Remind me at", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .onChange(of: reminderTime) { _, newTime in
                    let hour = Calendar.current.component(.hour, from: newTime)
                    let minute = Calendar.current.component(.minute, from: newTime)
                    viewModel.setReminderTime(hour: hour, minute: minute)
                }
        } header: {
            Text("Reminder time")
        } footer: {
            Text("This is when your daily period reminder will fire, once you're due.")
        }
    }

    // MARK: - Loading and saving

    /// Fills the boxes with the current values. This only shows them;
    /// it doesn't save anything.
    private func loadFields() {
        let data = viewModel.data
        cycleLengthText = "\(data.cycleLength)"
        periodLengthText = "\(data.periodLength)"

        var time = DateComponents()
        time.hour = data.reminderHour
        time.minute = data.reminderMinute
        reminderTime = Calendar.current.date(from: time) ?? Date()
    }

    /// Saves a box as your own number only if you actually changed it.
    /// Untouched boxes keep working automatically.
    private func saveLengths() {
        let data = viewModel.data

        var newCycle = data.customCycleLength
        if let typed = Int(cycleLengthText), typed != data.cycleLength {
            newCycle = typed
        }

        var newPeriod = data.customPeriodLength
        if let typed = Int(periodLengthText), typed != data.periodLength {
            newPeriod = typed
        }

        // Nothing changed, so there's nothing to save.
        if newCycle == data.customCycleLength && newPeriod == data.customPeriodLength {
            loadFields()
            return
        }

        viewModel.setCustomLengths(cycle: newCycle, period: newPeriod)
        loadFields()   // shows the number that was actually saved
        flashSavedMessage()
    }

    /// Shows "Saved ✓" for a moment.
    private func flashSavedMessage() {
        withAnimation {
            showSavedMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation {
                showSavedMessage = false
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CycleViewModel())
}
