## 1. Dependency

- [x] 1.1 Добавить `swift-markdown` (`https://github.com/swiftlang/swift-markdown`) в `LightweightChat/Package.swift` (package + target dependency) — проверить `swift build --package-path LightweightChat` резолвит зависимость
- [x] 1.2 Проверить совместимость версии `swift-markdown` со `swift-tools-version: 5.9` и macOS 14 — проверить чистая сборка проходит без ошибок toolchain

## 2. Rendering

- [x] 2.1 Заменить `.text` ветку `MessageBubble` на рендер через `Document(parsing:)` + обход `Markup` (paragraph, heading, list, quote, codeBlock, inline code, emphasis, link) — проверить headings/lists/quotes/code отображаются структурно
- [x] 2.2 Сохранить выделение текста, цвета темы, фон код-блоков, alignment user/assistant — проверить визуально при обеих темах и selection включён
- [x] 2.3 Добавить fallback: при ошибке парсинга или пустом дереве показывать raw content как plain `Text` — проверить malformed Markdown не крашит и показывает текст
- [x] 2.4 Обработать незакрытый fence mid-stream (показывать plain accumulated text пока не парсится чисто) — проверить стриминг не мигает и не теряет текст

## 3. Cleanup & Verification

- [x] 3.1 Удалить мёртвый код (`parseBlocks`, `markdownAttributed`) после паритета рендера — проверить `swift build` проходит и grep не находит использований
- [x] 3.2 Проверить stats-строка `response-stats` без изменений под assistant сообщениями — проверить формат "model · prompt: N · completion: N · total: N · N.Ns" на месте
- [x] 3.3 Ручная проверка: headings, списки (вложенные), code blocks, quotes, inline code, links, malformed input — проверить всё по сценариям `specs/markdown-rendering/spec.md` (структурный рендер подтверждён скриншотом: divider рисуются)

## 4. ChatGPT-style оформление

- [x] 4.1 Добавить Highlightr (highlight.js) в `Package.swift` — проверить `swift build` резолвит и собирает; при несовместимости даунгрейд до карточки без подсветки
- [x] 4.2 Карточка код-блока: header (язык + Copy с подтверждением), Highlightr-тело, fallback plain mono — проверить Copy кладёт raw code в clipboard
- [x] 4.3 Проза sans: убрать `.monospaced` у контейнера чата, код/пилюли явно mono — проверить текст sans, код mono
- [x] 4.4 Пилюли inline-кода: проза через NSTextView (wrapping + фон пилюль + сплошное выделение вместо FlowLayout — решение зафиксировано) — проверить wrapping не ломается, пилюли в потоке текста
- [x] 4.5 Action row под assistant сообщениями: Copy (raw markdown), Like/Dislike локальные тоглы — проверить clipboard и состояния
- [x] 4.6 Ручная визуальная проверка против референса: headings, списки, код-карточки, пилюли, quotes, links, обе темы, stats на месте
- [x] 4.7 Крэш Highlightr (Bundle.module fatalError): Makefile не копировал SPM `*.bundle` в `.app` — добавить копирование в `bundle`/`dist-bundle`, проверить бандл в Resources, подпись, запуск
