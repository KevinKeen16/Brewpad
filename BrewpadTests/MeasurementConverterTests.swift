import Testing
@testable import Brewpad

struct MeasurementConverterTests {
    @Test
    func testGramsToOunces() async throws {
        let result = MeasurementConverter.convert("20g", toImperial: true)
        #expect(result.contains("0.7 oz"))
    }

    @Test
    func testOuncesToGrams() async throws {
        let result = MeasurementConverter.convert("0.7 oz", toImperial: false)
        #expect(result.contains("20g"))
    }

    @Test
    func testMillilitersToFluidOunces() async throws {
        let result = MeasurementConverter.convert("120ml", toImperial: true)
        #expect(result.contains("4.1 fl oz"))
    }

    @Test
    func testPluralMillilitersToFluidOunces() async throws {
        let result = MeasurementConverter.convert("120mls", toImperial: true)
        #expect(result.contains("4.1 fl oz"))
    }

    @Test
    func testApostropheMillilitersToFluidOunces() async throws {
        let result = MeasurementConverter.convert("120ml's", toImperial: true)
        #expect(result.contains("4.1 fl oz"))
    }

    @Test
    func testFluidOuncesToMilliliters() async throws {
        let result = MeasurementConverter.convert("4 fl oz", toImperial: false)
        #expect(result.contains("118ml"))
    }

    @Test
    func testCelsiusToFahrenheit() async throws {
        let result = MeasurementConverter.convert("93°C", toImperial: true)
        #expect(result.contains("199°F"))
    }

    @Test
    func testFahrenheitToCelsius() async throws {
        let result = MeasurementConverter.convert("199°F", toImperial: false)
        #expect(result.contains("93°C"))
    }

    @Test
    func testCentimetersToInches() async throws {
        let result = MeasurementConverter.convert("20cm", toImperial: true)
        #expect(result.contains("7.9 inches"))
    }

    @Test
    func testInchesToCentimeters() async throws {
        let result = MeasurementConverter.convert("7.9 inches", toImperial: false)
        #expect(result.contains("20.0cm"))
    }

    @Test
    func testMultipleOccurrences() async throws {
        let result = MeasurementConverter.convert("Add 20g sugar and 20g flour", toImperial: true)
        #expect(result.contains("Add 0.7 oz sugar and 0.7 oz flour"))
    }

    @Test
    func testMixedUnitsInSentence() async throws {
        let result = MeasurementConverter.convert("Heat 200ml water to 93°C", toImperial: true)
        #expect(result.contains("6.8 fl oz"))
        #expect(result.contains("199°F"))
    }
}
