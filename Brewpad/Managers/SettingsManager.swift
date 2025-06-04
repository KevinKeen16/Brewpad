import SwiftUI

class SettingsManager: ObservableObject {
    @Published var useMetricUnits: Bool {
        didSet {
            UserDefaults.standard.set(useMetricUnits, forKey: "useMetricUnits")
        }
    }
    
    @Published var username: String? {
        didSet {
            UserDefaults.standard.set(username, forKey: "username")
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var isReplayingTutorial: Bool = false
    
    // Debug Settings
    @Published var isDebugModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDebugModeEnabled, forKey: "isDebugModeEnabled")
        }
    }
    
    @Published var debugHoliday: Holiday {
        didSet {
            UserDefaults.standard.set(debugHoliday.rawValue, forKey: "debugHoliday")
        }
    }
    
    // Birthdate is used for age verification
    @Published var birthdate: Date? {
        didSet {
            UserDefaults.standard.set(birthdate, forKey: "birthdate")
            isOver18 = calculateIsOver18(from: birthdate)
        }
    }

    @Published private(set) var isOver18: Bool = false
    
    enum Holiday: String, CaseIterable {
        case none = "None"
        case newYearsEve = "New Year's Eve"
        case newYearsDay = "New Year's Day"
        case christmasEve = "Christmas Eve"
        case christmasDay = "Christmas Day"
        case valentines = "Valentine's Day"
        case halloween = "Halloween"
        case thanksgiving = "Thanksgiving"
        case easter = "Easter"
    }
    
    enum Theme: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    
    @Published var theme: Theme = .system {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "theme")
        }
    }
    
    init() {
        if let themeString = UserDefaults.standard.string(forKey: "theme"),
           let savedTheme = Theme(rawValue: themeString) {
            self.theme = savedTheme
        }
        
        self.useMetricUnits = UserDefaults.standard.bool(forKey: "useMetricUnits")
        self.username = UserDefaults.standard.string(forKey: "username")
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.isDebugModeEnabled = UserDefaults.standard.bool(forKey: "isDebugModeEnabled")

        if let savedDate = UserDefaults.standard.object(forKey: "birthdate") as? Date {
            self.birthdate = savedDate
            self.isOver18 = calculateIsOver18(from: savedDate)
        } else {
            self.birthdate = nil
            // Support older versions that stored the boolean directly
            self.isOver18 = UserDefaults.standard.bool(forKey: "isOver18")
        }
        
        if let holidayString = UserDefaults.standard.string(forKey: "debugHoliday"),
           let savedHoliday = Holiday(rawValue: holidayString) {
            self.debugHoliday = savedHoliday
        } else {
            self.debugHoliday = .none
        }
    }

    private func calculateIsOver18(from date: Date?) -> Bool {
        guard let date else { return false }
        if let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year {
            return years >= 18
        }
        return false
    }
}
