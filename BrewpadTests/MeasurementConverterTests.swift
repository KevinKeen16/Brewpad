import Testing
@testable import Brewpad

struct MeasurementConverterTests {
    @Test
    func testGramsToOunces() async throws {
        let result = MeasurementConverter.convert("20g", toImperial: true)
        #expect(result.contains("0.7 oz"))
    }

    @Test
    func testMillilitersToFluidOunces() async throws {
        let result = MeasurementConverter.convert("120ml", toImperial: true)
        #expect(result.contains("4.1 fl oz"))
    }

    @Test
    func testCelsiusToFahrenheit() async throws {
        let result = MeasurementConverter.convert("93°C", toImperial: true)
        #expect(result.contains("199°F"))
    }

    @Test
    func testCentimetersToInches() async throws {
        let result = MeasurementConverter.convert("20cm", toImperial: true)
        #expect(result.contains("7.9 inches"))
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
