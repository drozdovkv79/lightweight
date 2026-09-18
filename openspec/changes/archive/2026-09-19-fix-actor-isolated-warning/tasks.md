## 1. Actor isolation fix

- [ ] 1.1 Обернуть `chatVM.send(selectionSnapshot:template:)` в `Task { @MainActor in }` в `AppDelegate` (App.swift:79)
- [ ] 1.2 `swift build` — zero warnings, zero errors
- [ ] 1.3 `swift test` — passing
