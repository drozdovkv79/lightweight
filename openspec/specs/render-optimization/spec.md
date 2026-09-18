# render-optimization Specification

## Purpose

Reduce render lag and memory allocations in chat by caching parsed Markdown, isolating streaming updates, reusing text storage, and throttling scroll.

## Requirements

### Requirement: Markdown parse cached per message
The system SHALL store parsed Markdown (`Markdown.Document` or derived `[Markdown.Markup]`) in `ChatMessage` (lazy property) and SHALL reuse it across `ContentView` updates.

#### Scenario: Cache avoids parse on stream
- **WHEN** `streamingContent` updates
- **THEN** `LazyVStack` messages use cached parse result, `Markdown.Document` is not called

### Requirement: Streaming content isolated in separate view
The system SHALL render `streamingContent` in a standalone `StreamingBubble` view outside `LazyVStack`, so updates only affect that view.

#### Scenario: Streaming update does not trigger message re-render
- **WHEN** new chunk arrives
- **THEN** only `StreamingBubble` updates; `MessageRow` rows stay unchanged

### Requirement: RichTextView reuses text storage
The system SHALL reuse `NSTextStorage` and `NSLayoutManager` in `RichTextView` across updates instead of creating `Self.measuredHeight` with new instances.

#### Scenario: Height measurement does not allocate
- **WHEN** message text updates
- **THEN** `updateNSView` updates existing storage; `NSTextStorage` count does not grow per frame

### Requirement: Scroll to bottom throttled
The system SHALL throttle `scrollToBottom` calls (via `Task.sleep` or `DispatchQueue.main.asyncAfter`) so rapid `streamingContent` updates do not trigger continuous scroll calculations.

#### Scenario: Rapid updates do not block render
- **WHEN** stream delivers 10 chunks within 300ms
- **THEN** `proxy.scrollTo` executes at most once per 50ms
