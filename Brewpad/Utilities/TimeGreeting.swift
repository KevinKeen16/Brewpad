import Foundation
import SwiftUI

struct TimeGreeting {
    private struct QuipsData: Codable {
        let early_morning: [String]
        let morning: [String]
        let midday: [String]
        let afternoon: [String]
        let evening: [String]
        let night: [String]
        let midnight: [String]
        let seasonal: SeasonalQuips
    }
    
    private struct SeasonalQuips: Codable {
        let new_years_eve: [String]
        let new_years_day: [String]
        let christmas_eve: [String]
        let christmas_day: [String]
        let valentines: [String]
        let halloween: [String]
        let thanksgiving: [String]
        let easter: [String]
        let birthday: [String]
    }
    
    private static var quips: QuipsData? = {
        guard let url = Bundle.main.url(forResource: "quips", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let quips = try? JSONDecoder().decode(QuipsData.self, from: data) else {
            return nil
        }
        return quips
    }()
    
    static func getQuip(username: String?, settingsManager: SettingsManager) -> String {
        let name = username ?? "coffee lover"
        
        // Check for special dates first
        if let seasonalQuip = checkSeasonalQuip(name: name, settingsManager: settingsManager) {
            return seasonalQuip
        }
        
        // Fall back to time-based quips
        return getTimeBasedQuip(name: name)
    }
    
    private static func checkSeasonalQuip(name: String, settingsManager: SettingsManager) -> String? {
        // If debug mode is enabled and a holiday is selected, use that
        if settingsManager.isDebugModeEnabled,
           settingsManager.debugHoliday != .none {
            guard let seasonal = quips?.seasonal else { return nil }
            
            let holidayQuips: [String]? = {
                switch settingsManager.debugHoliday {
                case .none: return nil
                case .newYearsEve: return seasonal.new_years_eve
                case .newYearsDay: return seasonal.new_years_day
                case .christmasEve: return seasonal.christmas_eve
                case .christmasDay: return seasonal.christmas_day
                case .valentines: return seasonal.valentines
                case .halloween: return seasonal.halloween
                case .thanksgiving: return seasonal.thanksgiving
                case .easter: return seasonal.easter
                }
            }()
            
            guard let quips = holidayQuips,
                  let quip = quips.randomElement() else {
                return nil
            }
            
            return quip.replacingOccurrences(of: "{name}", with: name)
        }

        // Birthday check
        if let birthday = settingsManager.birthdate {
            let calendar = Calendar.current
            let today = calendar.dateComponents([.month, .day], from: Date())
            let birthComponents = calendar.dateComponents([.month, .day], from: birthday)
            if today.month == birthComponents.month && today.day == birthComponents.day,
               let quip = quips?.seasonal.birthday.randomElement() {
                return quip.replacingOccurrences(of: "{name}", with: name)
            }
        }

        return checkActualSeasonalQuip(name: name)
    }
    
    // Move the original seasonal check logic to a separate function
    private static func checkActualSeasonalQuip(name: String) -> String? {
        let today = Calendar.current.dateComponents([.month, .day], from: Date())
        guard let month = today.month, let day = today.day else {
            return nil
        }
        
        let seasonalQuips: [String]? = {
            guard let seasonal = quips?.seasonal else { return nil }
            
            switch (month, day) {
            case (12, 24): return seasonal.christmas_eve
            case (12, 25): return seasonal.christmas_day
            case (12, 31): return seasonal.new_years_eve
            case (1, 1): return seasonal.new_years_day
            case (2, 14): return seasonal.valentines
            case (10, 31): return seasonal.halloween
            case let (11, d) where d == getThanksgivingDay(): return seasonal.thanksgiving
            case let (m, d) where isEaster(month: m, day: d): return seasonal.easter
            default: return nil
            }
        }()
        
        guard let quips = seasonalQuips,
              let quip = quips.randomElement() else {
            return nil
        }
        
        return quip.replacingOccurrences(of: "{name}", with: name)
    }
    
    private static func getTimeBasedQuip(name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        let timeQuips: [String]? = {
            guard let quips = quips else { return nil }
            
            switch hour {
            case 5..<8: return quips.early_morning
            case 8..<11: return quips.morning
            case 11..<14: return quips.midday
            case 14..<17: return quips.afternoon
            case 17..<20: return quips.evening
            case 20..<23: return quips.night
            default: return quips.midnight
            }
        }()
        
        guard let quips = timeQuips,
              let quip = quips.randomElement() else {
            return "Time for coffee, \(name)!"
        }
        
        return quip.replacingOccurrences(of: "{name}", with: name)
    }
    
    // Helper function to calculate Thanksgiving (4th Thursday of November)
    private static func getThanksgivingDay() -> Int {
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
    private static func isEaster(month: Int, day: Int) -> Bool {
        // Note: This is a simplified check. For a complete Easter calculation,
        // you might want to implement the full algorithm or use a date library
        let year = Calendar.current.component(.year, from: Date())
        // You could store Easter dates for the next few years or implement the calculation
        let easterDates = [
            // Add known Easter dates for the next few years
            (2024, 3, 31),
            (2025, 4, 20),
            (2026, 4, 5),
            (2027, 3, 28)
        ]
        
        return easterDates.contains(where: { $0.0 == year && $0.1 == month && $0.2 == day })
    }
} 