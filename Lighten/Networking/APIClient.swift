import Foundation

/// Talks to the API the same way the student cabinet in the browser does.
///
/// Sign-in is a session cookie. The API names the cookie after the cabinet in
/// the `x-llife-app` header, so the app says it is the student cabinet and
/// keeps its own sign-in. URLSession stores the cookie in
/// HTTPCookieStorage.shared and sends it back by itself; it survives an app
/// restart until the session expires.
final class APIClient: @unchecked Sendable {
    static let shared = APIClient()

    /// Called when any request answers 401: the app shows the sign-in screen.
    var onUnauthorized: (@Sendable () -> Void)?

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = .shared
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        // Weak mobile internet: wait for the network instead of failing at once.
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 60
        session = URLSession(configuration: configuration)
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        try decode(await send("GET", path, body: Optional<Empty>.none))
    }

    func post<T: Decodable, B: Encodable>(_ path: String, _ body: B) async throws -> T {
        try decode(await send("POST", path, body: body))
    }

    func put<T: Decodable, B: Encodable>(_ path: String, _ body: B) async throws -> T {
        try decode(await send("PUT", path, body: body))
    }

    /// For routes that answer 204 No Content.
    func send<B: Encodable>(_ method: String, _ path: String, _ body: B) async throws {
        _ = try await send(method, path, body: body)
    }

    func send(_ method: String, _ path: String) async throws {
        _ = try await send(method, path, body: Optional<Empty>.none)
    }

    /// Forgets the session cookie. Used on sign-out, after the API closed it.
    func clearCookies() {
        let storage = HTTPCookieStorage.shared
        for cookie in storage.cookies(for: AppConfig.baseURL) ?? [] {
            storage.deleteCookie(cookie)
        }
    }

    // MARK: - Private

    private struct Empty: Codable {}

    private func send<B: Encodable>(_ method: String, _ path: String, body: B?) async throws -> Data {
        var request = URLRequest(url: AppConfig.apiURL(path))
        request.httpMethod = method
        request.setValue("student", forHTTPHeaderField: "x-llife-app")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw APIError.network
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.network }
        switch http.statusCode {
        case 200..<300:
            return data
        default:
            let code = (try? decoder.decode(NestErrorBody.self, from: data))?.code
            // The session is gone. A wrong password is a 401 too, but with its own code.
            if http.statusCode == 401 && code == "not_signed_in" {
                onUnauthorized?()
                throw APIError.unauthorized
            }
            throw APIError.server(status: http.statusCode, code: code)
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }
}
