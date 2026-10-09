import Foundation

struct GeoLocation: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let admin1: String?
    let country: String
    let latitude: Double
    let longitude: Double
    let timezone: String

    var displayName: String {
        if let admin1, !admin1.isEmpty {
            return "\(name), \(admin1), \(country)"
        }
        return "\(name), \(country)"
    }
}

struct GeocodingSearchResponse: Decodable, Sendable {
    let results: [GeocodingResult]?
}

struct GeocodingResult: Decodable, Sendable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let timezone: String
    let country: String
    let admin1: String?

    func asLocation() -> GeoLocation {
        GeoLocation(
            id: id,
            name: name,
            admin1: admin1,
            country: country,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone
        )
    }
}
