# Activity Weather (iOS)

Native SwiftUI app for a senior mobile take-home: search a city or town, fetch a 7-day forecast from [Open-Meteo](https://open-meteo.com/), and **rank each day** for:

- Skiing
- Surfing
- Outdoor sightseeing
- Indoor sightseeing

Reasoning, assumptions, and trade-offs: [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Requirements

- Xcode 15+ (project targets **iOS 17**)
- Internet for geocoding and forecast APIs

## Run

1. Open `ActivityWeather.xcodeproj` in Xcode.
2. Select the **ActivityWeather** scheme and an iPhone simulator.
3. **Run** (⌘R).

Or from the command line:

```bash
xcodebuild -scheme ActivityWeather -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' build
```

## Tests

```bash
xcodebuild -scheme ActivityWeather -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' test
```

Unit tests focus on `SuitabilityScorer` heuristics (no network).

## APIs

- Geocoding: `https://geocoding-api.open-meteo.com/v1/search`
- Forecast: `https://api.open-meteo.com/v1/forecast` (7 daily variables: temps, precipitation, snowfall, wind, weather code, cloud cover)

## Key assumptions (short)

- **Surfing** uses wind speed as a proxy; pick a coastal location when testing surf rankings.
- **Indoor sightseeing** favors days that are poor for outdoor sightseeing.
- Suitability is **explainable heuristics**, not ground-truth recreation forecasts.

See `docs/DECISIONS.md` for the full list.

## Project layout

```
ActivityWeather/          App target (SwiftUI, MVVM-ish)
ActivityWeatherTests/     Scorer unit tests
docs/DECISIONS.md         How I worked / trade-offs
project.yml               XcodeGen spec (regenerate with XcodeGen if needed)
```

Regenerate the Xcode project after editing `project.yml`:

```bash
xcodegen generate
```
