import Testing
import SwiftUI
@testable import Brewpad

struct HolidayThemeTests {
    @Test
    func testValentinesColor() async throws {
        let color = HolidayTheme.getColor(for: .valentines)
        #expect(color == .pink)
    }

    @Test
    func testChristmasColor() async throws {
        let color = HolidayTheme.getColor(for: .christmasDay)
        #expect(color == .red)
    }

    @Test
    func testHalloweenColor() async throws {
        let color = HolidayTheme.getColor(for: .halloween)
        #expect(color == .orange)
    }

    @Test
    func testThanksgivingColor() async throws {
        let color = HolidayTheme.getColor(for: .thanksgiving)
        #expect(color == .brown)
    }

    @Test
    func testEasterColor() async throws {
        let color = HolidayTheme.getColor(for: .easter)
        #expect(color == .purple)
    }
}
