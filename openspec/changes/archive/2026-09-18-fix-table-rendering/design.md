## Context
Markdown table rendering broken: flat text, missing header data, oversized monospace font, no borders.

## Goals
- Fix table parsing: `Markdown.Table.Head` for header, `Markdown.Table.Body` for rows
- Header row bold with background tint; body rows normal weight with borders
- Font regular `.system(size: fontSize)`, no `.monospaced`
- Columns distributed with `minWidth: 60, maxWidth: .infinity`
