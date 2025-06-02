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
    
    @Published var isOver18: Bool {
        didSet {
            UserDefaults.standard.set(isOver18, forKey: "isOver18")
        }
    }
    
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
        self.isOver18 = UserDefaults.standard.bool(forKey: "isOver18")
        
        if let holidayString = UserDefaults.standard.string(forKey: "debugHoliday"),
           let savedHoliday = Holiday(rawValue: holidayString) {
            self.debugHoliday = savedHoliday
        } else {
            self.debugHoliday = .none
        }
    }
} 