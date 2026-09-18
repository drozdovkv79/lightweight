## 1. Fixed palette

- [x] 1.1 Добавить константы палитры (bg #282C34, text #ABB2BF в Color и NSColor) — проверить константы доступны из ContentView/Settings/App
- [x] 1.2 Заменить все использования `backgroundTheme`/`foregroundColor`/`foregroundNSColor` на константы в `ContentView.swift` — проверить `swift build` проходит, визуально фон и текст One Dark
- [x] 1.3 Удалить `BackgroundTheme` enum, `backgroundThemeRaw` AppStorage, секцию пикера в `SettingsView.swift`, логику `colorScheme` в `App.swift` — проверить grep не находит `BackgroundTheme|background_theme|usesLightText`, build проходит

## 2. Compact stats

- [x] 2.1 Переработать `statsLine` в `Models.swift`: формат `↑N ↓M · X.X tok/s · Y.Ys`, tok/s = completion/responseTime, отсутствующие значения `—` — проверить юнит-проверкой строк для кейсов с/без usage
- [ ] 2.2 Проверить stats под ответом в аппе с usage и без usage (fallback `—`) — проверить визуально оба кейса

## 3. Verification

- [ ] 3.1 Ручная проверка: чат, settings (без пикера), input, код-карточки (фиолетовые keywords, зелёные strings), пилюли, stats — проверить всё по сценариям `specs/app-theme`, `specs/response-stats`, `specs/markdown-rendering`
