## 1. Markdown Cache

- [x] 1.1 Add `lazy var parsedBlocks: [Markdown.Markup]?` to `ChatMessage`; parse in init/update. Verify no `Markdown.Document` call in `MessageRow.body`.
- [x] 1.2 Modify `ContentView` to pass cached array to `MarkdownBlockContent`. Verify `LazyVStack` does not re-parse on `streamingContent` change.

## 2. Streaming Isolation

- [x] 2.1 Create `StreamingBubble` view; render `streamingContent` outside `LazyVStack`. Verify `streamingContent` update only changes bubble.

## 3. RichTextView Reuse

- [x] 3.1 Store `NSTextStorage` + `NSLayoutManager` in `RichTextView` `Context.coordinator`. Update `updateNSView`. Verify no new `NSTextStorage` per update.

## 4. Table Optimization

- [x] 4.1 Cache `headerCells` and `bodyRows` arrays in `MarkdownBlockView`. Add `.fixedSize(horizontal: false, vertical: true)` to rows. Verify table builds within 33ms.

## 5. Scroll Throttle + Verification

- [x] 5.1 Add `Task.sleep(for: .milliseconds(50))` throttle in `scrollToBottom`. Verify rapid stream updates trigger at most 1 scroll/50ms.
- [x] 5.2 Build `swift build`; run app; confirm no lag on long chat with 20+ assistant messages and tables.
