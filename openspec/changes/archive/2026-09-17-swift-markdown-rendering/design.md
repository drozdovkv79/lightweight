## Context

See `proposal.md` (Why). Current rendering: `MessageBubble.parseBlocks()` splits on ` ``` `, prose goes through `AttributedString(markdown:)` with `.inlineOnlyPreservingWhitespace`, code goes to a styled `Text`. No headings, lists, quotes, or block structure. See `specs/markdown-rendering/spec.md` for required behavior.

Constraints: SPM, `swift-tools-version: 5.9`, macOS 14+, single executable target; streaming updates throttled at 33ms.

## Goals / Non-Goals

**Goals:**
- Parse assistant Markdown into a real document tree and render block structure in SwiftUI.
- Keep bubble layout, theme colors, text selection, code styling, and stats line intact.
- Graceful plain-text fallback on parse failure.

**Non-Goals:**
- GitHub Flavored Markdown extensions (tables, task lists, strikethrough) beyond what the parser supports.
- Markdown editing, syntax highlighting by language, or link previews.
- Changing streaming throttle, networking, or stats logic.

## Decisions

### Parser: swift-markdown via SPM
Use `https://github.com/swiftlang/swift-markdown` as a package dependency (`Document(parsing:)` → `Markup` tree).
- Alternatives: keep `AttributedString(markdown:)` (rejected — inline-only, no block structure); embed WebView (rejected — heavy, breaks native selection/theme).
- Rationale: user-requested library; native parser; no runtime outside SPM.

### Rendering: Markup tree → SwiftUI views
Walk the `Markup` tree and map nodes to SwiftUI (`Text` for inline runs, dedicated views for heading/list/quote/codeBlock/paragraph). Replace only the `.text` branch inside `MessageBubble`; keep the bubble container, alignment, and stats `Text` untouched.
- Alternative: convert tree to one `AttributedString` (rejected — SwiftUI `Text` still can't express block layout like lists/quotes reliably).
- Inline styling (emphasis, inline code, links) maps to `AttributedString` runs inside each block's `Text`.

### Failure mode: plain-text fallback
If `Document(parsing:)` throws or the tree is empty, render raw `content` as plain selectable `Text`. Malformed input never drops the message.

### Streaming: parse on throttled update
Reuse the existing 33ms `streamingContent` path; each update re-parses accumulated text, falling back to plain text while a fence/block is still open. No change to throttle or networking.

### Highlighter: Highlightr (highlight.js)
Syntax highlighting needs many languages (models output anything), so use Highlightr (`https://github.com/raspu/Highlightr`) with a bundled dark theme and auto-detect, preferring the fence info string when highlight.js supports it.
- Alternative: Splash (rejected — Swift-only, mis-highlights other languages); hand-rolled regex (rejected — crude, unmaintainable).
- `highlight(_:as:)` returns `NSAttributedString`; convert to SwiftUI via `AttributedString(nsAttr)`. Set theme code font to Menlo 13 to match the card.
- If the package fails to resolve/build on this toolchain, downgrade to unhighlighted card and report — card, header, and Copy still ship.

### Code card layout
Header row: language label (fence info or "code") left, Copy button right with brief "Copied" confirmation. Body: highlighted `Text` (or plain mono fallback). Card keeps the existing subtle `foregroundColor.opacity(0.10)` background language.

### Inline code pills via FlowLayout
`Text` + `AttributedString` cannot paint per-run backgrounds, so paragraphs/headings become segment lists (`text` / `code`) rendered in a custom `Layout` (wrapping flow, macOS 14 API). Text segments are `Text(AttributedString)`; code segments are mono `Text` with horizontal/vertical padding, subtle background, rounded corners. Same point size keeps baselines aligned; tables keep single-`Text` cells (no pills there).

### Action row and clipboard
`NSPasteboard.general` for both Copy buttons (code card copies raw code, row copies raw message Markdown). Action row lives under assistant bubbles only: Copy, Like, Dislike as small secondary icon buttons; Like/Dislike are `@State` toggles in a new stateful row view, mutually exclusive.

### Prose font
Container default becomes proportional sans (remove `.monospaced` design); code paths already set mono explicitly. Stats line and input stay mono.

## Risks / Trade-offs

- [Risk] New SPM dependency increases clean-build time → Mitigation: pin a stable `from:` version; no other new deps.
- [Risk] Partial Markdown mid-stream parses oddly (unclosed fence/list) → Mitigation: detect unclosed fence / parse failure → show plain accumulated text until it parses cleanly.
- [Risk] GFM tables/task-lists may not render as tables → Mitigation: explicitly out of scope; content still shown as fallback text, no crash.
- [Risk] `swift-markdown` minimum tools version above 5.9 → Mitigation: verify at apply time; if incompatible, stop and surface before code changes.
- [Risk] Highlightr unmaintained or incompatible with Swift 6 toolchain → Mitigation: verify first; downgrade to unhighlighted card if it fails.
- [Risk] Highlighting long code blocks on every render costs CPU → Mitigation: chat-sized inputs; highlight once per view evaluation, no extra caching layer.
- [Risk] Custom FlowLayout baseline drift between sans pill neighbors → Mitigation: same point size everywhere; visually verified in manual check.

## Migration Plan

1. Add package + target dependency; `swift build` to resolve.
2. Replace `.text` branch rendering; keep `parseBlocks` code-branch until parity verified, then remove dead code.
3. Build + manual check: headings, lists, code, quotes, links, theme, selection, stats line.
4. Rollback: revert `Package.swift` + `ContentView.swift` (no data migration involved).

## Open Questions

None. Dependency version compatibility is verified as the first apply task.
