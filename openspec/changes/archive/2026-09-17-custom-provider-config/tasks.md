## 1. Configuration & Storage

- [x] 1.1 Добавить `provider_url` key в `UserDefaults` (чтение/запись) с fallback на `https://openrouter.ai/api/v1/chat/completions`
- [x] 1.2 Добавить поле для ввода URL провайдера в `SettingsView` и привязать к `UserDefaults`
- [x] 1.3 Добавить `loadModelsFromHF()` метод в `ChatViewModel` для вызова `hf models list --format json` через `Process()`

## 2. Dynamic Model Loading

- [x] 2.1 Реализовать парсинг вывода `hf models list --format json` в массив `LLMModel`
- [x] 2.2 Обработать ошибки: `hf` не найден, команда завершилась с ошибкой — silent fail, модели остаются пустыми
- [x] 2.3 Удалить статический `availableModels` массив из `Models.swift`, добавить `ModelLoader.parseHFModels`
- [x] 2.4 Добавить button "Refresh Models" в `SettingsView` для ручного рефреша

## 3. API Request URL Configuration

- [x] 3.1 Заменить хардкод `https://openrouter.ai/api/v1/chat/completions` в `ChatViewModel.streamResponse()` на чтение из `UserDefaults`
- [x] 3.2 Добавить fallback URL при пустом `provider_url`
- [x] 3.3 Обновить `UserDefaults` для хранения и чтения `provider_url`

## 4. UI & Validation

- [x] 4.1 Добавить ProgressView при вызове `hf models list`
- [x] 4.2 Добавить список текущих моделей в Settings
- [x] 4.3 Alert при ошибке `hf` CLI — скрыт при silent fail (models остаются пустыми)
- [x] 4.4 Добавить автоматическую привязку scheme к URL (`https://` если пусто)

## 5. Verification

- [x] 5.1 Запустить `swift build` и убедиться что код компилируется
- [x] 5.2 Проверить что `make run` открывает приложение с Settings содержащим поле для URL провайдера
- [x] 5.3 Проверить что `hf models list --format json` парсится в `LLMModel` массив через `ModelLoader.parseHFModels`
- [x] 5.4 Проверить fallback URL при пустом поле провайдера
