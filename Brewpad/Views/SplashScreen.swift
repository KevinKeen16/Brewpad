import SwiftUI

struct SplashScreen: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var rotationAngle: Double = 0
    @State private var quipOpacity: Double = 0
    @State private var currentQuip: String = ""
    @State private var showConfetti: Bool = false
    private var isBirthday: Bool {
        guard let birthday = settingsManager.birthdate else { return false }
        let calendar = Calendar.current
        let today = calendar.dateComponents([.month, .day], from: Date())
        let components = calendar.dateComponents([.month, .day], from: birthday)
        return today.month == components.month && today.day == components.day
    }
    let action: AppState.AppAction?
    
    init(action: AppState.AppAction? = nil) {
        self.action = action
    }
    
    private var cupColor: Color {
        if settingsManager.isDebugModeEnabled {
            return HolidayTheme.getColor(for: settingsManager.debugHoliday)
        }
        
        // Check for actual holiday
        let today = Calendar.current.dateComponents([.month, .day], from: Date())
        let month = today.month!
        let day = today.day!
        
        let holiday: SettingsManager.Holiday? = {
            switch (month, day) {
            case (12, 24): return .christmasEve
            case (12, 25): return .christmasDay
            case (12, 31): return .newYearsEve
            case (1, 1): return .newYearsDay
            case (2, 14): return .valentines
            case (10, 31): return .halloween
            case let (11, d) where d == getThanksgivingDay(): return .thanksgiving
            case let (m, d) where isEaster(month: m, day: d): return .easter
            default: return nil
            }
        }()
        
        return HolidayTheme.getColor(for: holiday)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Image(systemName: "mug.fill")
                    .font(.system(size: 80))
                    .foregroundColor(cupColor)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        startShakeAnimation()
                    }

                Text("Brewpad")
                    .font(.largeTitle)
                    .bold()

                // Quip Text
                Text(action?.quip ?? currentQuip)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .opacity(quipOpacity)
                    .animation(.easeIn(duration: 0.5).delay(0.5), value: quipOpacity)
                    .onAppear {
                        quipOpacity = 1
                        if action == nil {
                            currentQuip = TimeGreeting.getQuip(username: settingsManager.username, settingsManager: settingsManager)
                        }
                        if isBirthday {
                            // Reveal confetti as the quip appears.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showConfetti = true
                            }
                        }
                    }
            }

            if isBirthday && showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
    
    private func startShakeAnimation() {
        rotationAngle = -10
        withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
            rotationAngle = 10
        }
    }
    
    // Helper function to calculate Thanksgiving (4th Thursday of November)
    private func getThanksgivingDay() -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())

        let startOfNovember = calendar.date(from: DateComponents(year: year, month: 11, day: 1))!
        let components = DateComponents(month: 11, weekday: 5, weekdayOrdinal: 4)

        guard let thanksgiving = calendar.nextDate(after: startOfNovember,
                                                   matching: components,
                                                   matchingPolicy: .nextTime,
                                                   direction: .forward) else {
            return 0
        }

        return calendar.component(.day, from: thanksgiving)
    }
    
    // Helper function to check if current date is Easter
    private func isEaster(month: Int, day: Int) -> Bool {
        let year = Calendar.current.component(.year, from: Date())
        let easterDates = [
            (2024, 3, 31),
            (2025, 4, 20),
            (2026, 4, 5),
            (2027, 3, 28)
        ]
        
        return easterDates.contains(where: { $0.0 == year && $0.1 == month && $0.2 == day })
    }
}

#Preview {
    SplashScreen()
        .environmentObject(SettingsManager())
} 