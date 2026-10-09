import Foundation

enum WMOWeatherCode {
    /// Returns true for thunderstorm, freezing rain, or heavy precipitation codes.
    static func isSevere(_ code: Int) -> Bool {
        (95...99).contains(code) || code == 67 || code == 77
    }

    static func isRainy(_ code: Int) -> Bool {
        (51...67).contains(code) || (80...82).contains(code)
    }

    static func isSnowy(_ code: Int) -> Bool {
        (71...77).contains(code) || (85...86).contains(code)
    }

    static func shortDescription(for code: Int) -> String {
        switch code {
        case 0: "Clear"
        case 1, 2, 3: "Partly cloudy"
        case 45, 48: "Fog"
        case 51, 53, 55: "Drizzle"
        case 56, 57: "Freezing drizzle"
        case 61, 63, 65: "Rain"
        case 66, 67: "Freezing rain"
        case 71, 73, 75: "Snow"
        case 77: "Snow grains"
        case 80, 81, 82: "Rain showers"
        case 85, 86: "Snow showers"
        case 95: "Thunderstorm"
        case 96, 99: "Thunderstorm with hail"
        default: "Mixed conditions"
        }
    }
}
