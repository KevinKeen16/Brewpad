import Foundation

struct MeasurementConverter {
    // MARK: - Regular Expressions
    private static let metricWeightRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*)g\\b",
            options: []
        ) else {
            fatalError("Failed to compile weight regular expression")
        }
        return regex
    }()

    private static let metricVolumeRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*)ml\\b",
            options: []
        ) else {
            fatalError("Failed to compile volume regular expression")
        }
        return regex
    }()

    private static let metricTemperatureRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*)°C\\b",
            options: []
        ) else {
            fatalError("Failed to compile temperature regular expression")
        }
        return regex
    }()

    private static let metricLengthRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*)cm\\b",
            options: []
        ) else {
            fatalError("Failed to compile length regular expression")
        }
        return regex
    }()

    private static let imperialWeightRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*) ?oz\\b",
            options: []
        ) else {
            fatalError("Failed to compile imperial weight regular expression")
        }
        return regex
    }()

    private static let imperialVolumeRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*) ?fl oz\\b",
            options: []
        ) else {
            fatalError("Failed to compile imperial volume regular expression")
        }
        return regex
    }()

    private static let imperialTemperatureRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*)°F\\b",
            options: []
        ) else {
            fatalError("Failed to compile imperial temperature regular expression")
        }
        return regex
    }()

    private static let imperialLengthRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*) ?inches?\\b",
            options: []
        ) else {
            fatalError("Failed to compile imperial length regular expression")
        }
        return regex
    }()

    // MARK: - Conversion Patterns
    private static let metricToImperial: [(NSRegularExpression, (Double) -> String)] = [
        // Weight: grams to ounces
        (
            metricWeightRegex,
            { value in
                let oz = value * 0.035274
                return String(format: "%.1f oz", oz)
            }
        ),
        // Volume: milliliters to fluid ounces
        (
            metricVolumeRegex,
            { value in
                let flOz = value * 0.033814
                return String(format: "%.1f fl oz", flOz)
            }
        ),
        // Temperature: Celsius to Fahrenheit
        (
            metricTemperatureRegex,
            { value in
                let fahrenheit = (value * 9/5) + 32
                return String(format: "%.0f°F", fahrenheit)
            }
        ),
        // Length: centimeters to inches
        (
            metricLengthRegex,
            { value in
                let inches = value * 0.393701
                return String(format: "%.1f inches", inches)
            }
        )
    ]

    private static let imperialToMetric: [(NSRegularExpression, (Double) -> String)] = [
        // Weight: ounces to grams
        (
            imperialWeightRegex,
            { value in
                let grams = value / 0.035274
                return String(format: "%.0fg", grams)
            }
        ),
        // Volume: fluid ounces to milliliters
        (
            imperialVolumeRegex,
            { value in
                let ml = value / 0.033814
                return String(format: "%.0fml", ml)
            }
        ),
        // Temperature: Fahrenheit to Celsius
        (
            imperialTemperatureRegex,
            { value in
                let celsius = (value - 32) * 5/9
                return String(format: "%.0f°C", celsius)
            }
        ),
        // Length: inches to centimeters
        (
            imperialLengthRegex,
            { value in
                let cm = value / 0.393701
                return String(format: "%.1fcm", cm)
            }
        )
    ]

    // MARK: - Public API
    static func convert(_ text: String, toImperial: Bool) -> String {
        var result = text
        let patterns = toImperial ? metricToImperial : imperialToMetric
        for (regex, converter) in patterns {
            let nsRange = NSRange(result.startIndex..<result.endIndex, in: result)
            // Find all matches and process them in reverse order
            let matches = regex.matches(in: result, options: [], range: nsRange)
            for match in matches.reversed() {
                if let fullRange = Range(match.range, in: result),
                   let valueRange = Range(match.range(at: 1), in: result),
                   let value = Double(result[valueRange]) {
                    let convertedValue = converter(value)
                    result.replaceSubrange(fullRange, with: convertedValue)
                }
            }
        }
        return result
    }
}
