import SwiftUI

/// The exam lesson before, during and after (docs/tz.md §10).
struct ExamGateView: View {
    let lesson: StudentLessonDTO
    let reload: () async -> Void

    @State private var running = false
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(Strings.Exam.label).font(Typo.caption).foregroundStyle(Palette.blueText)
                Text(lesson.title).font(Typo.title)
                if let exam = lesson.exam {
                    switch exam.state {
                    case .notStarted: intro(exam)
                    case .running:
                        Button(Strings.Exam.resume) { running = true }.buttonStyle(.primary)
                    case .finished: finished
                    }
                }
                if let error { NoticeText(text: error, tone: .error) }
            }
            .padding(Metrics.padding)
        }
        .onAppear { if lesson.exam?.state == .running { running = true } }
        .fullScreenCover(isPresented: $running, onDismiss: { Task { await reload() } }) {
            ExamRunnerView(lesson: lesson) { running = false }
        }
    }

    private func intro(_ exam: StudentExamDTO) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(fill(Strings.Exam.intro, [
                "n": exam.taskCount, "taskUnit": plural(exam.taskCount, Strings.Units.task),
                "minutes": exam.minutes, "minuteUnit": plural(exam.minutes, Strings.Units.minute),
            ]))
            .font(Typo.card)
            ForEach(Strings.Exam.rules, id: \.self) { rule in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle().fill(Palette.ink).frame(width: 6, height: 6)
                    Text(rule)
                }
            }
            if let plays = exam.audioPlays, lesson.audioUrl != nil {
                Text(fill(Strings.Exam.plays, ["n": plays, "unit": plural(plays, Strings.Units.time)]))
            }
            if lesson.canAnswer {
                Button(busy ? Strings.Exam.starting : Strings.Exam.start) { Task { await start() } }
                    .buttonStyle(.primary)
                    .disabled(busy)
            } else {
                NoticeText(text: Strings.Lesson.readOnly)
            }
        }
    }

    private var finished: some View {
        let score = lesson.tasks.reduce(0) { $0 + ($1.submission?.score ?? 0) }
        let max = lesson.tasks.reduce(0) { $0 + $1.maxScore }
        return VStack(alignment: .leading, spacing: 16) {
            Text(Strings.Exam.finishedTitle).font(Typo.card)
            Text(Format.score(score, of: max)).font(Typo.big)
            Text(Strings.Result.review).font(Typo.card)
            ForEach(Array(lesson.tasks.enumerated()), id: \.element.id) { i, task in
                Card {
                    Text(fill(Strings.Exam.taskOf, ["n": i + 1, "total": lesson.tasks.count]))
                        .font(Typo.caption).foregroundStyle(Palette.inkSoft)
                    Text(taskPrompt(task)).font(Typo.bodyBold)
                    if let details = task.submission?.details {
                        ReviewView(details: details)
                    } else {
                        Text(Strings.Lesson.empty).foregroundStyle(Palette.inkSoft)
                    }
                }
            }
        }
    }

    private func start() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await APIClient.shared.send("POST", "student/lessons/\(lesson.id)/exam/start")
            await reload()
            running = true
        } catch let apiError as APIError {
            error = apiError.message
        } catch {}
    }
}
