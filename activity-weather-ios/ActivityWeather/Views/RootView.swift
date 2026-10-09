import SwiftUI

struct RootView: View {
    @State private var viewModel = WeatherSearchViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SearchSection(viewModel: viewModel)
                    if viewModel.isLoadingForecast {
                        ProgressView("Loading 7-day forecast…")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                    } else if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    } else if viewModel.forecast != nil {
                        ForecastSection(viewModel: viewModel)
                    } else {
                        EmptyStateView()
                    }
                }
                .padding()
            }
            .navigationTitle("Activity Weather")
            .background(Color(.systemGroupedBackground))
        }
    }
}

private struct SearchSection: View {
    @Bindable var viewModel: WeatherSearchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where are you going?")
                .font(.headline)

            TextField("City or town", text: $viewModel.searchText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(12)
                .background(.background, in: RoundedRectangle(cornerRadius: 12))
                .onChange(of: viewModel.searchText) { _, _ in
                    viewModel.onSearchTextChanged()
                }

            if viewModel.isSearching {
                ProgressView()
                    .controlSize(.small)
            }

            if !viewModel.suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.suggestions) { location in
                        Button {
                            viewModel.select(location)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(location.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(location.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                        }
                        if location.id != viewModel.suggestions.last?.id {
                            Divider()
                        }
                    }
                }
                .background(.background, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

private struct ForecastSection: View {
    @Bindable var viewModel: WeatherSearchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let location = viewModel.selectedLocation {
                Text(location.displayName)
                    .font(.title3.weight(.semibold))
            }

            Text("Next 7 days — ranked best to worst for each activity.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Activity", selection: $viewModel.selectedActivity) {
                ForEach(ActivityType.allCases) { activity in
                    Label(activity.title, systemImage: activity.symbolName)
                        .tag(activity)
                }
            }
            .pickerStyle(.menu)

            if let ranking = viewModel.ranking(for: viewModel.selectedActivity) {
                ActivityRankingList(ranking: ranking)
            }
        }
    }
}

private struct ActivityRankingList: View {
    let ranking: ActivityRanking

    var body: some View {
        VStack(spacing: 10) {
            ForEach(ranking.rankedDays) { item in
                RankingRow(item: item)
            }
        }
    }
}

private struct RankingRow: View {
    let item: ActivityDayScore

    private var band: SuitabilityBand { SuitabilityBand(score: item.score) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("#\(item.rank)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.day.date, format: .dateTime.weekday(.wide).month().day())
                        .font(.body.weight(.semibold))
                    Spacer()
                    ScoreBadge(score: item.score, band: band)
                }
                Text("\(Int(item.day.temperatureMinC))–\(Int(item.day.temperatureMaxC))°C · \(WMOWeatherCode.shortDescription(for: item.day.weatherCode))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ScoreBadge: View {
    let score: Int
    let band: SuitabilityBand

    var body: some View {
        Text("\(score) · \(band.label)")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bandColor.opacity(0.15), in: Capsule())
            .foregroundStyle(bandColor)
    }

    private var bandColor: Color {
        switch band {
        case .excellent: .green
        case .good: .mint
        case .fair: .orange
        case .poor: .red
        }
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline)
            .foregroundStyle(.red)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Search for a city to see which days fit skiing, surfing, and sightseeing.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    RootView()
}
