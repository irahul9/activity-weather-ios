# How I worked — planning & trade-offs

This file is intentionally rough: it mirrors what I'd leave in a PR description or design doc before polishing README copy.

## Problem framing

The prompt asks for **ranking the next 7 days** per activity, not a single "go / no-go" score. I interpreted that as: for each activity, order days from most to least suitable, with a numeric score and short rationale so the ranking is explainable.

No backend → all logic runs on device; Open-Meteo geocoding + forecast only.

## Assumptions (would clarify with PM/design)

| Topic | Assumption |
| --- | --- |
| Surfing | Forecast API has **no wave height**. I score **10 m wind** as a coarse proxy and assume the user searches **coastal** towns when planning surf. |
| Skiing | Resort elevation varies; I use **grid elevation** from the forecast location only (no mountain-specific model). Fresh **`snowfall_sum`** boosts score; cold + dry is "OK" but not ideal. |
| Indoor sightseeing | "Good" indoor days correlate with **bad outdoor sightseeing** weather (rain, extremes, storms) — museums as fallback, not competing with a perfect patio day. |
| Ranking ties | Same score → earlier calendar day ranks higher (stable, predictable). |
| Search | Debounced geocoding after **2+ characters**; errors during typing don't flash error banners (empty suggestions). |

## Architecture

- **SwiftUI + `@Observable` view model** — minimal boilerplate, fits iOS 17+ take-home scope.
- **`OpenMeteoClientProtocol`** — network boundary for tests / future mocks.
- **`SuitabilityScorer`** — pure functions, unit tested without UI or URLSession.
- **No third-party dependencies** — fewer moving parts for reviewers cloning the repo.

Trade-off: I did not add a dedicated domain layer with use-case types; for ~7 days × 4 activities the view model calling client + scorer stays readable.

## Suitability model

Scores are **0–100 heuristic sums**, not ML. Each activity has hand-tuned weights documented in `SuitabilityScorer.swift`. I verified against live API samples (Berlin, Chamonix-style queries) and adjusted penalties for rain-on-warm-ski-days and storm codes (WMO 95–99).

Verification approach:

1. Hit geocoding + forecast URLs in terminal and inspect JSON field names.
2. Unit tests for skiing extremes and indoor/outdoor inverse relationship.
3. Simulator manual pass: search → select → switch activity segments.

## UI choices

- Single screen: search → pick place → segmented control for activity → **ordered list** with rank, score band, temp range, WMO summary.
- Did **not** build maps, charts, or multi-city compare — scope control for a judgment-focused submission.

## AI usage

AI assisted with scaffolding (boilerplate, WMO code table) and XcodeGen setup. I **verified** API parameters against Open-Meteo docs, ran `curl` on live endpoints, and ran `xcodebuild test` locally before considering it done.

## If I had more time

- Elevation-aware skiing via Open-Meteo elevation parameter or user-picked resort pin.
- Marine / wave API for surf when allowed beyond the exercise minimum.
- Snapshot tests for ranking rows and accessibility labels.
- Persist last searched city.
