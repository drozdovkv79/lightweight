## Context

Текущий фолбэк восстановления окна — `newWindowForTab:` хак, в рантайме не работает (пользователь подтвердил): SwiftUI WindowGroup релизит NSWindow при ⌘W, `WindowRegistry.mainWindow` (weak) становится nil, создавать окно из AppDelegate нечем. `ChatInputField` уже имеет `@FocusState focused` (private) с автоФокусом — нужно наружное управление. Accessibility permission уже запрашивается для Selection Assistant (`checkPermissionPromptIfNeeded`). `AboutPanel.show()` существует в App.swift. Tray click сейчас — `statusItemClicked` → `activateMainWindow()`.

## Goals / Non-Goals

**Goals:**
- Окно переживает ⌘W — восстановление тем же окном, без recreation-хаков.
- Контекстное меню tray: About…, Quit (правый клик), левый клик — как раньше.
- Глобальный хоткей Cmd+Ctrl+Opt+<любая клавиша> → окно + фокус в prompt input, без перехвата события.

**Non-Goals:**
- Кастомизация хоткея в Settings (фиксированная комбинация).
- Меню на левом клике / подменю tray.
- Перехват/глушение hotkey-события (listen-only).
- Отдельная TCC permission для хоткея (переиспользуем Accessibility).

## Decisions

- **Корень fix'а восстановления: `window.isReleasedWhenClosed = false`** в `WindowAccessor.makeNSView`. После ⌘W окно остаётся в `NSApp.windows` (hidden), registry (weak) валиден, `makeKeyAndOrderFront` возвращает его. Удалить `newWindowForTab:` фолбэк из `activateMainWindow` — становится мёртвым кодом. Альтернатива ( recreating через openWindow из ContentView) не работает: при закрытом окне листенеров нет; держать невидимое окно-якорь — усложнение.
- **Контекстное меню: `sendAction(on: [.leftMouseUp, .rightMouseUp])` + разбор `NSApp.currentEvent`** в `statusItemClicked`. Right-click → присвоить `statusItem.menu = menu`, `button.performClick(nil)` (откроет меню), затем `menu = nil` обратно (вернуть click-поведение). Меню строится каждый раз (`menuNeedsUpdate` не нужен, два статичных пункта). Пункты: `About…` → `AboutPanel.show()`; `Quit` → `NSApp.terminate(nil)`. Английские тайтлы — язык приложения английский (Assumption: юзер описал суть по-русски).
- **Глобальный хоткей: listen-only CGEventTap** (`CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap, options: .listenOnly, eventsOfInterest: keyDown mask)`). Почему не `NSEvent.addGlobalMonitorForEvents(.keyDown)`: тот требует отдельную TCC permission «Input Monitoring» (отдельный prompt, прошлый catch-22). CGEventTap listen-only работает под тем же Accessibility permission, который уже выдан. Tap возвращает event без изменений (не глотаем). Callback: проверка `event.flags` содержит `.maskControl + .maskAlternate + .maskCommand` (и НЕ `.maskSecondaryFn`), keyDown от немодификатора → `DispatchQueue.main.async { activateMainWindow(); post .focusPromptInput }`. Tap создаётся при launch; если `tapCreate` вернул nil (нет permission) — ретрай при выдаче permission (хук в существующий `checkPermissionPromptIfNeeded` через колбэк/уведомление). Модификатор-only press не генерирует keyDown → сценарий «ignored» бесплатно.
- **Фокус в prompt: `Notification.Name.focusPromptInput`** → `ChatInputField.onReceive { focused = true }`. Вызов после `activateMainWindow()` (окно должно стать key до фокуса). Порядок в хендлере хоткея: activate → post notification (async main).
- **Новый файл `Sources/GlobalActivationMonitor.swift`**: enum/class с `start(onActivate:)`, `stop()`; хранит `CFMachPortRef` + run loop source; AppDelegate владеет инстансом.

## Risks / Trade-offs

- [`isReleasedWhenClosed = false` удерживает память окна после ⌘W] → одно окно, единицы МБ; осознанный trade-off против ненадёжного recreation.
- [CGEventTap listen-only без permission молча не работает] → tapCreate вернёт nil при отсутствии Accessibility; ретрай при grant; поведение задокументировано в спеке.
- [`newWindowForTab` удаление] → фолбэк больше не нужен: окно не умирает. Если где-то окно всё же убьётся (crash restore) — tray click вернёт фокус на любое `canBecomeMain` окно; WindowGroup recreation остаётся недоступным — приемлемо.
- [Hotkey срабатывает на любые клавиши с тремя модификаторами — включая намеренные шорткаты пользователя в других приложениях] → комбинация из трёх модификаторов редко занята; мы не глотаем событие, чужие шорткаты продолжают работать; активация — additive.
- [Right-click detection через `NSApp.currentEvent`] → стандартный приём для status item; `performClick(nil)` для открытия меню — известный паттерн.

## Migration Plan

Без storage/entitlements изменений. Rollback = revert.

## Open Questions

None.
