import Foundation

/// Who is signed in. The session itself is the API's cookie; this keeps the
/// user it belongs to, and drops to the sign-in screen when the API says 401.
@MainActor
final class SessionStore: ObservableObject {
    enum State: Equatable {
        case checking
        case signedOut
        case signedIn(MeDTO)
    }

    @Published private(set) var state: State = .checking

    var me: MeDTO? {
        if case .signedIn(let me) = state { return me }
        return nil
    }

    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
        api.onUnauthorized = { [weak self] in
            Task { @MainActor in self?.state = .signedOut }
        }
    }

    /// On launch: is the stored cookie still a session?
    func restore() async {
        guard state == .checking else { return }
        do {
            let me: MeDTO = try await api.get("auth/me")
            state = me.role == .student ? .signedIn(me) : .signedOut
        } catch APIError.network {
            // No internet on launch: keep the sign-in, the screens will retry.
            state = HTTPCookieStorage.shared.cookies(for: AppConfig.baseURL)?.isEmpty == false
                ? .signedIn(MeDTO(id: "", name: "", login: "", role: .student))
                : .signedOut
        } catch {
            state = .signedOut
        }
    }

    /// Signs in. Throws APIError; `teacherAccount` when the login is a teacher's.
    func login(login: String, password: String) async throws {
        let me: MeDTO = try await api.post("auth/login", LoginBody(login: login, password: password))
        guard me.role == .student else {
            try? await api.send("POST", "auth/logout")
            api.clearCookies()
            throw LoginError.teacherAccount
        }
        state = .signedIn(me)
    }

    func logout() async {
        try? await api.send("POST", "auth/logout")
        api.clearCookies()
        state = .signedOut
    }

    /// The user's name and login, after an offline launch.
    func refreshMe() async {
        guard let me: MeDTO = try? await api.get("auth/me"), me.role == .student else { return }
        state = .signedIn(me)
    }
}

enum LoginError: Error {
    case teacherAccount
}
