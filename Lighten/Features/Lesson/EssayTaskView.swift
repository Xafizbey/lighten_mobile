import SwiftUI

/// An essay: written here, kept as a draft, handed in once, scored by the teacher.
///
/// The draft is saved on the phone at every change and on the server every
/// 12 seconds (CLAUDE.md: every 10–15 seconds, both places). Without a
/// connection the text stays on the phone and goes out when the connection
/// comes back.
struct EssayTaskView: View {
    let task: StudentTaskDTO
    let canAnswer: Bool
    let onChange: (StudentSubmissionDTO) -> Void

    @State private var text = ""
    @State private var lastSent = ""
    @State private var saveState: SaveState = .idle
    @State private var confirm = false
    @State private var busy = false
    @State private var error: String?
    @Environment(\.scenePhase) private var scenePhase

    private enum SaveState { case idle, saving, saved, offline }

    private var payload: EssayPayload? {
        if case .essay(let p) = task.payload { return p }
        return nil
    }

    private var handedIn: Bool {
        guard let status = task.submission?.status else { return false }
        return status != .draft
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Essay.topic).font(Typo.caption).foregroundStyle(Palette.inkSoft)
            if let payload { MaterialText(payload.topic, bold: true) }
            if let limits = limitsText { Text(limits).font(Typo.caption).foregroundStyle(Palette.inkSoft) }

            if handedIn, let submission = task.submission {
                handedInView(submission)
            } else if canAnswer {
                editor
            } else {
                NoticeText(text: Strings.Lesson.readOnly)
            }
        }
        .onAppear(perform: restore)
        .task(id: task.id) { await autosaveLoop() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { Task { await saveDraft() } }
        }
    }

    private var editor: some View {
        let words = Format.countWords(text)
        return VStack(alignment: .leading, spacing: 10) {
            TextEditor(text: $text)
                .font(Typo.material)
                .frame(minHeight: 240)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Palette.bg))
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(Strings.Essay.placeholder)
                            .foregroundStyle(Palette.inkSoft)
                            .padding(.horizontal, 17)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: Metrics.radius).strokeBorder(Palette.line, lineWidth: 2))
                .onChange(of: text) { _, value in
                    EssayDraftStore.save(value, taskId: task.id)
                    if saveState == .saved { saveState = .idle }
                }

            HStack {
                Text(fill(Strings.Essay.words, ["n": words, "unit": plural(words, Strings.Units.word)]))
                Spacer()
                switch saveState {
                case .saving: Text(Strings.Essay.saving)
                case .saved: Text(Strings.Essay.saved)
                default: EmptyView()
                }
            }
            .font(Typo.caption)
            .foregroundStyle(Palette.inkSoft)

            if saveState == .offline { NoticeText(text: Strings.Essay.offline) }
            if let error { NoticeText(text: error, tone: .error) }

            Button(Strings.Essay.submit) { confirm = true }
                .buttonStyle(.primary)
                .disabled(busy || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .confirmationDialog(Strings.Essay.confirm, isPresented: $confirm, titleVisibility: .visible) {
                    Button(Strings.Essay.submit) { Task { await submit() } }
                    Button(Strings.Essay.cancel, role: .cancel) {}
                }
        }
    }

    private func handedInView(_ submission: StudentSubmissionDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if submission.status == .teacherGraded, let score = submission.score {
                Text(Strings.Essay.graded).font(Typo.bodyBold)
                Text(Format.score(score, of: submission.maxScore)).font(Typo.title)
                if let comment = submission.teacherComment, !comment.isEmpty {
                    Text(Strings.Essay.comment).font(Typo.caption).foregroundStyle(Palette.inkSoft)
                    Text(comment)
                }
                DisputeBox(submission: submission) { dispute in
                    var updated = submission
                    updated.dispute = dispute
                    onChange(updated)
                }
            } else {
                NoticeText(text: Strings.Essay.submitted)
            }
            Text(Strings.Essay.yourText).font(Typo.caption).foregroundStyle(Palette.inkSoft)
            Card { MaterialText(submission.answers?.stringValue ?? "") }
        }
    }

    private var limitsText: String? {
        guard let payload else { return nil }
        switch (payload.minWords, payload.maxWords) {
        case let (min?, max?): return fill(Strings.Essay.range, ["min": min, "max": max])
        case let (min?, nil): return fill(Strings.Essay.min, ["min": min])
        case let (nil, max?): return fill(Strings.Essay.max, ["max": max])
        default: return nil
        }
    }

    // MARK: - Draft

    private func restore() {
        guard !handedIn, text.isEmpty else { return }
        let server = task.submission?.answers?.stringValue ?? ""
        let local = EssayDraftStore.load(taskId: task.id)
        // The phone's copy is never older than the server's: it is saved first.
        text = local ?? server
        lastSent = server
    }

    private func autosaveLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(12))
            await saveDraft()
        }
    }

    private func saveDraft() async {
        guard canAnswer, !handedIn, text != lastSent else { return }
        let sending = text
        saveState = .saving
        do {
            let submission: StudentSubmissionDTO = try await APIClient.shared.put(
                "student/tasks/\(task.id)/draft", EssayTextBody(text: sending))
            lastSent = sending
            saveState = .saved
            onChange(submission)
        } catch APIError.network {
            saveState = .offline
        } catch {
            saveState = .idle
        }
    }

    private func submit() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            let submission: StudentSubmissionDTO = try await APIClient.shared.post(
                "student/tasks/\(task.id)/submit", EssayTextBody(text: text))
            EssayDraftStore.clear(taskId: task.id)
            onChange(submission)
        } catch let apiError as APIError {
            error = apiError.message
        } catch {}
    }
}

/// The essay draft on the phone, so a lost connection or a closed app loses nothing.
enum EssayDraftStore {
    private static func key(_ taskId: String) -> String { "essay-draft-\(taskId)" }

    static func save(_ text: String, taskId: String) {
        UserDefaults.standard.set(text, forKey: key(taskId))
    }

    static func load(taskId: String) -> String? {
        UserDefaults.standard.string(forKey: key(taskId))
    }

    static func clear(taskId: String) {
        UserDefaults.standard.removeObject(forKey: key(taskId))
    }
}
