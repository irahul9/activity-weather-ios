import Foundation

struct DailyForecast: Sendable {
    let days: [ForecastDay]
}

struct ForecastDay: Identifiable, Sendable {
    let id: String
    let date: Date
    let temperatureMaxC: Double
    let temperatureMinC: Double
    let precipitationSumMm: Double
    let snowfallSumCm: Double
    let windSpeedMaxKmh: Double
    let weatherCode: Int
    let cloudCoverMeanPercent: Double

    var averageTemperatureC: Double {
        (temperatureMaxC + temperatureMinC) / 2
    }
}

struct ForecastAPIResponse: Decodable, Sendable {
    let daily: DailyPayload
}

struct DailyPayload: Decodable, Sendable {
    let time: [String]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationSum: [Double]
    let snowfallSum: [Double]
    let windSpeed10mMax: [Double]
    let weatherCode: [Int]
    let cloudCoverMean: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationSum = "precipitation_sum"
        case snowfallSum = "snowfall_sum"
        case windSpeed10mMax = "wind_speed_10m_max"
        case weatherCode = "weather_code"
        case cloudCoverMean = "cloud_cover_mean"
    }

    func asForecast(calendar: Calendar = .current) throws -> DailyForecast {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        var days: [ForecastDay] = []
        days.reserveCapacity(time.count)

        for index in time.indices {
            guard let date = formatter.date(from: time[index]) else {
                throw OpenMeteoError.decodingFailure
            }
            days.append(
                ForecastDay(
                    id: time[index],
                    date: date,
                    temperatureMaxC: temperature2mMax[index],
                    temperatureMinC: temperature2mMin[index],
                    precipitationSumMm: precipitationSum[index],
                    snowfallSumCm: snowfallSum[index],
                    windSpeedMaxKmh: windSpeed10mMax[index],
                    weatherCode: weatherCode[index],
                    cloudCoverMeanPercent: cloudCoverMean[index]
                )
            )
        }

        return DailyForecast(days: days)
    }
}
