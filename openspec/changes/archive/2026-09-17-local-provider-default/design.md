## Context

Текущая реализация `custom-provider-config` использует:
- Default URL: `https://openrouter.ai/api/v1/chat/completions`
- Models: `hf models list --format json` (удалённый Hub)
- Парсинг: `id` поля из `hf models list` имеет формат `org/model`, `:nitro` добавляется

Новая реализация использует:
- Default URL: `http://127.0.0.1:8000/v1/chat/completions`
- Models: `hf cache ls --json` (локальный кэш)
- Парсинг: `repo_id` поля, содержит `model/` префикс который нужно снять

## Goals / Non-Goals

**Goals:**
- Сменить default URL на localhost
- Загружать модели из локального кэша `hf cache ls`
- Парсить `repo_id` из формата `model/org/name` → `org/name`

**Non-Goals:**
- Сохранить обратную совместимость с `hf models list` форматом
- Синхронизация кэша с Hub

## Decisions

**1. `hf cache ls --json` вместо `hf models list --format json`**
`hf cache ls` возвращает только локально скачанные модели. Это правильно для локального провайдера — показать только то, что уже есть на диске.

**2. `repo_id` как identifier**
В `hf cache ls` каждый объект имеет `id: "model/org/name"` и `repo_id: "org/name"`. Используем `repo_id` как чистый идентификатор модели.

**3. Default URL localhost**
Пользователь явно запросил `http://127.0.0.1:8000/v1/chat/completions`. Это типичный endpoint для ollama/lms/vllm.

**4. `:nitro` suffix сохраняется**
Даже для локальных моделей suffix `:nitro` добавляется, так как OpenRouter API совместим. Если провайдер не использует OpenRouter, suffix можно убрать — но это out of scope.

## Risks / Trade-offs

- [Risk] `hf cache ls` не установлен или не аутентифицирован → [Mitigation] Silent fail, alert shown
- [Risk] `repo_id` может быть пустым для некоторых записей → [Mitigation] Skip entries без `repo_id`
- [Trade-off] Локальные модели могут не поддерживать `:nitro` suffix — пользователь может ввести свой URL без suffix

## Open Questions

- Нужен ли отдельный default для `http://127.0.0.1:8000` vs `http://localhost:8000`?
- Следует ли убирать `:nitro` suffix если URL не OpenRouter?
