## Design

### Approach
Replace HStack with "|" joined text in tableView() with proper HStack-based grid:
- Parse Markdown.Table.Head for header cells
- Parse Markdown.Table.Body for data rows
- Each cell uses Text with frame(minWidth: 60, maxWidth: .infinity) for proportional column widths
- Header row: bold, background foregroundColor.opacity(0.12), border stroke
- Body cells: regular weight, border stroke
- Font: .system(size: fontSize) (no .monospaced)

### Files Changed
- LightweightChat/Sources/ContentView.swift — tableView(), cells(of()), cellText()
