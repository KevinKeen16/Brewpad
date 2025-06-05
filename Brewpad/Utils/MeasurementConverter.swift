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

    private static let metricKilogramRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*)kg\\b",
            options: []
        ) else {
            fatalError("Failed to compile kilogram regular expression")
        }
        return regex
    }()

    private static let metricVolumeRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*)\\s*ml'?s?\\b",
            options: [.caseInsensitive]
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

    private static let imperialPoundRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*) ?lbs?\\b",
            options: []
        ) else {
            fatalError("Failed to compile pound regular expression")
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

    // Range patterns (e.g., 10-15g)
    private static let metricRangeRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*)\\s*-\\s*([0-9]+\\.?[0-9]*)(g|kg|ml'?s?)\\b",
            options: [.caseInsensitive]
        ) else {
            fatalError("Failed to compile metric range regular expression")
        }
        return regex
    }()

    private static let imperialRangeRegex: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "([0-9]+\\.?[0-9]*)\\s*-\\s*([0-9]+\\.?[0-9]*)(oz|fl oz|lbs?)\\b",
            options: []
        ) else {
            fatalError("Failed to compile imperial range regular expression")
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
        // Weight: kilograms to pounds
        (
            metricKilogramRegex,
            { value in
                let pounds = value * 2.20462
                return String(format: "%.1f lb", pounds)
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
        // Weight: pounds to kilograms
        (
            imperialPoundRegex,
            { value in
                let kg = value / 2.20462
                return String(format: "%.1fkg", kg)
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
        // First handle ranges like "10-15g" so both numbers are converted
        result = convertRanges(result, toImperial: toImperial)
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

    private static func convertRanges(_ text: String, toImperial: Bool) -> String {
        var result = text
        let regex = toImperial ? metricRangeRegex : imperialRangeRegex
        let nsRange = NSRange(result.startIndex..<result.endIndex, in: result)
        let matches = regex.matches(in: result, options: [], range: nsRange)
        for match in matches.reversed() {
            guard let fullRange = Range(match.range, in: result),
                  let firstValueRange = Range(match.range(at: 1), in: result),
                  let secondValueRange = Range(match.range(at: 2), in: result),
                  let unitRange = Range(match.range(at: 3), in: result),
                  let firstValue = Double(result[firstValueRange]),
                  let secondValue = Double(result[secondValueRange]) else { continue }

            let unit = String(result[unitRange]).lowercased()
            var convertedUnit: String = unit
            var newFirst: String = String(firstValue)
            var newSecond: String = String(secondValue)

            if toImperial {
                switch unit {
                case "g":
                    newFirst = String(format: "%.1f", firstValue * 0.035274)
                    newSecond = String(format: "%.1f", secondValue * 0.035274)
                    convertedUnit = "oz"
                case "kg":
                    newFirst = String(format: "%.1f", firstValue * 2.20462)
                    newSecond = String(format: "%.1f", secondValue * 2.20462)
                    convertedUnit = "lb"
                case _ where unit.hasPrefix("ml"):
                    newFirst = String(format: "%.1f", firstValue * 0.033814)
                    newSecond = String(format: "%.1f", secondValue * 0.033814)
                    convertedUnit = "fl oz"
                default:
                    break
                }
            } else {
                switch unit {
                case "oz":
                    newFirst = String(format: "%.0f", firstValue / 0.035274)
                    newSecond = String(format: "%.0f", secondValue / 0.035274)
                    convertedUnit = "g"
                case _ where unit.hasPrefix("fl oz"):
                    newFirst = String(format: "%.0f", firstValue / 0.033814)
                    newSecond = String(format: "%.0f", secondValue / 0.033814)
                    convertedUnit = "ml"
                case "lb", "lbs":
                    newFirst = String(format: "%.1f", firstValue / 2.20462)
                    newSecond = String(format: "%.1f", secondValue / 2.20462)
                    convertedUnit = "kg"
                default:
                    break
                }
            }

            let replacement = "\(newFirst)-\(newSecond) \(convertedUnit)"
            result.replaceSubrange(fullRange, with: replacement)
        }
        return result
    }
}
