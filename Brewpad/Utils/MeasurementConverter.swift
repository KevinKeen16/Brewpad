import Foundation

struct MeasurementConverter {
    static func convert(_ text: String, toImperial: Bool) -> String {
        // Match patterns like "22.5g", "120ml", "93°C", "1cm"
        let patterns: [(String, String, (Double) -> String)] = [
            // Weight: grams
            ("([0-9]+\\.?[0-9]*)g\\b", "g", { value in
                let oz = value * 0.035274
                return String(format: "%.1f oz", oz)
            }),
            // Volume: milliliters
            ("([0-9]+\\.?[0-9]*)ml\\b", "ml", { value in
                let flOz = value * 0.033814
                return String(format: "%.1f fl oz", flOz)
            }),
            // Temperature: Celsius
            ("([0-9]+\\.?[0-9]*)°C\\b", "°C", { value in
                let fahrenheit = (value * 9/5) + 32
                return String(format: "%.0f°F", fahrenheit)
            }),
            // Length: centimeters
            ("([0-9]+\\.?[0-9]*)cm\\b", "cm", { value in
                let inches = value * 0.393701
                return String(format: "%.1f inches", inches)
            })
        ]
        
        var result = text
        
        if toImperial {
            for (pattern, unit, converter) in patterns {
                let regex = try? NSRegularExpression(pattern: pattern, options: [])
                let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
                
                // Find all matches and process them in reverse order
                let matches = regex?.matches(in: text, options: [], range: nsRange) ?? []
                for match in matches.reversed() {
                    if let range = Range(match.range(at: 1), in: text),
                       let value = Double(text[range]) {
                        let convertedValue = converter(value)
                        // Use the original unit to replace the correct measurement
                        result = result.replacingOccurrences(of: text[range] + unit, with: convertedValue)
                    }
                }
            }
        }
        
        return result
    }
} 