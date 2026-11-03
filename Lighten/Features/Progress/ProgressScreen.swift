import SwiftUI

/// Points by week and section, and the exams.
struct ProgressScreen: View {
    @State private var state: Loadable<StudentProgressDTO> = .loading

    var body: some View {
        LoadableView(state: state, retry: load) { progress in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(Strings.Progress.title).font(Typo.title)
                    Text(Strings.Progress.lede).foregroundStyle(Palette.inkSoft)

                    if progress.modules.allSatisfy({ $0.total.maxScore == 0 }) && progress.exams.isEmpty {
                        NoticeText(text: Strings.Progress.empty)
                    } else {
                        Card {
                            Text(Strings.Progress.total).font(Typo.caption).foregroundStyle(Palette.inkSoft)
                            Text(Format.score(progress.total.score, of: progress.total.maxScore)).font(Typo.big)
                        }
                        ForEach(progress.modules) { module in
                            Card {
                                Text(fill(Strings.Progress.week, ["n": module.position]))
                                    .font(Typo.caption).foregroundStyle(Palette.inkSoft)
                                HStack {
                                    Text(module.title).font(Typo.bodyBold)
                                    Spacer()
                                    Text(Format.score(module.total.score, of: module.total.maxScore))
                                        .font(Typo.bodyBold)
                                }
                                ForEach(module.sections.filter { $0.maxScore > 0 }) { section in
                                    HStack {
                                        Text(Strings.section(section.section))
                                        Spacer()
                                        Text(Format.score(section.score, of: section.maxScore))
                                            .foregroundStyle(Palette.inkSoft)
                                    }
                                }
                            }
                        }
                        if !progress.exams.isEmpty {
                            Text(Strings.Progress.exams).font(Typo.card).padding(.top, 8)
                            ForEach(progress.exams) { exam in
                                Card {
                                    Text(Strings.section(exam.section))
                                        .font(Typo.caption).foregroundStyle(Palette.inkSoft)
                                    HStack {
                                        Text(exam.title).font(Typo.bodyBold)
                                        Spacer()
                                        Text(Format.score(exam.score, of: exam.maxScore)).font(Typo.bodyBold)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(Metrics.padding)
            }
            .refreshable { await load() }
        }
        .screen()
        .navigationTitle(Strings.Nav.progress)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        do {
            state = .loaded(try await APIClient.shared.get("student/progress"))
        } catch let error as APIError {
            if case .loaded = state { return }
            state = .failed(error)
        } catch {}
    }
}
