## Context

Текущий streaming pipeline: `streamResponse()` читает SSE chunks, декодит `APIResponse`, накапливает `delta.content`. После `[DONE]` вызывается `completeRequest()`. Модель `APIResponse` не содержит `usage` поле. `ChatMessage` хранит только `role` и `content`.

## Goals / Non-Goals

**Goals:**
- Парсить `usage` из последнего streaming chunk
- Замерять время ответа (от request до `[DONE]`)
- Отображать stats под сообщениями ассистента

**Non-Goals:**
- Кумулятивная статистика за сессию / историю
- Графики, экспорт, сохранение stats
- Валидация/лаймиты на токены

## Decisions

### 1. Расширить `APIResponse` вместо отдельного парсинга
Добавить optional `usage` поле в `APIResponse`. Не требует нового endpoint или отдельного запроса — данные уже приходят в streaming chunks.

**Альтернатива**: отдельный non-streaming запрос после ответа — проще, но двойной запрос, задержка.

### 2. Собирать usage из последнего chunk
В `streamResponse()` перед `break` на `[DONE]` — декодировать chunk и извлекать `usage`. Если usage нет — показать "—".

**Альтернатива**: accumulation через отдельный флаг — сложнее, хрупко.

### 3. Хранить stats в ChatMessage
Расширить `ChatMessage` optional полями: `promptTokens`, `completionTokens`, `totalTokens`, `responseTime`, `model`. Не ломает существующий код — все optional.

### 4. Замер времени через `Date`
Засечь `Date()` перед `URLSession.shared.bytes`, вычислить разницу после `[DONE]`. Просто, надёжно.

## Risks / Trade-offs

- [Нет usage от сервера] → отображать "—" вместо чисел
- [Доп. поля в ChatMessage] →扩展会 модель, но все optional — обратно совместимо
- [Формат usage отличается от OpenAI] → сервер OpenAI-compatible, формат совпадает
