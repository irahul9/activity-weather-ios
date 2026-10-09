import Foundation
import Observation

@MainActor
@Observable
final class WeatherSearchViewModel {
    var searchText = ""
    var suggestions: [GeoLocation] = []
    var selectedLocation: GeoLocation?
    var forecast: DailyForecast?
    var rankings: [ActivityRanking] = []
    var selectedActivity: ActivityType = .outdoorSightseeing

    var isSearching = false
    var isLoadingForecast = false
    var errorMessage: String?

    private let client: OpenMeteoClientProtocol
    private let scorer: SuitabilityScorer
    private var searchTask: Task<Void, Never>?

    init(
        client: OpenMeteoClientProtocol = OpenMeteoClient(),
        scorer: SuitabilityScorer = SuitabilityScorer()
    ) {
        self.client = client
        self.scorer = scorer
    }

    func onSearchTextChanged() {
        searchTask?.cancel()
        errorMessage = nil

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            suggestions = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            isSearching = true
            defer { isSearching = false }

            do {
                suggestions = try await client.searchLocations(query: query)
            } catch is OpenMeteoError {
                suggestions = []
            } catch {
                suggestions = []
            }
        }
    }

    func select(_ location: GeoLocation) {
        selectedLocation = location
        searchText = location.displayName
        suggestions = []
        Task { await loadForecast(for: location) }
    }

    func loadForecast(for location: GeoLocation) async {
        isLoadingForecast = true
        errorMessage = nil
        forecast = nil
        rankings = []

        defer { isLoadingForecast = false }

        do {
            let forecast = try await client.fetchForecast(for: location)
            self.forecast = forecast
            self.rankings = scorer.rankings(for: forecast)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func ranking(for activity: ActivityType) -> ActivityRanking? {
        rankings.first { $0.activity == activity }
    }
}
