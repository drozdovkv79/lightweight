## Why

Текущий URL провайдера и список моделей жёстко зашиты в код. Смена провайдера требует редактирования Swift source и пересборки. Пользователь не может быстро сменить LLM-провайдера или подобрать модели из локального Hugging Face.

## What Changes

- **Убрать** хардкод `https://openrouter.ai/api/v1/chat/completions` в `ChatViewModel.swift`
- **Добавить** GUI поле для настройки произвольного URL AI-провайдера в `SettingsView`
- **Добавить** GUI поле для выбора локального источника моделей через `hf` CLI (Hugging Face Hub)
- **Убрать** `availableModels` массив из `Models.swift` как единственный источник моделей — заменить на динамическую загрузку через `hf models list`
- **BREAKING**: Модели больше не фиксированы в коде; список определяется из локального Hugging Face cache/Hub
- **BREAKING**: URL эндпоинта теперь конфигурируемый через GUI

## Capabilities

### New Capabilities
- `provider-config`: Настройка URL AI-провайдера, хранение API key, динамическая загрузка моделей из локального Hugging Face через `hf` CLI

### Modified Capabilities
- (none)

## Impact

- `ChatViewModel.swift` — замена хардкода URL на чтение из конфигурации
- `Models.swift` — удаление `availableModels` или переход на динамическую загрузку
- `SettingsView.swift` — добавление полей для URL провайдера и выбора моделей
- `Keychain.swift` — расширение для хранения URL провайдера (опционально, может быть UserDefaults)
- Зависимость: `hf` CLI должен быть установлен (`brew install hf` или `curl -LsSf https://hf.co/cli/install.sh | bash`)
