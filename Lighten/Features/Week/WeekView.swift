import SwiftUI

/// One week: its lessons by section, each with a visible status.
struct WeekView: View {
    let moduleId: String
    @State private var state: Loadable<StudentModuleDetailDTO> = .loading

    var body: some View {
        LoadableView(state: state, retry: load) { week in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(week.title).font(Typo.title)
                        if week.state == .open {
                            Text(fill(Strings.Week.due, ["date": Format.dayMonth(week.lastDay)]))
                                .foregroundStyle(Palette.inkSoft)
                        }
                    }
                    switch week.state {
                    case .upcoming: NoticeText(text: Strings.Week.notOpen)
                    case .closed: NoticeText(text: Strings.Week.closed)
                    case .open: EmptyView()
                    }
                    if week.lessons.isEmpty && week.state != .upcoming {
                        Text(Strings.Week.empty).foregroundStyle(Palette.inkSoft)
                    }
                    ForEach(SectionCode.allCases) { section in
                        let lessons = week.lessons.filter { $0.section == section }
                        if !lessons.isEmpty {
                            Text(Strings.section(section)).font(Typo.card).padding(.top, 8)
                            ForEach(lessons) { lesson in
                                NavigationLink(value: Route.lesson(lesson.id)) { row(lesson) }
                                    .buttonStyle(.plain)
                                    .disabled(week.state == .upcoming)
                            }
                        }
                    }
                }
                .padding(Metrics.padding)
            }
            .refreshable { await load() }
        }
        .screen()
        .navigationTitle(titleText)
        .navigationBarTitleDisplayMode(.inline)
        .task { if case .loading = state { await load() } }
    }

    private var titleText: String {
        if case .loaded(let week) = state { return fill(Strings.Week.title, ["n": week.position]) }
        return ""
    }

    private func row(_ lesson: StudentLessonSummaryDTO) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                if lesson.isExam {
                    Text(Strings.Exam.label).font(Typo.caption).foregroundStyle(Palette.blueText)
                }
                Text(lesson.title).font(Typo.bodyBold).multilineTextAlignment(.leading)
                HStack(spacing: 8) {
                    if lesson.taskCount == 0 {
                        Text(Strings.statusMaterial).font(Typo.caption).foregroundStyle(Palette.inkSoft)
                    } else {
                        StatusBadge(status: lesson.status)
                        if lesson.status == .done {
                            Text(Format.score(lesson.score, of: lesson.maxScore))
                                .font(Typo.caption).foregroundStyle(Palette.inkSoft)
                        }
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Palette.inkSoft)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Palette.bg))
        .overlay(RoundedRectangle(cornerRadius: Metrics.radius).strokeBorder(Palette.line, lineWidth: 2))
    }

    private func load() async {
        do {
            state = .loaded(try await APIClient.shared.get("student/modules/\(moduleId)"))
        } catch let error as APIError {
            if case .loaded = state { return }
            state = .failed(error)
        } catch {}
    }
}
