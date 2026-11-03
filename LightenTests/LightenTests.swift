import XCTest
@testable import Lighten

final class PluralTests: XCTestCase {
    func testRussianForms() {
        let forms = Strings.Units.task
        XCTAssertEqual(plural(1, forms), "задание")
        XCTAssertEqual(plural(2, forms), "задания")
        XCTAssertEqual(plural(5, forms), "заданий")
        XCTAssertEqual(plural(11, forms), "заданий")
        XCTAssertEqual(plural(21, forms), "задание")
        XCTAssertEqual(plural(112, forms), "заданий")
        XCTAssertEqual(plural(0, forms), "заданий")
    }
}

final class FormatTests: XCTestCase {
    func testDayMonthDoesNotShift() {
        XCTAssertEqual(Format.dayMonth("2026-11-16"), "16 ноября")
    }

    func testMomentIsReadInBishkek() {
        // Monday 00:00 in Bishkek is Sunday 18:00 UTC.
        XCTAssertEqual(Format.dayMonth(moment: "2026-11-15T18:00:00.000Z"), "16 ноября")
    }

    func testScore() {
        XCTAssertEqual(Format.score(7), "7")
        XCTAssertEqual(Format.score(7.5), "7,5")
        XCTAssertEqual(Format.score(3, of: 10), "3 из 10")
    }

    func testCountdown() {
        XCTAssertEqual(Format.countdown(65), "1:05")
        XCTAssertEqual(Format.countdown(3725), "1:02:05")
        XCTAssertEqual(Format.countdown(-3), "0:00")
    }

    func testCountWordsLikeTheSite() {
        XCTAssertEqual(Format.countWords("  I don't like it — well-known fact. "), 6)
        XCTAssertEqual(Format.countWords(""), 0)
    }

    func testFill() {
        XCTAssertEqual(fill("{score} из {max}", ["score": 3, "max": 10]), "3 из 10")
        XCTAssertEqual(fill("{a} {b}", ["a": "x"]), "x {b}")
    }
}

final class DecodingTests: XCTestCase {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    func testTaskPayloads() throws {
        let json = """
        [
          {"id":"1","type":"fill_blank","position":1,"maxScore":2,"submission":null,
           "payload":{"parts":["The cat ",{"blank":0}," on the mat. It ",{"blank":1},"."]}},
          {"id":"2","type":"multiple_choice","position":2,"maxScore":1,"submission":null,
           "payload":{"question":"Pick","options":["a","b"]}},
          {"id":"3","type":"true_false","position":3,"maxScore":1,"submission":null,
           "payload":{"statement":"Yes"}},
          {"id":"4","type":"reorder","position":4,"maxScore":1,"submission":null,
           "payload":{"words":["is","This","fine"]}},
          {"id":"5","type":"error_correction","position":5,"maxScore":1,"submission":null,
           "payload":{"sentence":"He go home."}},
          {"id":"6","type":"essay","position":6,"maxScore":10,"submission":null,
           "payload":{"topic":"My town","minWords":80,"maxWords":null}}
        ]
        """
        let tasks = try decode([StudentTaskDTO].self, json)
        XCTAssertEqual(tasks.count, 6)
        XCTAssertEqual(tasks[0].payload.blankCount, 2)
        if case .fillBlank(let p) = tasks[0].payload {
            XCTAssertEqual(p.parts[1], .blank(0))
            XCTAssertEqual(p.parts[0], .text("The cat "))
        } else {
            XCTFail("fill_blank payload")
        }
        if case .essay(let p) = tasks[5].payload {
            XCTAssertEqual(p.minWords, 80)
            XCTAssertNil(p.maxWords)
        } else {
            XCTFail("essay payload")
        }
    }

    func testGradedSubmission() throws {
        let json = """
        {"id":"s","status":"auto_graded","answers":["sat","is"],"score":1,"maxScore":2,
         "details":{"score":1,"maxScore":2,"items":[
           {"correct":true,"given":"sat","expected":"sat"},
           {"correct":false,"given":"is","expected":"was"}]},
         "teacherComment":null,"submittedAt":"2026-11-16T10:00:00.000Z","gradedAt":null,"dispute":null}
        """
        let submission = try decode(StudentSubmissionDTO.self, json)
        XCTAssertEqual(submission.details?.items.count, 2)
        XCTAssertEqual(submission.answers, .array([.string("sat"), .string("is")]))
    }

    func testNestErrorCode() throws {
        let one = try decode(NestErrorBody.self, #"{"statusCode":409,"message":"already_answered"}"#)
        XCTAssertEqual(one.code, "already_answered")
        let list = try decode(NestErrorBody.self, #"{"statusCode":400,"message":["note must be a string"]}"#)
        XCTAssertEqual(list.code, "note must be a string")
        XCTAssertEqual(Strings.errorText("already_answered"), "На это задание ты уже ответил.")
        XCTAssertEqual(Strings.errorText("something_new"), Strings.unknownError)
    }
}

final class AnswerTests: XCTestCase {
    private let reorder = StudentTaskDTO(
        id: "r", type: .reorder, position: 1,
        payload: .reorder(ReorderPayload(words: ["is", "This", "fine"])), maxScore: 1, submission: nil)

    func testIndexesTravelAsWholeNumbers() throws {
        let body = AnswerBody(answer: TaskAnswer.reorder([1, 0, 2]).json)
        let text = String(decoding: try JSONEncoder().encode(body), as: UTF8.self)
        XCTAssertEqual(text, #"{"answer":[1,0,2]}"#)
    }

    func testCompleteness() {
        XCTAssertFalse(TaskAnswer.reorder([1]).isComplete(for: reorder))
        XCTAssertTrue(TaskAnswer.reorder([1, 0, 2]).isComplete(for: reorder))
        XCTAssertFalse(TaskAnswer.errorCorrection("  ").isComplete(for: reorder))
        XCTAssertFalse(TaskAnswer.multipleChoice(nil).isComplete(for: reorder))
    }

    func testSavedExamAnswerIsRestored() {
        let saved = TaskAnswer.saved(.array([.number(2), .number(0)]), for: reorder)
        XCTAssertEqual(saved, .reorder([2, 0]))
    }
}
