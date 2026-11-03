import SwiftUI

/// The exam itself: no navigation, only the time and the task.
///
/// The server keeps the clock: the app counts down to the server's
/// `expiresAt`, corrected by the difference between the phone's clock and
/// the server's. Every answer is saved on the phone first and then on the
/// server; after a lost connection the exam opens at the same place.
struct ExamRunnerView: View {
    let onClose: () -> Void

    @State private var lesson: StudentLessonDTO
    @State private var answers: [String: TaskAnswer] = [:]
    @State private var index = 0
    @State private var saveState: SaveState = .idle
    @State private var confirmFinish = false
    @State private var finishing = false
    @State private var timeUp = false
    @State private var error: String?

    private let clockOffset: TimeInterval
    private let expiresAt: Date?

    private enum SaveState { case idle, saving, saved, offline }

    init(lesson: StudentLessonDTO, onClose: @escaping () -> Void) {
        self.onClose = onClose
        _lesson = State(initialValue: lesson)
        let serverNow = lesson.exam.flatMap { Format.parseMoment($0.now) } ?? Date()
        clockOffset = serverNow.timeIntervalSinceNow
        expiresAt = lesson.exam?.expiresAt.flatMap(Format.parseMoment)
    }

    var body: some View {
        VStack(spacing: 0) {
            timerBar
            if timeUp {
                done(Strings.Exam.timeUp)
            } else if lesson.tasks.isEmpty {
                ProgressView().frame(maxHeight: .infinity)
            } else {
                taskScreen
            }
        }
        .screen()
        .interactiveDismissDisabled()
        .onAppear(perform: restoreAnswers)
        .task { await flushPending() }
    }

    // MARK: - Timer

    private var timerBar: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let left = secondsLeft(at: context.date)
            Text(fill(Strings.Exam.left, ["time": Format.countdown(left)]))
                .font(Typo.bodyBold.monospacedDigit())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Palette.bg)
                .onChange(of: expiresAt != nil && left <= 0, initial: true) { _, over in
                    if over && !timeUp { Task { await finish(timeIsUp: true) } }
                }
        }
    }

    private func secondsLeft(at date: Date) -> Int {
        guard let expiresAt else { return 0 }
        return Int(expiresAt.timeIntervalSince(date.addingTimeInterval(clockOffset)).rounded(.down))
    }

    // MARK: - Tasks

    private var taskScreen: some View {
        let task = lesson.tasks[index]
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(fill(Strings.Exam.taskOf, ["n": index + 1, "total": lesson.tasks.count]))
                    .font(Typo.caption).foregroundStyle(Palette.inkSoft)

                if let audio = lesson.audioUrl, let url = URL(string: audio) {
                    examAudio(url)
                }

                Card {
                    Text(taskPrompt(task)).font(Typo.bodyBold)
                    TaskInputView(task: task, answer: binding(for: task))
                }

                switch saveState {
                case .saving: Text(Strings.Exam.saving).font(Typo.caption).foregroundStyle(Palette.inkSoft)
                case .saved: Text(Strings.Exam.saved).font(Typo.caption).foregroundStyle(Palette.inkSoft)
                case .offline: NoticeText(text: Strings.Exam.offline)
                case .idle: EmptyView()
                }
                if let error { NoticeText(text: error, tone: .error) }

                HStack(spacing: 12) {
                    if index > 0 {
                        Button(Strings.Exam.prev) { index -= 1 }.buttonStyle(.secondary)
                    }
                    if index < lesson.tasks.count - 1 {
                        Button(Strings.Exam.next) { index += 1 }.buttonStyle(.secondary)
                    }
                }

                Button(finishing ? Strings.Exam.finishing : Strings.Exam.finish) { confirmFinish = true }
                    .buttonStyle(.primary)
                    .disabled(finishing)
                    .padding(.top, 8)
                    .confirmationDialog(finishMessage, isPresented: $confirmFinish, titleVisibility: .visible) {
                        Button(Strings.Exam.finish) { Task { await finish(timeIsUp: false) } }
                        Button(Strings.Exam.cancel, role: .cancel) {}
                    }
            }
            .padding(Metrics.padding)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var finishMessage: String {
        let empty = lesson.tasks.filter { task in
            guard let answer = answers[task.id] else { return true }
            return !answer.isComplete(for: task)
        }.count
        guard empty > 0 else { return Strings.Exam.finishConfirm }
        return Strings.Exam.finishConfirm + " "
            + fill(Strings.Exam.unanswered, ["n": empty, "unit": plural(empty, Strings.Units.task)])
    }

    private func examAudio(_ url: URL) -> some View {
        let exam = lesson.exam
        let left = exam?.audioPlays.map { max(0, $0 - (exam?.playsUsed ?? 0)) }
        return VStack(alignment: .leading, spacing: 6) {
            AudioPlayerView(url: url, beforePlay: { await registerPlay() }, disabled: left == 0)
            if let left {
                Text(left > 0 ? fill(Strings.Exam.playsLeft, ["n": left]) : Strings.Exam.noPlays)
                    .font(Typo.caption).foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private func done(_ text: String) -> some View {
        VStack(spacing: 20) {
            NoticeText(text: text)
            Button(Strings.Exam.toResult, action: onClose).buttonStyle(.primary)
        }
        .padding(Metrics.padding)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Answers

    private func binding(for task: StudentTaskDTO) -> Binding<TaskAnswer> {
        Binding(
            get: { answers[task.id] ?? TaskAnswer.empty(for: task) ?? .errorCorrection("") },
            set: { value in
                answers[task.id] = value
                ExamAnswerStore.save(value.json, taskId: task.id)
                Task { await save(task.id, value) }
            }
        )
    }

    private func restoreAnswers() {
        for task in lesson.tasks where answers[task.id] == nil {
            let local = ExamAnswerStore.load(taskId: task.id)
            answers[task.id] = TaskAnswer.saved(local ?? task.submission?.answers, for: task)
        }
        if let firstEmpty = lesson.tasks.firstIndex(where: { task in
            !(answers[task.id]?.isComplete(for: task) ?? false)
        }) {
            index = firstEmpty
        }
    }

    private func save(_ taskId: String, _ answer: TaskAnswer) async {
        saveState = .saving
        do {
            try await APIClient.shared.send("PUT", "student/tasks/\(taskId)/exam-answer", AnswerBody(answer: answer.json))
            ExamAnswerStore.markSent(taskId: taskId)
            saveState = .saved
        } catch APIError.network {
            saveState = .offline
        } catch let apiError as APIError {
            if apiError.code == "exam_time_up" || apiError.code == "exam_finished" {
                timeUp = true
            } else {
                saveState = .idle
                error = apiError.message
            }
        } catch {}
    }

    /// Answers saved on the phone while the connection was gone.
    private func flushPending() async {
        for task in lesson.tasks {
            guard ExamAnswerStore.isPending(taskId: task.id), let answer = answers[task.id] else { continue }
            await save(task.id, answer)
        }
    }

    private func registerPlay() async -> Bool {
        do {
            let result: PlaysUsed = try await APIClient.shared.post(
                "student/lessons/\(lesson.id)/exam/play", EmptyBody())
            if let exam = lesson.exam {
                lesson = lesson.with(exam: exam.with(playsUsed: result.playsUsed))
            }
            return true
        } catch let apiError as APIError {
            error = apiError.message
            return false
        } catch {
            return false
        }
    }

    private func finish(timeIsUp: Bool) async {
        guard !finishing else { return }
        finishing = true
        defer { finishing = false }
        await flushPending()
        do {
            try await APIClient.shared.send("POST", "student/lessons/\(lesson.id)/exam/finish")
        } catch let apiError as APIError {
            let over = apiError.code == "exam_finished" || apiError.code == "exam_time_up"
            if !over {
                error = apiError.message
                return
            }
        } catch {
            return
        }
        lesson.tasks.forEach { ExamAnswerStore.clear(taskId: $0.id) }
        if timeIsUp { timeUp = true } else { onClose() }
    }
}

struct EmptyBody: Encodable {}

private extension StudentLessonDTO {
    func with(exam: StudentExamDTO) -> StudentLessonDTO {
        StudentLessonDTO(id: id, title: title, section: section, body: body, videoUrl: videoUrl,
                         audioUrl: audioUrl, slides: slides, module: module, canAnswer: canAnswer,
                         exam: exam, tasks: tasks)
    }
}

private extension StudentExamDTO {
    func with(playsUsed: Int) -> StudentExamDTO {
        StudentExamDTO(minutes: minutes, audioPlays: audioPlays, state: state, taskCount: taskCount,
                       startedAt: startedAt, expiresAt: expiresAt, finishedAt: finishedAt, now: now,
                       playsUsed: playsUsed)
    }
}

/// Exam answers on the phone, with a mark for those not yet on the server.
enum ExamAnswerStore {
    private static func key(_ id: String) -> String { "exam-answer-\(id)" }
    private static func pendingKey(_ id: String) -> String { "exam-pending-\(id)" }

    static func save(_ value: JSONValue, taskId: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key(taskId))
            UserDefaults.standard.set(true, forKey: pendingKey(taskId))
        }
    }

    static func load(taskId: String) -> JSONValue? {
        guard let data = UserDefaults.standard.data(forKey: key(taskId)) else { return nil }
        return try? JSONDecoder().decode(JSONValue.self, from: data)
    }

    static func isPending(taskId: String) -> Bool {
        UserDefaults.standard.bool(forKey: pendingKey(taskId))
    }

    static func markSent(taskId: String) {
        UserDefaults.standard.set(false, forKey: pendingKey(taskId))
    }

    static func clear(taskId: String) {
        UserDefaults.standard.removeObject(forKey: key(taskId))
        UserDefaults.standard.removeObject(forKey: pendingKey(taskId))
    }
}
