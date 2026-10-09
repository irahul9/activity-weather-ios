import Foundation

enum OpenMeteoError: LocalizedError, Sendable {
    case invalidURL
    case httpFailure(statusCode: Int)
    case decodingFailure
    case emptyResults
    case offline

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Could not build the weather request."
        case .httpFailure(let statusCode):
            "Weather service returned status \(statusCode)."
        case .decodingFailure:
            "Could not read the weather response."
        case .emptyResults:
            "No matching places found. Try adding a country or region."
        case .offline:
            "You appear to be offline. Check your connection and try again."
        }
    }
}
