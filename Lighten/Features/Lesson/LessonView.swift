import SwiftUI

/// A lesson: the material first, then the tasks one at a time. An exam lesson
/// opens the exam screen instead.
struct LessonView: View {
    let lessonId: String
    @State private var state: Loadable<StudentLessonDTO> = .loading

    var body: some View {
        LoadableView(state: state, retry: load) { lesson in
            if lesson.exam != nil {
                ExamGateView(lesson: lesson, reload: load)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.section(lesson.section))
                                .font(Typo.caption)
                                .foregroundStyle(Palette.inkSoft)
                            Text(lesson.title).font(Typo.title)
                        }
                        MaterialSection(lesson: lesson)
                        LessonTasksView(lesson: lesson) { taskId, submission in
                            update(taskId: taskId, submission: submission)
                        }
                    }
                    .padding(Metrics.padding)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .screen()
        .navigationBarTitleDisplayMode(.inline)
        .task { if case .loading = state { await load() } }
    }

    private func update(taskId: String, submission: StudentSubmissionDTO) {
        guard case .loaded(var lesson) = state,
              let index = lesson.tasks.firstIndex(where: { $0.id == taskId }) else { return }
        lesson.tasks[index].submission = submission
        state = .loaded(lesson)
    }

    private func load() async {
        do {
            state = .loaded(try await APIClient.shared.get("student/lessons/\(lessonId)"))
        } catch let error as APIError {
            if case .loaded = state { return }
            state = .failed(error)
        } catch {}
    }
}
