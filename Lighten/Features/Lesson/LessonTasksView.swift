import SwiftUI

/// The tasks of a lesson, one at a time (docs/tz.md §9: one action per
/// screen): answer, check, see the result, go on. When every task has an
/// answer: the score, the review, and "не согласен с оценкой".
struct LessonTasksView: View {
    let lesson: StudentLessonDTO
    let onSubmission: (String, StudentSubmissionDTO) -> Void

    var body: some View {
        let auto = lesson.tasks.filter { $0.type != .essay }
        let essays = lesson.tasks.filter { $0.type == .essay }

        if lesson.tasks.isEmpty {
            Text(Strings.Lesson.noTasks).foregroundStyle(Palette.inkSoft)
        } else {
            VStack(alignment: .leading, spacing: 24) {
                if !auto.isEmpty {
                    AutoTasksView(lesson: lesson, tasks: auto, onSubmission: onSubmission)
                }
                ForEach(essays) { task in
                    EssayTaskView(task: task, canAnswer: lesson.canAnswer) { onSubmission(task.id, $0) }
                }
            }
        }
    }
}

private struct AutoTasksView: View {
    let lesson: StudentLessonDTO
    let tasks: [StudentTaskDTO]
    let onSubmission: (String, StudentSubmissionDTO) -> Void

    /// The task on screen. It stays after the check so the feedback can be read.
    @State private var index: Int?
    @State private var answer: TaskAnswer = .errorCorrection("")
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        Group {
            if let index, lesson.canAnswer, index < tasks.count {
                taskCard(tasks[index], at: index)
            } else {
                ResultView(lesson: lesson, tasks: tasks, onSubmission: onSubmission)
            }
        }
        .onAppear(perform: start)
    }

    private func start() {
        guard index == nil else { return }
        if let first = tasks.firstIndex(where: { $0.submission == nil }) {
            index = first
            answer = TaskAnswer.empty(for: tasks[first]) ?? answer
        }
    }

    private func taskCard(_ task: StudentTaskDTO, at index: Int) -> some View {
        let checked = task.submission
        let remaining = tasks.indices.filter { $0 > index && tasks[$0].submission == nil }.count
        return VStack(alignment: .leading, spacing: 12) {
            Text(fill(Strings.Lesson.taskOf, ["n": index + 1, "total": tasks.count]))
                .font(Typo.caption)
                .foregroundStyle(Palette.inkSoft)
            Card {
                Text(taskPrompt(task)).font(Typo.bodyBold)
                TaskInputView(task: task, answer: $answer, disabled: busy || checked != nil)
                if let details = checked?.details {
                    ReviewView(details: details).padding(.top, 8)
                }
                if let error { NoticeText(text: error, tone: .error) }
                if checked != nil {
                    Button(remaining > 0 ? Strings.Lesson.next : Strings.Lesson.toResult) { goNext(from: index) }
                        .buttonStyle(.primary)
                } else {
                    Button(busy ? Strings.Lesson.checking : Strings.Lesson.check) {
                        Task { await check(task) }
                    }
                    .buttonStyle(.primary)
                    .disabled(busy || !answer.isComplete(for: task))
                    Text(Strings.Lesson.oneAttempt).font(Typo.caption).foregroundStyle(Palette.inkSoft)
                }
            }
        }
    }

    private func goNext(from current: Int) {
        error = nil
        if let next = tasks.indices.first(where: { $0 > current && tasks[$0].submission == nil }) {
            answer = TaskAnswer.empty(for: tasks[next]) ?? answer
            withAnimation(Motion.soft) { index = next }
        } else {
            withAnimation(Motion.soft) { index = tasks.count }
        }
    }

    private func check(_ task: StudentTaskDTO) async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            let submission: StudentSubmissionDTO = try await APIClient.shared.post(
                "student/tasks/\(task.id)/answer", AnswerBody(answer: answer.json))
            onSubmission(task.id, submission)
        } catch APIError.network {
            error = Strings.Lesson.saveError
        } catch let apiError as APIError {
            error = apiError.message
        } catch {}
    }
}

/// The lesson's score and every task's review.
private struct ResultView: View {
    let lesson: StudentLessonDTO
    let tasks: [StudentTaskDTO]
    let onSubmission: (String, StudentSubmissionDTO) -> Void

    var body: some View {
        let answered = tasks.filter { $0.submission != nil }
        let score = answered.reduce(0) { $0 + ($1.submission?.score ?? 0) }
        let max = tasks.reduce(0) { $0 + $1.maxScore }
        let anyWrong = answered.contains { ($0.submission?.score ?? 0) < $0.maxScore }

        VStack(alignment: .leading, spacing: 16) {
            if !lesson.canAnswer && answered.count < tasks.count {
                NoticeText(text: Strings.Lesson.readOnly)
            }
            Text(Strings.Result.title).font(Typo.title)
            Text(Format.score(score, of: max)).font(Typo.big)
            if !anyWrong && answered.count == tasks.count {
                Text(Strings.Result.allRight)
            }
            Text(Strings.Result.review).font(Typo.card).padding(.top, 8)
            ForEach(Array(tasks.enumerated()), id: \.element.id) { i, task in
                Card {
                    Text(fill(Strings.Lesson.taskOf, ["n": i + 1, "total": tasks.count]))
                        .font(Typo.caption).foregroundStyle(Palette.inkSoft)
                    Text(taskPrompt(task)).font(Typo.bodyBold)
                    if let line = taskLine(task) { MaterialText(line) }
                    if let submission = task.submission, let details = submission.details {
                        ReviewView(details: details)
                        DisputeBox(submission: submission) { dispute in
                            var updated = submission
                            updated.dispute = dispute
                            onSubmission(task.id, updated)
                        }
                    } else {
                        Text(Strings.Lesson.empty).foregroundStyle(Palette.inkSoft)
                    }
                }
            }
        }
    }

    private func taskLine(_ task: StudentTaskDTO) -> String? {
        switch task.payload {
        case .multipleChoice(let p): return p.question
        case .trueFalse(let p): return p.statement
        case .errorCorrection(let p): return p.sentence
        default: return nil
        }
    }
}

/// Right or "почти", with the right answer next to the student's.
struct ReviewView: View {
    let details: GradeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(details.items.enumerated()), id: \.offset) { _, item in
                if item.correct {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.greenText)
                        Text(Strings.Lesson.correct).font(Typo.bodyBold)
                        MaterialText(item.given)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Strings.Lesson.almost).font(Typo.bodyBold)
                        row(Strings.Lesson.yourAnswer, item.given.isEmpty ? Strings.Lesson.empty : item.given,
                            fill: Palette.coralTint)
                        row(Strings.Lesson.rightAnswer, item.expected, fill: Palette.greenTint)
                    }
                }
            }
        }
    }

    private func row(_ label: String, _ value: String, fill: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(Typo.caption).foregroundStyle(Palette.inkSoft)
            MaterialText(value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: Metrics.radiusSmall).fill(fill))
    }
}

/// "Не согласен с оценкой": always possible (CLAUDE.md). Shows the teacher's
/// answer once there is one.
struct DisputeBox: View {
    let submission: StudentSubmissionDTO
    let onSent: (DisputeDTO) -> Void

    @State private var open = false
    @State private var note = ""
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        if let dispute = submission.dispute {
            VStack(alignment: .leading, spacing: 6) {
                if dispute.resolvedAt != nil {
                    Text(Strings.Result.disputeResolved).font(Typo.bodyBold)
                    if let newScore = dispute.newScore, newScore != dispute.scoreBefore {
                        Text(fill(Strings.Result.disputeNewScore, [
                            "score": Format.score(newScore), "max": Format.score(submission.maxScore),
                        ]))
                    } else {
                        Text(Strings.Result.disputeSameScore)
                    }
                    if let teacherNote = dispute.teacherNote { Text(teacherNote) }
                } else {
                    Text(Strings.Result.disputeSent)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Metrics.radiusSmall).fill(Palette.blueTint))
        } else if open {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Result.disputeLabel).font(Typo.bodyBold)
                TextField(Strings.Result.disputeHint, text: $note, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Palette.bg))
                    .overlay(RoundedRectangle(cornerRadius: Metrics.radius).strokeBorder(Palette.line, lineWidth: 2))
                if let error { NoticeText(text: error, tone: .error) }
                Button(Strings.Result.disputeSend) { Task { await send() } }
                    .buttonStyle(.primary)
                    .disabled(busy || note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button(Strings.Result.disputeCancel) { open = false }
                    .buttonStyle(.secondary)
            }
        } else {
            Button(Strings.Result.dispute) { open = true }
                .font(Typo.caption)
                .foregroundStyle(Palette.blueText)
        }
    }

    private func send() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            let dispute: DisputeDTO = try await APIClient.shared.post(
                "student/submissions/\(submission.id)/dispute",
                DisputeBody(note: String(note.prefix(1000))))
            onSent(dispute)
        } catch let apiError as APIError {
            error = apiError.message
        } catch {}
    }
}
