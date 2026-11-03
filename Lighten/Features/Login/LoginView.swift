import SwiftUI

/// Sign-in with the phone or email and the password the teacher gave.
struct LoginView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var login = ""
    @State private var password = ""
    @State private var busy = false
    @State private var error: String?
    @FocusState private var focus: Field?

    private enum Field { case login, password }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LogoMark(size: 64)
                    .padding(.top, 40)
                Text(Strings.Login.title).font(Typo.big)
                Text(Strings.Login.lede).foregroundStyle(Palette.inkSoft)

                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Login.login).font(Typo.bodyBold)
                    TextField(Strings.Login.loginHint, text: $login)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focus, equals: .login)
                        .onSubmit { focus = .password }
                        .fieldStyle()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Login.password).font(Typo.bodyBold)
                    SecureField("", text: $password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .focused($focus, equals: .password)
                        .onSubmit { Task { await submit() } }
                        .fieldStyle()
                }

                if let error { NoticeText(text: error, tone: .error) }

                Button(busy ? Strings.Login.submitting : Strings.Login.submit) {
                    Task { await submit() }
                }
                .buttonStyle(.primary)
                .disabled(busy || login.isEmpty || password.isEmpty)
            }
            .padding(Metrics.padding)
        }
        .scrollDismissesKeyboard(.interactively)
        .screen()
    }

    private func submit() async {
        guard !busy, !login.isEmpty, !password.isEmpty else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await session.login(login: login, password: password)
        } catch LoginError.teacherAccount {
            error = Strings.Login.teacherAccount
        } catch let apiError as APIError {
            error = apiError.message
        } catch {
            self.error = Strings.unknownError
        }
    }
}

extension View {
    /// A text field: big enough for a thumb, 17 pt text.
    func fieldStyle() -> some View {
        self
            .font(Typo.body)
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Palette.bg))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.radius).strokeBorder(Palette.line, lineWidth: 2)
            )
    }
}
