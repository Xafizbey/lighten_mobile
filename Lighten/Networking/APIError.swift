import Foundation

/// What went wrong with a request, in the student's words (Strings.errors).
enum APIError: Error, Equatable {
    /// No connection, or the server did not answer.
    case network
    /// The session is gone: sign in again.
    case unauthorized
    /// The API's error code, such as "already_answered" (NestJS `message`).
    case server(status: Int, code: String?)
    /// The answer did not look like the app expected.
    case decoding(String)

    var code: String? {
        switch self {
        case .network: return "network"
        case .unauthorized: return nil
        case .server(_, let code): return code
        case .decoding: return nil
        }
    }

    var message: String { Strings.errorText(code) }
}

/// The body NestJS sends with an error: `{ statusCode, message, error }`.
/// `message` is a code for our own errors and a list for validation errors.
struct NestErrorBody: Decodable {
    let message: JSONValue?

    var code: String? {
        if let text = message?.stringValue { return text }
        return message?.arrayValue?.first?.stringValue
    }
}
