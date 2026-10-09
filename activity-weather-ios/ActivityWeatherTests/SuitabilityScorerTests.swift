import XCTest
@testable import ActivityWeather

final class SuitabilityScorerTests: XCTestCase {
    private let scorer = SuitabilityScorer()

    func testColdSnowyDayRanksHighForSkiing() {
        let day = ForecastDay(
            id: "2026-01-10",
            date: makeDate("2026-01-10"),
            temperatureMaxC: -2,
            temperatureMinC: -8,
            precipitationSumMm: 2,
            snowfallSumCm: 12,
            windSpeedMaxKmh: 20,
            weatherCode: 71,
            cloudCoverMeanPercent: 80
        )

        let result = scorer.score(day: day, activity: .skiing)
        XCTAssertGreaterThan(result.score, 75)
    }

    func testWarmRainyDayRanksLowForSkiing() {
        let day = ForecastDay(
            id: "2026-04-10",
            date: makeDate("2026-04-10"),
            temperatureMaxC: 14,
            temperatureMinC: 9,
            precipitationSumMm: 12,
            snowfallSumCm: 0,
            windSpeedMaxKmh: 25,
            weatherCode: 63,
            cloudCoverMeanPercent: 95
        )

        let result = scorer.score(day: day, activity: .skiing)
        XCTAssertLessThan(result.score, 40)
    }

    func testIndoorInverseOfOutdoorOnRainyDay() {
        let rainy = ForecastDay(
            id: "2026-03-01",
            date: makeDate("2026-03-01"),
            temperatureMaxC: 8,
            temperatureMinC: 4,
            precipitationSumMm: 14,
            snowfallSumCm: 0,
            windSpeedMaxKmh: 30,
            weatherCode: 63,
            cloudCoverMeanPercent: 100
        )

        let outdoor = scorer.score(day: rainy, activity: .outdoorSightseeing).score
        let indoor = scorer.score(day: rainy, activity: .indoorSightseeing).score
        XCTAssertGreaterThan(indoor, outdoor)
    }

    func testRankingsProduceSevenUniqueRanksPerActivity() {
        let forecast = DailyForecast(days: sampleWeek())
        let rankings = scorer.rankings(for: forecast)

        XCTAssertEqual(rankings.count, ActivityType.allCases.count)
        for ranking in rankings {
            XCTAssertEqual(ranking.rankedDays.count, 7)
            XCTAssertEqual(Set(ranking.rankedDays.map(\.rank)), Set(1...7))
        }
    }

    private func sampleWeek() -> [ForecastDay] {
        let isoDates = [
            "2026-05-10", "2026-05-11", "2026-05-12", "2026-05-13",
            "2026-05-14", "2026-05-15", "2026-05-16"
        ]
        return isoDates.enumerated().map { offset, iso in
            ForecastDay(
                id: iso,
                date: makeDate(iso),
                temperatureMaxC: Double(10 + offset),
                temperatureMinC: Double(5 + offset),
                precipitationSumMm: Double(offset),
                snowfallSumCm: 0,
                windSpeedMaxKmh: Double(10 + offset * 2),
                weatherCode: 3,
                cloudCoverMeanPercent: 50
            )
        }
    }

    private func makeDate(_ iso: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: iso)!
    }
}
