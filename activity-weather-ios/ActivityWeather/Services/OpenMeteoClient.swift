import Foundation

protocol OpenMeteoClientProtocol: Sendable {
    func searchLocations(query: String) async throws -> [GeoLocation]
    func fetchForecast(for location: GeoLocation) async throws -> DailyForecast
}

struct OpenMeteoClient: OpenMeteoClientProtocol {
    private let session: URLSession
    private let geocodingBase = URL(string: "https://geocoding-api.open-meteo.com/v1/search")!
    private let forecastBase = URL(string: "https://api.open-meteo.com/v1/forecast")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchLocations(query: String) async throws -> [GeoLocation] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        var components = URLComponents(url: geocodingBase, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: "8"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = components?.url else { throw OpenMeteoError.invalidURL }

        let data = try await fetchData(from: url)
        let response = try JSONDecoder().decode(GeocodingSearchResponse.self, from: data)
        guard let results = response.results, !results.isEmpty else {
            throw OpenMeteoError.emptyResults
        }
        return results.map { $0.asLocation() }
    }

    func fetchForecast(for location: GeoLocation) async throws -> DailyForecast {
        var components = URLComponents(url: forecastBase, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "timezone", value: location.timezone),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(
                name: "daily",
                value: [
                    "temperature_2m_max",
                    "temperature_2m_min",
                    "precipitation_sum",
                    "snowfall_sum",
                    "wind_speed_10m_max",
                    "weather_code",
                    "cloud_cover_mean"
                ].joined(separator: ",")
            )
        ]
        guard let url = components?.url else { throw OpenMeteoError.invalidURL }

        let data = try await fetchData(from: url)
        let response = try JSONDecoder().decode(ForecastAPIResponse.self, from: data)
        return try response.daily.asForecast()
    }

    private func fetchData(from url: URL) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw OpenMeteoError.decodingFailure
            }
            guard (200..<300).contains(http.statusCode) else {
                throw OpenMeteoError.httpFailure(statusCode: http.statusCode)
            }
            return data
        } catch let error as OpenMeteoError {
            throw error
        } catch URLError.notConnectedToInternet {
            throw OpenMeteoError.offline
        } catch {
            throw error
        }
    }
}
