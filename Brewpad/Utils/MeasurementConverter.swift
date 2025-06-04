import Foundation

struct MeasurementConverter {
    private static let weightRegex = try! NSRegularExpression(
        pattern: "([0-9]+\\.?[0-9]*)g\\b",
        options: []
    )
    private static let volumeRegex = try! NSRegularExpression(
        pattern: "([0-9]+\\.?[0-9]*)ml\\b",
        options: []
    )
    private static let temperatureRegex = try! NSRegularExpression(
        pattern: "([0-9]+\\.?[0-9]*)°C\\b",
        options: []
    )
    private static let lengthRegex = try! NSRegularExpression(
        pattern: "([0-9]+\\.?[0-9]*)cm\\b",
        options: []
    )

    private static let patterns: [(NSRegularExpression, (Double) -> String)] = [
        // Weight: grams
        (
            weightRegex,
            { value in
                let oz = value * 0.035274
                return String(format: "%.1f oz", oz)
            }
        ),
        // Volume: milliliters
        (
            volumeRegex,
            { value in
                let flOz = value * 0.033814
                return String(format: "%.1f fl oz", flOz)
            }
        ),
        // Temperature: Celsius
        (
            temperatureRegex,
            { value in
                let fahrenheit = (value * 9/5) + 32
                return String(format: "%.0f°F", fahrenheit)
            }
        ),
        // Length: centimeters
        (
            lengthRegex,
            { value in
                let inches = value * 0.393701
                return String(format: "%.1f inches", inches)
            }
        )
    ]

    static func convert(_ text: String, toImperial: Bool) -> String {
        
        var result = text
        
        if toImperial {
            for (regex, converter) in patterns {
                let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)

                // Find all matches and process them in reverse order
                let matches = regex.matches(in: text, options: [], range: nsRange)
                for match in matches.reversed() {
                    if let fullRange = Range(match.range, in: result),
                       let valueRange = Range(match.range(at: 1), in: result),
                       let value = Double(result[valueRange]) {
                        let convertedValue = converter(value)
                        result.replaceSubrange(fullRange, with: convertedValue)
                    }
                }
            }
        }
        
        return result
    }
} 