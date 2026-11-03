import Foundation

/// Every string of the app's interface. A copy of the student cabinet's
/// dictionary (apps/web/content/dictionary/ru.ts): when a text changes there,
/// change it here too.
///
/// With the student: «ты». No caps, no exclamation marks, no emoji. A mistake
/// never sounds like a failure: «Почти», «Вот как правильно». Numbers and dates
/// come from the API and go into {placeholders} through `fill`.
///
/// Section names stay English: that is how they sound in class.
enum Strings {
    static let brand = "Lighten"

    enum Units {
        static let point = PluralForms("балл", "балла", "баллов")
        static let lesson = PluralForms("урок", "урока", "уроков")
        static let word = PluralForms("слово", "слова", "слов")
        static let work = PluralForms("работа", "работы", "работ")
        static let time = PluralForms("раз", "раза", "раз")
        static let minute = PluralForms("минута", "минуты", "минут")
        static let task = PluralForms("задание", "задания", "заданий")
    }

    static func section(_ code: SectionCode) -> String {
        switch code {
        case .grammar: return "Grammar"
        case .listening: return "Listening"
        case .reading: return "Reading"
        case .exercise: return "Exercise"
        case .writing: return "Writing"
        case .speaking: return "Speaking"
        }
    }

    enum Nav {
        static let home = "Главная"
        static let progress = "Прогресс"
        static let account = "Профиль"
    }

    enum Login {
        static let title = "Вход"
        static let lede = "Логин и пароль тебе дал преподаватель."
        static let login = "Телефон или почта"
        static let loginHint = "Например, 0555 123 456"
        static let password = "Пароль"
        static let submit = "Войти"
        static let submitting = "Входим"
        static let teacherAccount =
            "Это аккаунт преподавателя. Кабинет преподавателя открывается на сайте."
    }

    enum Home {
        static let greeting = "Привет, {name}"
        static let noCourse =
            "Курс ещё не начался. Как только преподаватель добавит тебя в поток, здесь появятся уроки."
        static let accessClosed =
            "Доступ к урокам сейчас закрыт. Его открывает преподаватель после оплаты месяца. Если это ошибка, напиши преподавателю."
        static let accessUntil = "Доступ открыт до {date}"
        static let finished = "Все недели курса прошли. Результаты есть в прогрессе."
        static let checking = "На проверке у преподавателя: {n} {unit}"
        static let allWeeks = "Все недели курса"
        static let nextKick = "Дальше по плану · неделя {n}"
        static let nextText = "{title}. {n} {unit}."
        static let start = "Начать"
        static let continueLabel = "Продолжить"
        static let weekDoneKick = "Неделя {n}"
        static let weekDoneTitle = "Всё сдано"
        static let weekDoneText =
            "Задания этой недели сделаны. Можно пересмотреть материалы или подготовиться к живому занятию."
        static let toWeek = "Открыть неделю"
        static let soonKick = "Скоро старт"
        static let soonTitle = "Первая неделя"
        static let beforeStart = "Первая неделя откроется в понедельник, {date}"
        static let closedKick = "Доступ"
        static let closedTitle = "На паузе"
        static let thisWeek = "Разделы недели"
        static let tileDone = "готово"
        static let tileMaterial = "материал"
        static let tileLessons = "{done} из {total}"
        static let weekRow = "Неделя {n}"
        static let weekNow = "сейчас"
        static let weekOpensOn = "откроется {date}"
        static let weekDone = "уроков пройдено: {done} из {total}"
        static let weekClosed = "неделя прошла"
    }

    enum Week {
        static let title = "Неделя {n}"
        static let due = "До конца воскресенья, {date}"
        static let closed = "Неделя закрыта: задания можно посмотреть, но не сдать."
        static let notOpen = "Эта неделя ещё не открылась."
        static let empty = "В этой неделе пока нет уроков."
    }

    static func status(_ status: LessonStatus) -> String {
        switch status {
        case .notStarted: return "Не начат"
        case .inProgress: return "Начат"
        case .checking: return "Проверяется"
        case .done: return "Выполнен"
        }
    }

    static let statusMaterial = "Материал"
    static let score = "{score} из {max}"

    enum Lesson {
        static let material = "Материал"
        static let video = "Видео"
        static let openVideo = "Смотреть на YouTube"
        static let slides = "Презентация"
        static let slideOf = "Слайд {n} из {total}"
        static let audio = "Аудио"
        static let listen = "Слушать"
        static let pause = "Пауза"
        static let tasks = "Задания"
        static let taskOf = "Задание {n} из {total}"
        static let start = "К заданиям"
        static let readOnly = "Неделя закрыта: ответы уже не принимаются."
        static let noTasks = "В этом уроке нет заданий: только материал."
        static let check = "Проверить"
        static let checking = "Проверяем"
        static let next = "Дальше"
        static let toResult = "К результату"
        static let correct = "Верно"
        static let almost = "Почти. Вот как правильно:"
        static let yourAnswer = "Твой ответ"
        static let rightAnswer = "Правильно"
        static let empty = "нет ответа"
        static let oneAttempt =
            "Ответ на задание даётся один раз. Если не согласен с оценкой, скажи об этом на экране результата."
        static let saveError = "Не получилось отправить ответ. Проверь интернет и нажми ещё раз."
    }

    enum Tasks {
        static let fillBlank = "Впиши пропущенные слова"
        static let blank = "Пропуск {n}"
        static let choice = "Выбери один ответ"
        static let trueFalse = "Верно или неверно по тексту"
        static let trueLabel = "True"
        static let falseLabel = "False"
        static let reorder = "Составь предложение из слов"
        static let reorderPool = "Слова"
        static let reorderLine = "Твоё предложение"
        static let reorderHint =
            "Нажимай на слова по порядку. Нажми на слово в предложении, чтобы вернуть его."
        static let reorderReset = "Сначала"
        static let correction = "Найди ошибку и исправь её"
        static let correctionHint = "Напиши исправленное слово или всё предложение."
        static let correctionLabel = "Исправление"
    }

    enum Essay {
        static let topic = "Тема"
        static let words = "{n} {unit}"
        static let range = "Нужно от {min} до {max} слов"
        static let min = "Нужно не меньше {min} слов"
        static let max = "Нужно не больше {max} слов"
        static let placeholder = "Пиши здесь. Текст сохраняется сам."
        static let saved = "Сохранено"
        static let saving = "Сохраняем"
        static let offline = "Нет связи: текст сохранён на телефоне и уйдёт, когда связь появится."
        static let submit = "Сдать на проверку"
        static let confirm = "После сдачи текст нельзя будет изменить. Сдать?"
        static let submitted = "Сочинение у преподавателя на проверке. Оценка появится здесь."
        static let graded = "Оценка преподавателя"
        static let comment = "Комментарий"
        static let yourText = "Твой текст"
        static let cancel = "Отмена"
    }

    enum Result {
        static let title = "Результат"
        static let review = "Разбор"
        static let allRight = "Всё верно."
        static let dispute = "Не согласен с оценкой"
        static let disputeLabel = "Что не так с оценкой"
        static let disputeHint = "Например: «мой вариант тоже правильный, потому что…»"
        static let disputeSend = "Отправить преподавателю"
        static let disputeCancel = "Отмена"
        static let disputeSent = "Заявка у преподавателя. Ответ появится здесь."
        static let disputeResolved = "Преподаватель ответил"
        static let disputeNewScore = "Новая оценка: {score} из {max}"
        static let disputeSameScore = "Оценка осталась прежней."
    }

    /// The exam (docs/tz.md §10). A calm tone: just the time, no pressure.
    enum Exam {
        static let label = "Экзамен"
        static let intro = "{n} {taskUnit}, {minutes} {minuteUnit}"
        static let rules = [
            "Попытка одна: начать заново не получится.",
            "Время считается с момента, когда ты нажмёшь «Начать». Если связь пропадёт, время идёт дальше, а ответы сохраняются: просто открой экзамен снова.",
            "Ответы можно менять до конца. Верные ответы и баллы появятся после завершения.",
        ]
        static let plays = "Аудио можно прослушать {n} {unit}."
        static let start = "Начать экзамен"
        static let starting = "Начинаем"
        static let resume = "Вернуться к экзамену"
        static let finishedTitle = "Экзамен завершён"
        static let left = "Осталось {time}"
        static let taskOf = "Задание {n} из {total}"
        static let prev = "Назад"
        static let next = "Дальше"
        static let saved = "Ответ сохранён"
        static let saving = "Сохраняем"
        static let offline = "Нет связи: ответ сохранён на телефоне и уйдёт, когда связь появится."
        static let finish = "Завершить экзамен"
        static let finishConfirm = "Завершить экзамен? Ответы больше нельзя будет изменить."
        static let unanswered = "Без ответа: {n} {unit}."
        static let finishing = "Завершаем"
        static let timeUp = "Время вышло. Ответы, которые ты успел дать, засчитаны."
        static let listen = "Слушать"
        static let playsLeft = "Осталось прослушиваний: {n}"
        static let noPlays = "Прослушивания закончились."
        static let toResult = "К результату"
        static let cancel = "Отмена"
    }

    enum Progress {
        static let exams = "Экзамены"
        static let title = "Мой прогресс"
        static let lede = "Баллы за задания по неделям и разделам."
        static let total = "Всего"
        static let empty = "Пока здесь пусто: прогресс появится после первых заданий."
        static let week = "Неделя {n}"
    }

    enum Account {
        static let title = "Профиль"
        static let login = "Логин"
        static let level = "Уровень"
        static let noLevel = "преподаватель ещё не указал"
        static let group = "Группа"
        static let noGroup = "пока без группы"
        static let course = "Курс"
        static let forgot =
            "Логин и пароль выдаёт преподаватель. Если забудешь пароль или захочешь сменить логин, напиши преподавателю: он пришлёт новый."
        static let logout = "Выйти"
    }

    static let retry = "Ещё раз"

    private static let errors: [String: String] = [
        "exam_task": "Это задание экзамена.",
        "exam_not_started": "Экзамен ещё не начат.",
        "exam_finished": "Экзамен уже завершён.",
        "exam_time_up": "Время экзамена вышло.",
        "no_plays_left": "Прослушивания закончились.",
        "invalid_credentials": "Логин или пароль не подходят.",
        "too_many_attempts": "Слишком много попыток. Подожди 15 минут и попробуй снова.",
        "already_answered": "На это задание ты уже ответил.",
        "access_closed": "Доступ к урокам закрыт.",
        "module_closed": "Неделя закрыта: ответы уже не принимаются.",
        "module_not_open": "Эта неделя ещё не открылась.",
        "already_disputed": "Заявка по этому заданию уже отправлена.",
        "essay_empty": "Сначала напиши текст.",
        "already_submitted": "Сочинение уже сдано.",
        "network": "Нет связи с сервером. Проверь интернет.",
    ]
    static let unknownError = "Что-то пошло не так. Попробуй ещё раз."

    static func errorText(_ code: String?) -> String {
        guard let code, let text = errors[code] else { return unknownError }
        return text
    }
}

/// Puts values into "{name}" placeholders. Unknown placeholders stay as they are.
func fill(_ template: String, _ values: [String: CustomStringConvertible]) -> String {
    var result = template
    for (key, value) in values {
        result = result.replacingOccurrences(of: "{\(key)}", with: value.description)
    }
    return result
}
