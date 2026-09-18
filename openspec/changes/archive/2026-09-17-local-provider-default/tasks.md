## 1. Default URL Configuration

- [x] 1.1 Изменить default `provider_url` с `https://openrouter.ai/api/v1/chat/completions` на `http://127.0.0.1:8000/v1/chat/completions` в `ChatViewModel.apiEndpointURL`
- [x] 1.2 Обновить `SettingsView` placeholder text на `http://127.0.0.1:8000/v1/chat/completions`

## 2. Model Loading from Local Cache

- [x] 2.1 Изменить `loadModelsFromHF()` для вызова `hf cache ls --json` вместо `hf models list --format json`
- [x] 2.2 Обновить `ModelLoader.parseHFModels()` для парсинга `repo_id` из `hf cache ls` формата (убрать `model/` префикс)
- [x] 2.3 Обработать отсутствие `repo_id` в записях кэша — пропустить такие записи (guard в compactMap)

## 3. Cleanup

- [x] 3.1 Обновить `hf models list` references в AGENTS.md на `hf cache ls`

## 4. Verification

- [x] 4.1 Запустить `swift build` и убедиться что код компилируется
- [x] 4.2 Проверить что `hf cache ls --json` парсится корректно в `LLMModel` массив
- [x] 4.3 Проверить default URL `http://127.0.0.1:8000/v1/chat/completions`
- [x] 4.4 Проверить что `model/` префикс снимается из `repo_id`
