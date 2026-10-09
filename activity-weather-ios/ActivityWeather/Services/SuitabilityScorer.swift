import Foundation

/// Pure scoring engine: easy to unit test and tweak without touching UI or networking.
struct SuitabilityScorer: Sendable {
    func rankings(for forecast: DailyForecast) -> [ActivityRanking] {
        ActivityType.allCases.map { activity in
            let scored = forecast.days.map { day in
                let result = score(day: day, activity: activity)
                return ActivityDayScore(
                    activity: activity,
                    day: day,
                    score: result.score,
                    rank: 0,
                    summary: result.summary
                )
            }
            let sorted = scored.sorted {
                if $0.score == $1.score { return $0.day.date < $1.day.date }
                return $0.score > $1.score
            }
            let ranked = sorted.enumerated().map { index, item in
                ActivityDayScore(
                    activity: item.activity,
                    day: item.day,
                    score: item.score,
                    rank: index + 1,
                    summary: item.summary
                )
            }
            return ActivityRanking(activity: activity, rankedDays: ranked)
        }
    }

    func score(day: ForecastDay, activity: ActivityType) -> (score: Int, summary: String) {
        let raw: Double
        let summary: String
        switch activity {
        case .skiing:
            (raw, summary) = skiingScore(day)
        case .surfing:
            (raw, summary) = surfingScore(day)
        case .outdoorSightseeing:
            (raw, summary) = outdoorSightseeingScore(day)
        case .indoorSightseeing:
            (raw, summary) = indoorSightseeingScore(day)
        }
        return (Int(raw.rounded().clamped(to: 0...100)), summary)
    }

    // MARK: - Activity heuristics (documented in docs/DECISIONS.md)

    private func skiingScore(_ day: ForecastDay) -> (Double, String) {
        var score = 0.0
        var notes: [String] = []

        let maxT = day.temperatureMaxC
        let minT = day.temperatureMinC

        if maxT <= 3 {
            score += 35
            notes.append("cold enough")
        } else if maxT <= 6 {
            score += 18
            notes.append("marginal temps")
        } else {
            score -= 20
            notes.append("too warm")
        }

        if minT <= 0 {
            score += 20
        } else {
            score -= 10
            notes.append("no freeze")
        }

        if day.snowfallSumCm >= 5 {
            score += 30
            notes.append("fresh snow")
        } else if day.snowfallSumCm > 0 {
            score += 18
            notes.append("some snow")
        } else if maxT <= 1 {
            score += 8
            notes.append("dry cold")
        }

        if WMOWeatherCode.isRainy(day.weatherCode) && maxT > 2 {
            score -= 25
            notes.append("rain")
        }

        if day.precipitationSumMm > 8 {
            score -= 12
        }

        if day.windSpeedMaxKmh > 45 {
            score -= 15
            notes.append("strong wind")
        }

        if WMOWeatherCode.isSevere(day.weatherCode) {
            score -= 30
            notes.append("storms")
        }

        let summary = notes.isEmpty ? WMOWeatherCode.shortDescription(for: day.weatherCode) : notes.joined(separator: ", ")
        return (score, summary)
    }

    private func surfingScore(_ day: ForecastDay) -> (Double, String) {
        // Open-Meteo forecast has no wave height; wind is a coarse proxy (see DECISIONS.md).
        var score = 25.0
        var notes: [String] = []

        let wind = day.windSpeedMaxKmh
        if (18...35).contains(wind) {
            score += 35
            notes.append("wind in surf range")
        } else if (12...45).contains(wind) {
            score += 18
        } else if wind < 8 {
            score -= 15
            notes.append("flat wind")
        } else {
            score -= 10
            notes.append("very windy")
        }

        let temp = day.averageTemperatureC
        if (14...28).contains(temp) {
            score += 20
        } else if temp < 10 {
            score -= 15
            notes.append("cold water air")
        } else if temp > 32 {
            score -= 8
        }

        if day.precipitationSumMm > 5 || WMOWeatherCode.isRainy(day.weatherCode) {
            score -= 18
            notes.append("wet")
        }

        if WMOWeatherCode.isSevere(day.weatherCode) {
            score -= 35
            notes.append("unsafe storms")
        }

        let summary = notes.isEmpty ? "Wind \(Int(wind)) km/h" : notes.joined(separator: ", ")
        return (score, summary)
    }

    private func outdoorSightseeingScore(_ day: ForecastDay) -> (Double, String) {
        var score = 55.0
        var notes: [String] = []

        let temp = day.averageTemperatureC
        if (12...26).contains(temp) {
            score += 22
            notes.append("comfortable")
        } else if temp < 2 || temp > 32 {
            score -= 22
            notes.append("extreme temps")
        } else {
            score += 8
        }

        if day.precipitationSumMm <= 1 {
            score += 18
        } else if day.precipitationSumMm <= 4 {
            score += 5
        } else {
            score -= min(25, day.precipitationSumMm * 2)
            notes.append("rainy")
        }

        if day.cloudCoverMeanPercent < 70 {
            score += 10
        } else if day.cloudCoverMeanPercent > 90 {
            score -= 8
            notes.append("overcast")
        }

        if day.windSpeedMaxKmh > 40 {
            score -= 12
            notes.append("windy")
        }

        if WMOWeatherCode.isSevere(day.weatherCode) {
            score -= 30
            notes.append("storms")
        }

        let summary = notes.isEmpty ? WMOWeatherCode.shortDescription(for: day.weatherCode) : notes.joined(separator: ", ")
        return (score, summary)
    }

    private func indoorSightseeingScore(_ day: ForecastDay) -> (Double, String) {
        // Best indoor days = unpleasant outdoor days (museums as fallback).
        let outdoor = outdoorSightseeingScore(day).0
        var score = 100 - outdoor + 15

        var notes: [String] = []
        if day.precipitationSumMm >= 6 {
            notes.append("rainy — good museum day")
        }
        if day.averageTemperatureC < 5 || day.averageTemperatureC > 30 {
            notes.append("harsh outside")
        }
        if WMOWeatherCode.isSevere(day.weatherCode) {
            notes.append("stay inside")
        }

        if notes.isEmpty, score < 55 {
            notes.append("pleasant outdoors — indoor optional")
        }

        let summary = notes.isEmpty ? "Balanced day" : notes.joined(separator: ", ")
        return (score, summary)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
