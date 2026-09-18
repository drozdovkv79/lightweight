## Why

Переключение цветовых тем больше не нужно: приложение фиксируется на одной палитре One Dark Pro, а строка статистики токенов слишком шумная (имя модели, total) — нужна компактная форма со скоростью генерации.

## What Changes

- Убрать переключение палитры: секция темы в Settings, `BackgroundTheme` enum и все ветвления `usesLightText`/`background_theme` в коде. **BREAKING** для сохранённого `background_theme` в UserDefaults (ключ игнорируется).
- Зафиксировать палитру One Dark Pro: фон #282C34, основной текст #ABB2BF, акценты #C678DD, строки #98C379.
- Компактная статистика под ответом: без имени модели и total; вх. токены `↑N`, исх. `↓M`; скорость `X.X tok/s` (completion/responseTime); время ответа `Y.Ys` как сейчас. Формат: `↑N ↓M · X.X tok/s · Y.Ys`, отсутствующие значения — `—`.

## Capabilities

### New Capabilities

- `app-theme`: фиксированная палитра One Dark Pro без переключения (фон, текст, акценты, строки).

### Modified Capabilities

- `response-stats`: компактный формат stats-строки (стрелки, tok/s, без модели и total).
- `markdown-rendering`: фиксированные цвета палитры вместо следования за темой (сценарий Theme and selection).

## Impact

- `LightweightChat/Sources/ContentView.swift` — удаление `BackgroundTheme`, фиксированные цвета, новый формат `statsLine` идёт из `Models.swift`.
- `LightweightChat/Sources/SettingsView.swift` — удаление секции выбора темы.
- `LightweightChat/Sources/App.swift` — удаление логики `colorScheme` от темы.
- `LightweightChat/Sources/Models.swift` — новый формат `statsLine`, расчёт tok/s.
- Highlightr-тема `atom-one-dark` уже соответствует One Dark (фиолетовые keywords, зелёные strings) — замена не требуется.
