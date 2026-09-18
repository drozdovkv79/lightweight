## 1. Data Models

- [x] 1.1 Добавить `ResponseUsage` struct (promptTokens, completionTokens, totalTokens) в `Models.swift` — проверить что компилируется
- [x] 1.2 Добавить optional `usage: ResponseUsage?` поле в `APIResponse` — проверить декодинг с presence/absence usage
- [x] 1.3 Расширить `ChatMessage` полями: `promptTokens: Int?`, `completionTokens: Int?`, `totalTokens: Int?`, `responseTime: TimeInterval?`, `model: String?` — проверить что текущий код компилируется без изменений

## 2. Streaming Pipeline

- [x] 2.1 В `streamResponse()` засечь `Date()` перед `URLSession.shared.bytes` — вычислить `responseTime` после `[DONE]`
- [x] 2.2 В `streamResponse()` перед `break` по `[DONE]` декодировать последний chunk и извлечь `usage` — сохранить в локальную переменную
- [x] 2.3 Передать `usage`, `responseTime`, `model` в `completeRequest()` — расширить签名 метода
- [x] 2.4 В `completeRequest()` заполнить stats поля в `ChatMessage` перед append в `messages`

## 3. UI Display

- [x] 3.1 Добавить computed `statsLine` свойство в `ChatMessage` — формат "model · prompt: N · completion: N · total: N · N.Ns"
- [x] 3.2 В `ContentView` под `MessageBubble` для assistant сообщений добавить Text(statsLine) — мелкий шрифт, secondary цвет
- [x] 3.3 Не показывать stats для user сообщений и сообщений без stats

## 4. Verification

- [x] 4.1 Запустить `swift build` — убедиться что компилируется
- [ ] 4.2 Отправить запрос к серверу и проверить что stats отображается под ответом
- [ ] 4.3 Проверить что сервер без usage возвращает "—" вместо чисел
