## Why

Приложение по умолчанию использует OpenRouter API. Пользователь хочет использовать локальный LLM-сервер (ollama, lms, vllm) по адресу `http://127.0.0.1:8000/v1/chat/completions` и получать список моделей из локального кэша Hugging Face (`hf cache ls`), а не из удалённого Hub.

## What Changes

- **BREAKING**: URL провайдера по умолчанию изменён с `https://openrouter.ai/api/v1/chat/completions` на `http://127.0.0.1:8000/v1/chat/completions`
- **BREAKING**: Модели загружаются из `hf cache ls --json` вместо `hf models list --format json`
- Команда `hf cache ls` возвращает локальные кэшированные модели; парсинг использует `repo_id` без `model/` префикса
- `provider_url` по умолчанию в `UserDefaults` изменён

## Capabilities

### New Capabilities
- `local-provider-default`: Локальный URL по умолчанию и загрузка моделей из `hf cache ls`

### Modified Capabilities
- `provider-config`: Изменён default URL и источник моделей

## Impact
- `ChatViewModel.swift` — изменён `apiEndpointURL` default и `loadModelsFromHF()` команда
- `Models.swift` — `ModelLoader.parseHFModels()` обновлён для формата `hf cache ls`
- `SettingsView.swift` — default значение поля URL обновлено
- `build-release.sh` — не затронуто
