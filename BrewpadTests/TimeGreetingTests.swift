import Testing
@testable import Brewpad

struct TimeGreetingTests {
    @Test
    func testDebugHolidayQuipsChange() async throws {
        let settings = SettingsManager()
        settings.isDebugModeEnabled = true
        settings.debugHoliday = .christmasDay
        let quipChristmas = TimeGreeting.getQuip(username: "Alice", settingsManager: settings)

        settings.debugHoliday = .halloween
        let quipHalloween = TimeGreeting.getQuip(username: "Alice", settingsManager: settings)

        #expect(quipChristmas.contains("Alice"))
        #expect(quipHalloween.contains("Alice"))
        #expect(quipChristmas != quipHalloween)
    }

    @Test
    func testTimeBasedQuip() async throws {
        let settings = SettingsManager()
        settings.isDebugModeEnabled = false
        let quip = TimeGreeting.getQuip(username: "Alice", settingsManager: settings)
        #expect(!quip.isEmpty)
    }

    @Test
    func testBirthdayQuip() async throws {
        let settings = SettingsManager()
        settings.birthdate = Date()
        let quip = TimeGreeting.getQuip(username: "Alice", settingsManager: settings)
        #expect(quip.contains("Alice"))
    }
}
