import Foundation

/// Russian plural forms: one, few, many, e.g. "день", "дня", "дней".
struct PluralForms: Equatable {
    let one: String
    let few: String
    let many: String

    init(_ one: String, _ few: String, _ many: String) {
        self.one = one
        self.few = few
        self.many = many
    }
}

/// Same rule as apps/web/lib/plural.ts.
func plural(_ n: Int, _ forms: PluralForms) -> String {
    let mod10 = abs(n) % 10
    let mod100 = abs(n) % 100
    if mod10 == 1 && mod100 != 11 { return forms.one }
    if (2...4).contains(mod10) && (mod100 < 12 || mod100 > 14) { return forms.few }
    return forms.many
}
