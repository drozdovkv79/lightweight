---
slug: fix-table-rendering
createdAt: 2026-09-17T21:46:32.642Z
---

## Why
Markdown tables display incorrectly in chat: header data missing, body cells show flat text, font oversized, no borders.

## What Changes
- Rewrite `tableView()` in ContentView.swift: parse `Markdown.Table.Head` for header, `Markdown.Table.Body` for rows
- Render header bold with background tint; body cells with borders
- Remove `.monospaced`; use `.system(size: fontSize)` to match prose

## Capabilities
### Modified Capabilities
- `markdown-rendering`: table rendering behavior updated (header bold, body bordered, regular font size)

## Impact
- LightWeightChat/Sources/ContentView.swift — tableView(), cells(), cellText()
