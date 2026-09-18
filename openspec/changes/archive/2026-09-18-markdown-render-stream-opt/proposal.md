## Why

Markdown.Document parsing + RichTextView.NSTextStorage recreate per render → CPU/memory lag on long chats. streamingContent triggers full LazyVStack re-parse. tableView rebuilds HStack per cell.

## What Changes

- Cache Markdown.Document per message (lazy var parsedBlocks).
- Reuse NSTextStorage/NSLayoutManager in RichTextView.
- Isolate streamingContent in separate StreamingBubble view.
- Cache table cells by markup id; add fixedSize for rows.
- Add throttle/debounce to scrollToBottom.

## Capabilities

### New Capabilities
- `render-optimization`: Cache parsed markdown, isolate streaming render, reuse text storage, throttle scroll updates.

### Modified Capabilities
- `markdown-rendering`: Add requirement: parsed markdown SHALL be cached per message id, not re-parsed in body.
- `table-rendering`: Add requirement: table rows SHALL use fixed vertical size; cell text SHALL be cached by row index.

## Impact

`ContentView`, `MessageRow`, `MessageBubble`, `MarkdownBlockView`, `RichTextView`, `ChatMessage` (new lazy property).
