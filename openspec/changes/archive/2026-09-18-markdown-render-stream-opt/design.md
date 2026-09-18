## Context

`ContentView` parses `Markdown.Document` per message in `body`. `RichTextView` creates new `NSTextStorage` for height measurement. `streamingContent` updates trigger full `LazyVStack`. `tableView` builds rows without cache.

## Goals

- Cache markdown parse per message.
- Reuse `NSTextStorage` in `RichTextView`.
- Isolate `streamingContent` render.
- Cache table cell text; throttle scroll.

## Non-Goals

- Change markdown parser library.
- Modify streaming protocol (`URLSession.bytes`).
- Add backend persistence.

## Decisions

- Cache in `ChatMessage` (`lazy var parsedBlocks`): avoids dictionary lookup overhead; aligns with value semantics.
- `RichTextView` reuse via `updateNSView`: minimal code change, keeps `NSViewRepresentable` interface.
- `StreamingBubble`: separate `View` outside `LazyVStack`; keeps `ContentView` simple.
- Table cell cache: `Array(headerCells)` + cached body rows; `fixedSize(vertical: true)` prevents height recalc.
- Scroll throttle: `Task.sleep(for: .milliseconds(50))` in `scrollToBottom`; simpler than `Debounced` object.

## Risks / Trade-offs

- Cache memory growth with very long chats → Mitigation: `lazy` only holds parsed array; original string stays. Acceptable for chat scale.
- `RichTextView` reuse requires careful `textStorage` reset → Mitigation: `setAttributedString(attributed)` in `updateNSView`, not new instance.
- `StreamingBubble` separation may lose scroll sync briefly → Mitigation: `streamingContent` updates trigger same throttle mechanism.

## Migration Plan

No migration. Pure optimization: no API changes, no user-facing feature change.
