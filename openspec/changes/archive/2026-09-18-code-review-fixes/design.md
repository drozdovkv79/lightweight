## Context
Working tree after render-opt fix (ContentView, Models). 15 review points span input validation, render throttle, AX, tests.

## Goals
Fix critical bugs (#1 URL guard, #2 throttle, #3 submit cleanup, #4 panel init, #5 insert AX, #6 lazy parse). Add tests + commit Package.resolved.

## Decisions
- URL guard inline, no new abstraction.
- Throttle via @State timestamp (simple, no external lib).
- Monitor cleanup in ChatInputField onDisappear / before new.
- Lazy parse: ChatMessage init deferred, not background (keep MainActor simple).
- Tests minimal (XCTest) for URL guard + throttle.

## Risks
- Changing ChatMessage init affects all message creation (ChatViewModel.send, completeRequest).
- RichTextView reuse already applied; this change only validates.
