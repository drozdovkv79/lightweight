## Why

Code review 15 points: crash on bad URL, fake throttle, double submit, panel flash, insert fail, eager parse, double layout, spec mismatch, silent JSON encode, unbounded error stream, global error flash, AX bridge, multi-monitor panel, stale API key state, no tests, Package.resolved uncommitted.

## What Changes

1. URL guard + fail (ChatViewModel)
2. Real scroll throttle (ContentView @State)
3. ChatInputField monitor cleanup
4. SelectionAssistantPanel orderOut/init
5. insertSelection AX focused element fix
6. ChatMessage parsedBlocks lazy/background
7. RichTextView reuse (coordinator only)
8. StreamingBubble outside LazyVStack + spec fix
9. Request body guard
10. Error stream cap
11. insertionError local / clear
12. AX bridge robust
13. Panel multi-screen
14. Settings apiKey sync
15. Tests + Package.resolved commit

## Capabilities

### New Capabilities
- `security-input-validation`: URL/body validation, error caps, AX permission
- `render-performance-fix`: throttle, reuse, lazy parse, spec sync

### Modified Capabilities
- `provider-config`: bad URL guard (delta)
- `insert-back`: AX focused element (delta)
- `actionbar-overlay`: init position fix (delta)

## Impact
ChatViewModel, ContentView, ChatInputField, SettingsView, SelectionAssistantPanel, ChatMessage, Package.swift, Makefile.
