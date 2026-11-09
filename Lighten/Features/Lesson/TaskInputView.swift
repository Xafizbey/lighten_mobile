import SwiftUI

/// What a task asks, in one line.
func taskPrompt(_ task: StudentTaskDTO) -> String {
    switch task.type {
    case .fillBlank: return Strings.Tasks.fillBlank
    case .multipleChoice: return Strings.Tasks.choice
    case .trueFalse: return Strings.Tasks.trueFalse
    case .reorder: return Strings.Tasks.reorder
    case .errorCorrection: return Strings.Tasks.correction
    case .essay: return Strings.Essay.topic
    }
}

/// The input for one auto-checked task. The same view serves lessons and exams.
struct TaskInputView: View {
    let task: StudentTaskDTO
    @Binding var answer: TaskAnswer
    var disabled = false

    var body: some View {
        switch (task.payload, answer) {
        case (.fillBlank(let payload), .fillBlank(let values)):
            FillBlankInput(payload: payload, values: values, disabled: disabled) { answer = .fillBlank($0) }
        case (.multipleChoice(let payload), .multipleChoice(let selected)):
            VStack(alignment: .leading, spacing: 12) {
                MaterialText(payload.question, bold: true)
                ForEach(Array(payload.options.enumerated()), id: \.offset) { index, option in
                    OptionButton(text: option, selected: selected == index, english: true) {
                        answer = .multipleChoice(index)
                    }
                    .disabled(disabled)
                }
            }
        case (.trueFalse(let payload), .trueFalse(let selected)):
            VStack(alignment: .leading, spacing: 12) {
                MaterialText(payload.statement, bold: true)
                HStack(spacing: 12) {
                    OptionButton(text: Strings.Tasks.trueLabel, selected: selected == true, english: true) {
                        answer = .trueFalse(true)
                    }
                    OptionButton(text: Strings.Tasks.falseLabel, selected: selected == false, english: true) {
                        answer = .trueFalse(false)
                    }
                }
                .disabled(disabled)
            }
        case (.reorder(let payload), .reorder(let order)):
            ReorderInput(words: payload.words, order: order, disabled: disabled) { answer = .reorder($0) }
        case (.errorCorrection(let payload), .errorCorrection(let text)):
            VStack(alignment: .leading, spacing: 12) {
                MaterialText(payload.sentence, bold: true)
                Text(Strings.Tasks.correctionHint).font(Typo.caption).foregroundStyle(Palette.inkSoft)
                TextField(Strings.Tasks.correctionLabel, text: Binding(
                    get: { text },
                    set: { answer = .errorCorrection($0) }
                ))
                .font(Typo.material)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .fieldStyle()
                .disabled(disabled)
            }
        default:
            EmptyView()
        }
    }
}

/// One choice. Selected: blue border and tint, as on the site (green means "right").
struct OptionButton: View {
    let text: String
    let selected: Bool
    var english = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(english ? Typo.material : Typo.body)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: Metrics.radius)
                    .fill(selected ? Palette.blueTint : Palette.bg))
                .overlay(RoundedRectangle(cornerRadius: Metrics.radius)
                    .strokeBorder(selected ? Palette.blue : Palette.line, lineWidth: selected ? 3 : 2))
        }
        .buttonStyle(.plain)
        .animation(Motion.snappy, value: selected)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The text with numbered gaps, then one field per gap: on a phone a field
/// inside a line of text is too small for a thumb.
private struct FillBlankInput: View {
    let payload: FillBlankPayload
    let values: [String]
    let disabled: Bool
    let onChange: ([String]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MaterialText(textWithGaps)
            ForEach(values.indices, id: \.self) { i in
                VStack(alignment: .leading, spacing: 6) {
                    Text(fill(Strings.Tasks.blank, ["n": i + 1]))
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSoft)
                    TextField("", text: Binding(
                        get: { values[i] },
                        set: { value in
                            var next = values
                            next[i] = value
                            onChange(next)
                        }
                    ))
                    .font(Typo.material)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .fieldStyle()
                    .disabled(disabled)
                }
            }
        }
    }

    private var textWithGaps: String {
        payload.parts.map { part in
            switch part {
            case .text(let text): return text
            case .blank(let index): return " ___(\(index + 1))___ "
            }
        }
        .joined()
    }
}

/// Words to tap in order. Tapping a word in the sentence puts it back.
private struct ReorderInput: View {
    let words: [String]
    let order: [Int]
    let disabled: Bool
    let onChange: ([Int]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Strings.Tasks.reorderHint).font(Typo.caption).foregroundStyle(Palette.inkSoft)

            Text(Strings.Tasks.reorderLine).font(Typo.bodyBold)
            FlowLayout().callAsFunction {
                ForEach(order, id: \.self) { index in
                    chip(words[index], filled: true) {
                        onChange(order.filter { $0 != index })
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: Metrics.radius).strokeBorder(
                Palette.line, style: StrokeStyle(lineWidth: 2, dash: [6, 4])))

            Text(Strings.Tasks.reorderPool).font(Typo.bodyBold)
            FlowLayout().callAsFunction {
                ForEach(words.indices.filter { !order.contains($0) }, id: \.self) { index in
                    chip(words[index], filled: false) { onChange(order + [index]) }
                }
            }

            if !order.isEmpty && !disabled {
                Button(Strings.Tasks.reorderReset) { onChange([]) }
                    .font(Typo.caption)
            }
        }
        .animation(Motion.snappy, value: order)
    }

    private func chip(_ word: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(word)
                .font(Typo.material)
                .foregroundStyle(filled ? Palette.onBright : Palette.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(RoundedRectangle(cornerRadius: Metrics.radiusSmall)
                    .fill(filled ? Palette.yellow : Palette.bg))
                .overlay(RoundedRectangle(cornerRadius: Metrics.radiusSmall)
                    .strokeBorder(filled ? Color.clear : Palette.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}
