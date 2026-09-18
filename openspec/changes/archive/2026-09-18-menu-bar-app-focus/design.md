## Context

`AppDelegate` (App.swift) уже владеет lifetime-объектами (triggerMonitor, coordinator) и создаёт их в `applicationDidFinishLaunching` — туда же встаёт статус-айтем. Активация сейчас используется точечно в `AboutPanel.show()` (`NSApp.activate(ignoringOtherApps: true)`), общего хелпера нет. Главное окно — SwiftUI `WindowGroup` (`ContentView`); `WindowAccessor` уже существует для доступа к NSWindow. Путь selection-dispatch: coordinator/panel → `.selectionAssistantDirect` → `App.swift` onReceive → `chatVM.send(selectionSnapshot:template:)`. Точка вставки активации — этот onReceive, покрывает оба сценария (direct и preset).

## Goals / Non-Goals

**Goals:**
- Один клик из любого приложения → окно поверх, фокус в нём.
- Активация в момент dispatch промпта — до стриминга ответа.
- Общий хелпер активации, без дублирования в двух местах.

**Non-Goals:**
- Меню у статус-айтема (только клик-действие).
- Скрытие dock-иконки / LSUIElement (приложение остаётся обычным).
- Настройка "показывать иконку в меню" (всегда показывается).
- Активация при обычной отправке из самого приложения (уже в фокусе).

## Decisions

- **Иконки — предоставленные файлы**: app icon = `Resources/locy_icon.jpeg` → одноразовая генерация `AppIcon.icns` через builtin `sips` (resize в iconset-размеры 16–1024) + `iconutil -c icns`; результат коммитится, Info.plist остаётся с `CFBundleIconFile = AppIcon`. Tray = `Resources/locy_tray.jpeg`, бандлится как ресурс; JPEG без альфы → runtime circular mask: NSImage 18×18, CoreGraphics clip по кругу, углы прозрачные — иначе в светлом меню-баре будет чёрный квадрат. `isTemplate = false` (полноцветная круглая иконка). Альтернативы: `NSApp.applicationIconImage` (не та картинка), template-рендер (обесцветит бренд), build-time PNG с альфой через внешние тулы (не builtin) — отклонены.
- **Активация — хелпер в AppDelegate**: `func activateMainWindow()`: `NSApp.activate(ignoringOtherApps: true)`; поиск главного окна — `NSApp.windows.first { $0.canBecomeMain && $0.isVisible }`; если нет видимого (закрыто) — пересоздать через нельзя из AppDelegate напрямую (SwiftUI WindowGroup) → используем WindowAccessor-паттерн: окно SwiftUI живёт в `NSApp.windows`; при закрытом окне WindowGroup пересоздаётся только по user gesture... Решение: запретить закрытие главного окна в oblivion — SwiftUI `WindowGroup` при ⌘W закрывает окно; клик по статус-айтему должен его вернуть. Надёжный приём: держать `WindowAccessor` (уже есть в ContentView) который сохраняет ссылку на NSWindow в статический registry; хелпер: если окно есть в registry → `makeKeyAndOrderFront(nil)`; если нет → `NSApp.sendAction(#selector(NSWindow.newWindowForTab(_:)), to: nil, from: nil)` НЕ подходит. Практичный вариант для macOS 14: `NSApp.activate` + если окно не найдено — post `Notification` который SwiftUI-слой ловит и открывает через `openWindow` environment (EnvironmentObject/`@Environment(\.openWindow)`) — доступно в ContentView. Итог: хелпер сначала пробует registry-окно; фолбэк — NotificationCenter → `.onReceive` в ContentView вызывает `openWindow(id:)` + фокус.
- **Активация при dispatch**: в `App.swift` onReceive `.selectionAssistantDirect` после `chatVM.send(...)` вызвать `appDelegate.activateMainWindow()`. Доступ к AppDelegate из body — `@NSApplicationDelegateAdaptor` уже есть в scope.
- **Задержка активации**: активировать сразу (не ждать ответа) — пользователь видит начало стрима. Dispatch идёт из global-монитора — активация из не-activ процесса требует `ignoringOtherApps: true`, что и делаем.

## Risks / Trade-offs

- [Статус-айтем держит app alive при закрытом окне] → обычное поведение для GUI-приложений с dock; приёмлемо.
- [Закрытое ⌘W окно] → фолбэк через `openWindow` покрывает; риск минимален.
- [Активация может быть заблокирована macOS при активном fullscreen другого приложения] → окно откроется поверх при выходе из fullscreen; known macOS behavior.
- [JPEG tray icon без альфы] → runtime circular mask решает; mask рисуется один раз при создании image, кэшируется в свойстве AppDelegate.
- [sips/iconutil генерация icns] → builtin macOS, без внешних зависимостей; делается один раз, артефакт коммитится.

## Migration Plan

Без миграций: нет нового storage/entitlements. Rollback = revert.

## Open Questions

None.
