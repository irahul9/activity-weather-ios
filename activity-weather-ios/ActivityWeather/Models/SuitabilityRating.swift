import Foundation

struct ActivityDayScore: Identifiable, Sendable {
    let activity: ActivityType
    let day: ForecastDay
    let score: Int
    let rank: Int
    let summary: String

    var id: String { "\(activity.rawValue)-\(day.id)" }
}

struct ActivityRanking: Sendable {
    let activity: ActivityType
    let rankedDays: [ActivityDayScore]
}

enum SuitabilityBand: Sendable {
    case excellent
    case good
    case fair
    case poor

    init(score: Int) {
        switch score {
        case 80...: self = .excellent
        case 60..<80: self = .good
        case 40..<60: self = .fair
        default: self = .poor
        }
    }

    var label: String {
        switch self {
        case .excellent: "Excellent"
        case .good: "Good"
        case .fair: "Fair"
        case .poor: "Poor"
        }
    }
}
