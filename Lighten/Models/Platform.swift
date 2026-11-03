import Foundation

// What the API returns to the student cabinet. Mirrors
// packages/shared/src/platform.ts: keep the two in step. Dates travel as
// strings: 'YYYY-MM-DD' for a day, ISO 8601 for a moment.

struct MeDTO: Codable, Equatable {
    let id: String
    let name: String
    let login: String
    let role: UserRole
}

enum UserRole: String, Codable {
    case student, teacher
}

/// The six sections, in the brief's order (packages/shared/src/school.ts).
enum SectionCode: String, Codable, CaseIterable, Identifiable {
    case grammar, listening, reading, exercise, writing, speaking
    var id: String { rawValue }
}

enum ModuleState: String, Codable {
    case upcoming, open, closed
}

enum LessonStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case checking
    case done
}

struct ScoreDTO: Codable, Equatable {
    let score: Double
    let maxScore: Double
}

struct SectionProgressDTO: Codable, Equatable, Identifiable {
    let section: SectionCode
    let score: Double
    let maxScore: Double
    let lessonsTotal: Int
    let lessonsDone: Int
    var id: SectionCode { section }
}

struct StudentModuleDTO: Codable, Equatable, Identifiable {
    let id: String
    let position: Int
    let title: String
    let state: ModuleState
    let opensAt: String
    let closesAt: String
    let lastDay: String
    let sections: [SectionProgressDTO]
}

struct StudentHomeDTO: Codable, Equatable {
    struct Access: Codable, Equatable {
        let open: Bool
        let until: String?
    }

    struct NextLesson: Codable, Equatable {
        let id: String
        let title: String
        let section: SectionCode
        let taskCount: Int
        let status: LessonStatus
    }

    let name: String
    let level: String?
    let groupName: String?
    let courseTitle: String?
    let startsOn: String?
    let access: Access
    let current: StudentModuleDTO?
    let next: StudentModuleDTO?
    let weeks: [StudentModuleDTO]
    let nextLesson: NextLesson?
    let checking: Int
}

struct StudentLessonSummaryDTO: Codable, Equatable, Identifiable {
    let id: String
    let section: SectionCode
    let position: Int
    let title: String
    let status: LessonStatus
    let taskCount: Int
    let isExam: Bool
    let score: Double
    let maxScore: Double
}

struct StudentModuleDetailDTO: Codable, Equatable, Identifiable {
    let id: String
    let position: Int
    let title: String
    let state: ModuleState
    let opensAt: String
    let closesAt: String
    let lastDay: String
    let sections: [SectionProgressDTO]
    let lessons: [StudentLessonSummaryDTO]
}

enum ExamState: String, Codable {
    case notStarted = "not_started"
    case running
    case finished
}

/// The exam side of a lesson. The timer is the server's: the app only shows it.
struct StudentExamDTO: Codable, Equatable {
    let minutes: Int
    let audioPlays: Int?
    let state: ExamState
    let taskCount: Int
    let startedAt: String?
    let expiresAt: String?
    let finishedAt: String?
    /// The server's clock when the answer was made, to correct the phone's.
    let now: String
    let playsUsed: Int
}

struct SlideDTO: Codable, Equatable, Identifiable {
    let fileId: String
    let width: Double
    let height: Double
    var id: String { fileId }
}

struct StudentLessonDTO: Codable, Equatable, Identifiable {
    struct ModuleRef: Codable, Equatable {
        let id: String
        let position: Int
        let title: String
        let state: ModuleState
        let lastDay: String
    }

    let id: String
    let title: String
    let section: SectionCode
    let body: String?
    let videoUrl: String?
    let audioUrl: String?
    let slides: [SlideDTO]
    let module: ModuleRef
    let canAnswer: Bool
    let exam: StudentExamDTO?
    var tasks: [StudentTaskDTO]
}

struct StudentProgressDTO: Codable, Equatable {
    struct Module: Codable, Equatable, Identifiable {
        let id: String
        let position: Int
        let title: String
        let state: ModuleState
        let sections: [SectionProgressDTO]
        let total: ScoreDTO
    }

    struct Exam: Codable, Equatable, Identifiable {
        let lessonId: String
        let title: String
        let section: SectionCode
        let modulePosition: Int
        let score: Double
        let maxScore: Double
        var id: String { lessonId }
    }

    let modules: [Module]
    let total: ScoreDTO
    let exams: [Exam]
}

struct DisputeDTO: Codable, Equatable, Identifiable {
    let id: String
    let studentNote: String
    let scoreBefore: Double
    let newScore: Double?
    let teacherNote: String?
    let resolvedAt: String?
    let createdAt: String
}
