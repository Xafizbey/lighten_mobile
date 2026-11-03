import SwiftUI

@main
struct LightenApp: App {
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .tint(Palette.greenText)
        }
    }
}

/// Sign-in screen or the cabinet, by the session.
struct RootView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
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
