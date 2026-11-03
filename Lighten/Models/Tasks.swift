import Foundation

// Task shapes (docs/tz.md §6, packages/shared/src/tasks/types.ts). The app
// gets the payload only: the answer key never leaves the server.

enum TaskType: String, Codable {
    case fillBlank = "fill_blank"
    case multipleChoice = "multiple_choice"
    case trueFalse = "true_false"
    case reorder
    case errorCorrection = "error_correction"
    case essay
}

/// A piece of a fill-in text: plain text (it may hold "\n") or a gap.
enum FillBlankPart: Codable, Equatable {
    case text(String)
    case blank(Int)

    private enum Keys: String, CodingKey { case blank }

    init(from decoder: Decoder) throws {
        if let text = try? decoder.singleValueContainer().decode(String.self) {
            self = .text(text)
        } else {
            let container = try decoder.container(keyedBy: Keys.self)
            self = .blank(try container.decode(Int.self, forKey: .blank))
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let text):
            var container = encoder.singleValueContainer()
            try container.encode(text)
        case .blank(let index):
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(index, forKey: .blank)
        }
    }
}

struct FillBlankPayload: Codable, Equatable { let parts: [FillBlankPart] }
struct MultipleChoicePayload: Codable, Equatable { let question: String; let options: [String] }
struct TrueFalsePayload: Codable, Equatable { let statement: String }
/// Already shuffled: the right order is only in the key.
struct ReorderPayload: Codable, Equatable { let words: [String] }
struct ErrorCorrectionPayload: Codable, Equatable { let sentence: String }
struct EssayPayload: Codable, Equatable { let topic: String; let minWords: Int?; let maxWords: Int? }

enum TaskPayload: Equatable {
    case fillBlank(FillBlankPayload)
    case multipleChoice(MultipleChoicePayload)
    case trueFalse(TrueFalsePayload)
    case reorder(ReorderPayload)
    case errorCorrection(ErrorCorrectionPayload)
    case essay(EssayPayload)

    var blankCount: Int {
        guard case .fillBlank(let payload) = self else { return 0 }
        return payload.parts.reduce(0) { count, part in
            if case .blank = part { return count + 1 } else { return count }
        }
    }
}

enum SubmissionStatus: String, Codable {
    case draft, submitted
    case autoGraded = "auto_graded"
    case teacherGraded = "teacher_graded"
}

struct GradeItem: Codable, Equatable {
    let correct: Bool
    /// What the student gave, as text. Empty when nothing was given.
    let given: String
    /// The teacher's first accepted answer, shown next to the student's.
    let expected: String
}

struct GradeResult: Codable, Equatable {
    let score: Double
    let maxScore: Double
    let items: [GradeItem]
}

struct StudentSubmissionDTO: Codable, Equatable, Identifiable {
    let id: String
    let status: SubmissionStatus
    let answers: JSONValue?
    let score: Double?
    let maxScore: Double
    let details: GradeResult?
    let teacherComment: String?
    let submittedAt: String?
    let gradedAt: String?
    var dispute: DisputeDTO?
}

struct StudentTaskDTO: Codable, Equatable, Identifiable {
    let id: String
    let type: TaskType
    let position: Int
    let payload: TaskPayload
    let maxScore: Double
    var submission: StudentSubmissionDTO?

    private enum Keys: String, CodingKey {
        case id, type, position, payload, maxScore, submission
    }

    init(id: String, type: TaskType, position: Int, payload: TaskPayload, maxScore: Double,
         submission: StudentSubmissionDTO?) {
        self.id = id
        self.type = type
        self.position = position
        self.payload = payload
        self.maxScore = maxScore
        self.submission = submission
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(TaskType.self, forKey: .type)
        position = try c.decode(Int.self, forKey: .position)
        maxScore = try c.decode(Double.self, forKey: .maxScore)
        submission = try c.decodeIfPresent(StudentSubmissionDTO.self, forKey: .submission)
        switch type {
        case .fillBlank: payload = .fillBlank(try c.decode(FillBlankPayload.self, forKey: .payload))
        case .multipleChoice: payload = .multipleChoice(try c.decode(MultipleChoicePayload.self, forKey: .payload))
        case .trueFalse: payload = .trueFalse(try c.decode(TrueFalsePayload.self, forKey: .payload))
        case .reorder: payload = .reorder(try c.decode(ReorderPayload.self, forKey: .payload))
        case .errorCorrection: payload = .errorCorrection(try c.decode(ErrorCorrectionPayload.self, forKey: .payload))
        case .essay: payload = .essay(try c.decode(EssayPayload.self, forKey: .payload))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(position, forKey: .position)
        try c.encode(maxScore, forKey: .maxScore)
        try c.encodeIfPresent(submission, forKey: .submission)
        switch payload {
        case .fillBlank(let p): try c.encode(p, forKey: .payload)
        case .multipleChoice(let p): try c.encode(p, forKey: .payload)
        case .trueFalse(let p): try c.encode(p, forKey: .payload)
        case .reorder(let p): try c.encode(p, forKey: .payload)
        case .errorCorrection(let p): try c.encode(p, forKey: .payload)
        case .essay(let p): try c.encode(p, forKey: .payload)
        }
    }
}

/// A student's answer, in the shape POST /student/tasks/:id/answer expects
/// (apps/api/src/modules/learning/learning.dto.ts).
enum TaskAnswer: Equatable {
    /// One string per gap, in order.
    case fillBlank([String])
    /// Index into options.
    case multipleChoice(Int?)
    case trueFalse(Bool?)
    /// Indexes into payload.words, in the order the student put them.
    case reorder([Int])
    /// The fixed word alone or the whole fixed sentence.
    case errorCorrection(String)

    static func empty(for task: StudentTaskDTO) -> TaskAnswer? {
        switch task.payload {
        case .fillBlank: return .fillBlank(Array(repeating: "", count: task.payload.blankCount))
        case .multipleChoice: return .multipleChoice(nil)
        case .trueFalse: return .trueFalse(nil)
        case .reorder: return .reorder([])
        case .errorCorrection: return .errorCorrection("")
        case .essay: return nil
        }
    }

    /// The answer the student saved before, during an exam.
    static func saved(_ value: JSONValue?, for task: StudentTaskDTO) -> TaskAnswer? {
        guard let value else { return empty(for: task) }
        switch task.payload {
        case .fillBlank:
            let given = value.arrayValue?.map { $0.stringValue ?? "" } ?? []
            var answers = Array(repeating: "", count: task.payload.blankCount)
            for (i, text) in given.enumerated() where i < answers.count { answers[i] = text }
            return .fillBlank(answers)
        case .multipleChoice: return .multipleChoice(value.intValue)
        case .trueFalse: return .trueFalse(value.boolValue)
        case .reorder: return .reorder(value.arrayValue?.compactMap(\.intValue) ?? [])
        case .errorCorrection: return .errorCorrection(value.stringValue ?? "")
        case .essay: return nil
        }
    }

    /// Whether the "check" button can be pressed.
    func isComplete(for task: StudentTaskDTO) -> Bool {
        switch (self, task.payload) {
        case (.fillBlank(let values), _):
            return values.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        case (.multipleChoice(let index), _): return index != nil
        case (.trueFalse(let value), _): return value != nil
        case (.reorder(let order), .reorder(let payload)): return order.count == payload.words.count
        case (.errorCorrection(let text), _):
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default: return false
        }
    }

    var json: JSONValue {
        switch self {
        case .fillBlank(let values): return .array(values.map { .string($0) })
        case .multipleChoice(let index): return index.map { .number(Double($0)) } ?? .null
        case .trueFalse(let value): return value.map { .bool($0) } ?? .null
        case .reorder(let order): return .array(order.map { .number(Double($0)) })
        case .errorCorrection(let text): return .string(text)
        }
    }
}

struct AnswerBody: Encodable { let answer: JSONValue }
struct EssayTextBody: Encodable { let text: String }
struct DisputeBody: Encodable { let note: String }
struct LoginBody: Encodable { let login: String; let password: String }
struct PlaysUsed: Decodable { let playsUsed: Int }
