## Why
Tables in chat responses render as flat " | " joined text instead of a proper bordered table with bold header row.

## What Changes
- Rewrite tableView() in ContentView.swift to parse Markdown.Table.Head for header and Markdown.Table.Body for data rows
- Render header row with bold font and background tint
- Render body rows with regular font and cell borders
- Remove monospace font from table cells to match regular text size

## Capabilities

### New Capabilities
- table-rendering: proper bordered table with bold header rendered from markdown table syntax

### Modified Capabilities
- swift-markdown-rendering: tableView() function updated
