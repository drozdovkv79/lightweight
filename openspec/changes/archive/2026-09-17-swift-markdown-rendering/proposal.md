## Why

Ответы ИИ сейчас рендерятся кастомным парсером (`parseBlocks` + inline-only `AttributedString(markdown:)`), поэтому полноценный Markdown отображается неполно: нет надёжных заголовков, списков, таблиц, цитат и вложенных структур.

## What Changes

- Добавить зависимость `swift-markdown` (`https://github.com/swiftlang/swift-markdown`) в `LightweightChat/Package.swift`.
- Заменить кастомный рендеринг текста ассистента в `MessageBubble` на парсинг через `swift-markdown` (`Document(parsing:)` + обход `Markup`).
- Сохранить существующее визуальное поведение: выделение текста, цвета темы, фон код-блоков, stats-строка `response-stats` без изменений.
- Обрабатывать невалидный Markdown graceful fallback в plain text.

## Capabilities

### New Capabilities

- `markdown-rendering`: полноценный рендеринг Markdown ответов ассистента через `swift-markdown` в `MessageBubble`.

### Modified Capabilities

- Нет. `response-stats` не меняется: stats-строка остаётся отдельным `Text` под bubble.

## Impact

- `LightweightChat/Package.swift` — новая package dependency + target dependency.
- `LightweightChat/Sources/ContentView.swift` — `MessageBubble`, `parseBlocks`, `markdownAttributed`.
- Потенциальный рост времени сборки из-за новой зависимости; runtime-зависимостей вне SPM нет.
- Минимальная версия Swift/инструментария должна остаться совместимой со `swift-tools-version: 5.9` и macOS 14+.
