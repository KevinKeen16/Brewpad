import SwiftUI

struct HolidayTheme {
    static func getColor(for holiday: SettingsManager.Holiday?) -> Color {
        guard let holiday = holiday else { return .blue }
        
        switch holiday {
        case .none:
            return .blue
        case .newYearsEve, .newYearsDay:
            return .gold // Champagne gold color
        case .christmasEve, .christmasDay:
            return .red
        case .valentines:
            return .pink
        case .halloween:
            return .orange
        case .thanksgiving:
            return .brown
        case .easter:
            return .purple
        }
    }
}

extension Color {
    static let gold = Color(red: 1, green: 0.84, blue: 0)
    static let brown = Color(red: 0.6, green: 0.4, blue: 0.2)
    static let lightBlue = Color(red: 0.4, green: 0.7, blue: 1.0)
} 