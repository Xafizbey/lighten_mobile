import SwiftUI

@main
struct LightenApp: App {
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .tint(Palette.blueText)
        }
    }
}

/// Sign-in screen or the cabinet, by the session, under the opening splash.
/// The session is checked while the splash plays.
struct RootView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var splash = true

    var body: some View {
        ZStack {
            Group {
                switch session.state {
                case .checking:
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).screen()
                case .signedOut:
                    LoginView()
                case .signedIn:
                    CabinetView()
                }
            }

            if splash {
                SplashView {
                    withAnimation(Motion.soft) { splash = false }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .task { await session.restore() }
    }
}

/// The three parts of the cabinet, as in the site's navigation.
struct CabinetView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label(Strings.Nav.home, systemImage: "house") }
            NavigationStack { ProgressScreen() }
                .tabItem { Label(Strings.Nav.progress, systemImage: "chart.bar") }
            NavigationStack { AccountView() }
                .tabItem { Label(Strings.Nav.account, systemImage: "person") }
        }
    }
}
