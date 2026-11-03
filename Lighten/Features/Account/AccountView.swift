import SwiftUI

/// Profile: login, level, group, course, and sign-out. The password is the
/// teacher's to change.
struct AccountView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var home: StudentHomeDTO?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(home?.name ?? session.me?.name ?? "").font(Typo.title)
                Card {
                    row(Strings.Account.login, session.me?.login ?? "")
                    row(Strings.Account.level, home?.level ?? Strings.Account.noLevel)
                    row(Strings.Account.group, home?.groupName ?? Strings.Account.noGroup)
                    if let course = home?.courseTitle { row(Strings.Account.course, course) }
                }
                Text(Strings.Account.forgot).foregroundStyle(Palette.inkSoft)
                Button(Strings.Account.logout) { Task { await session.logout() } }
                    .buttonStyle(.secondary)
                    .padding(.top, 8)
            }
            .padding(Metrics.padding)
        }
        .screen()
        .navigationTitle(Strings.Account.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await session.refreshMe()
            if let loaded: StudentHomeDTO = try? await APIClient.shared.get("student/home") {
                home = loaded
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(Typo.caption).foregroundStyle(Palette.inkSoft)
            Text(value).font(Typo.bodyBold)
        }
    }
}
