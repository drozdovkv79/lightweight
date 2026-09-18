## Context

Текущий код хранит жёсткодированный URL (`https://openrouter.ai/api/v1/chat/completions`) в `ChatViewModel.swift:78` и массив `availableModels` в `Models.swift`. API key уже хранится в Keychain через `Keychain.swift` и настраивается через `SettingsView.swift`. Приложение использует `URLSession.shared.bytes` для SSE-стриминга.

## Goals / Non-Goals

**Goals:**
- Вынести URL эндпоинта в GUI-настройку
- Загружать список моделей динамически через `hf models list`
- Сохранить существующий механизм SSE-стриминга и Keychain без изменений

**Non-Goals:**
- Поддержка нескольких провайдеров одновременно (один URL за раз)
- Кэширование списка моделей на диске (загрузка каждый раз из `hf`)
- Автоподбор моделей по задаче

## Decisions

**1. `hf` CLI как источник моделей вместо HTTP API**
Пользователь явно указал `hf` команду. `hf models list --format json` возвращает структурированный список. Реализация выполняет subprocess через `Process()` в Swift.

**2. Конфигурация через UserDefaults + Keychain**
URL провайдера хранится в `UserDefaults.standard` (как `provider_url`). API key остаётся в Keychain. Это минимальное изменение — `SettingsView` уже сохраняет данные через `@AppStorage` и `Keychain.save`.

**3. Fallback URL при пустом поле**
Если `provider_url` пустой — используется `https://openrouter.ai/api/v1/chat/completions`. Это сохраняет совместимость для существующих пользователей.

**4. Модели загружаются при старте приложения**
`ChatViewModel.init()` вызывает `loadModelsFromHF()` при запуске. Пользователь может ручной рефреш через Settings.

## Risks / Trade-offs

- [Risk] `hf` CLI не установлен → [Mitigation] Fallback к пустому списку моделей + alert пользователю
- [Risk] `hf models list` медленно выполняется → [Mitigation] Загрузка в фоновом Task, не блокирует UI
- [Risk] Формат вывода `hf` изменится между версиями → [Mitigation] Парсить только поля `id` и `label`, игнорировать остальное
- [Trade-off] Нет оффлайн-кэша моделей → каждый запуск требует `hf` CLI и сети

## Open Questions

- Нужен ли кэш моделей на случай отсутствия сети при следующем запуске?
- Нужен ли отдельный tab/section в Settings для провайдера vs остальные настройки?
