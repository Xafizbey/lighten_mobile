import SwiftUI

/// Home: one big card with the next thing to do, the week's sections under
/// it, and every week of the course after that (apps/web/app/(cabinet)/page.tsx).
struct HomeView: View {
    @State private var state: Loadable<StudentHomeDTO> = .loading

    var body: some View {
        LoadableView(state: state, retry: load) { home in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header(home)
                    MainStory(home: home)
                    if home.access.open, let week = home.current {
                        SectionRail(week: week)
                    }
                    if home.checking > 0 {
                        NoticeText(text: fill(Strings.Home.checking, [
                            "n": home.checking, "unit": plural(home.checking, Strings.Units.work),
                        ]))
                    }
                    if !home.weeks.isEmpty {
                        WeekList(weeks: home.weeks, canOpen: home.access.open)
                    }
                    if home.access.open, let until = home.access.until {
                        Text(fill(Strings.Home.accessUntil, ["date": Format.dayMonth(until)]))
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSoft)
                    }
                }
                .padding(Metrics.padding)
            }
            .refreshable { await load() }
        }
        .screen()
        .navigationTitle(Strings.Nav.home)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Route.self) { $0.destination }
        .task { if case .loading = state { await load() } }
    }

    private func header(_ home: StudentHomeDTO) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(fill(Strings.Home.greeting, ["name": home.name])).font(Typo.title)
            let meta = [home.level, home.groupName].compactMap { $0 }
            if !meta.isEmpty {
                Text(meta.joined(separator: " · "))
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private func load() async {
        do {
            state = .loaded(try await APIClient.shared.get("student/home"))
        } catch let error as APIError {
            if case .loaded = state { return } // keep what is on screen
            state = .failed(error)
        } catch {}
    }
}

/// Where a tap leads, inside a tab's NavigationStack.
enum Route: Hashable {
    case week(String)
    case lesson(String)

    @ViewBuilder var destination: some View {
        switch self {
        case .week(let id): WeekView(moduleId: id)
        case .lesson(let id): LessonView(lessonId: id)
        }
    }
}

/// The one thing to do now.
private struct MainStory: View {
    let home: StudentHomeDTO

    var body: some View {
        if home.startsOn == nil {
            Story(tone: nil, kick: Strings.Home.soonKick, title: Strings.Home.soonTitle,
                  text: Strings.Home.noCourse)
        } else if !home.access.open {
            Story(tone: Palette.bright(Palette.coral), kick: Strings.Home.closedKick, title: Strings.Home.closedTitle,
                  text: Strings.Home.accessClosed)
        } else if let week = home.current, let next = home.nextLesson {
            NavigationLink(value: Route.lesson(next.id)) {
                Story(
                    tone: Palette.tone(next.section),
                    kick: fill(Strings.Home.nextKick, ["n": week.position]),
                    title: Strings.section(next.section),
                    text: fill(Strings.Home.nextText, [
                        "title": next.title, "n": next.taskCount,
                        "unit": plural(next.taskCount, Strings.Units.task),
                    ]),
                    action: next.status == .notStarted ? Strings.Home.start : Strings.Home.continueLabel
                )
            }
            .buttonStyle(.plain)
        } else if let week = home.current {
            NavigationLink(value: Route.week(week.id)) {
                Story(tone: Palette.bright(Palette.green), kick: fill(Strings.Home.weekDoneKick, ["n": week.position]),
                      title: Strings.Home.weekDoneTitle, text: Strings.Home.weekDoneText,
                      action: Strings.Home.toWeek)
            }
            .buttonStyle(.plain)
        } else if let next = home.next {
            Story(tone: nil, kick: Strings.Home.soonKick, title: next.title,
                  text: fill(Strings.Home.beforeStart, ["date": Format.dayMonth(moment: next.opensAt)]))
        } else {
            Story(tone: nil, kick: Strings.brand, title: Strings.Progress.title,
                  text: Strings.Home.finished)
        }
    }
}

private struct Story: View {
    /// A fill with its text, or nil for the page's own surface.
    let tone: Palette.Tone?
    let kick: String
    let title: String
    let text: String
    var action: String?

    /// Bright fills take `onBright` text in both themes; the page fill follows the theme.
    private var bright: Bool { tone != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(kick).font(Typo.caption)
            Text(title).font(Typo.big)
            Text(text).font(Typo.body)
            if let action {
                HStack {
                    Text(action).font(Typo.bodyBold)
                    Image(systemName: "arrow.right")
                }
                .padding(.top, 8)
            }
        }
        .foregroundStyle(tone?.text ?? Palette.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(tone?.fill ?? Palette.bg))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Palette.line, lineWidth: bright ? 0 : 2))
    }
}

/// The open week's sections, side by side.
private struct SectionRail: View {
    let week: StudentModuleDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink(value: Route.week(week.id)) {
                HStack {
                    Text(Strings.Home.thisWeek).font(Typo.card)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Palette.inkSoft)
                }
            }
            .buttonStyle(.plain)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(week.sections) { section in
                        NavigationLink(value: Route.week(week.id)) { tile(section) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func tile(_ s: SectionProgressDTO) -> some View {
        let state: String
        if s.lessonsTotal > 0 && s.lessonsDone == s.lessonsTotal {
            state = Strings.Home.tileDone
        } else if s.maxScore == 0 {
            state = Strings.Home.tileMaterial
        } else {
            state = fill(Strings.Home.tileLessons, ["done": s.lessonsDone, "total": s.lessonsTotal])
        }
        return VStack(alignment: .leading, spacing: 6) {
            Text(Strings.section(s.section)).font(Typo.bodyBold)
            Text(state).font(Typo.caption)
        }
        .foregroundStyle(Palette.tone(s.section).text)
        .frame(width: 128, height: 92, alignment: .topLeading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Palette.tone(s.section).fill))
        .overlay(RoundedRectangle(cornerRadius: Metrics.radius).strokeBorder(Palette.line, lineWidth: 2))
    }
}

/// Every week of the course: done, open and still closed.
private struct WeekList: View {
    let weeks: [StudentModuleDTO]
    let canOpen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.Home.allWeeks).font(Typo.card)
            ForEach(weeks) { week in
                if canOpen && week.state != .upcoming {
                    NavigationLink(value: Route.week(week.id)) { row(week) }.buttonStyle(.plain)
                } else {
                    row(week)
                }
            }
        }
    }

    private func row(_ week: StudentModuleDTO) -> some View {
        let done = week.sections.reduce(0) { $0 + $1.lessonsDone }
        let total = week.sections.reduce(0) { $0 + $1.lessonsTotal }
        let state: String
        switch week.state {
        case .open: state = Strings.Home.weekNow
        case .upcoming: state = fill(Strings.Home.weekOpensOn, ["date": Format.dayMonth(moment: week.opensAt)])
        case .closed: state = total > 0
            ? fill(Strings.Home.weekDone, ["done": done, "total": total])
            : Strings.Home.weekClosed
        }
        return HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(fill(Strings.Home.weekRow, ["n": week.position])).font(Typo.caption)
                    .foregroundStyle(Palette.inkSoft)
                Text(week.title).font(Typo.bodyBold)
                Text(state).font(Typo.caption).foregroundStyle(
                    week.state == .open ? Palette.greenText : Palette.inkSoft)
            }
            Spacer()
            if week.state == .upcoming {
                Image(systemName: "lock").foregroundStyle(Palette.inkSoft)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Palette.bg))
        .overlay(RoundedRectangle(cornerRadius: Metrics.radius).strokeBorder(
            week.state == .open ? Palette.green : Palette.line, lineWidth: 2))
    }
}
