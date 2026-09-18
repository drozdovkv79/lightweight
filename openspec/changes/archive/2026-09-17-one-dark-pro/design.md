## Context

See `proposal.md` (Why). Current state: `BackgroundTheme` enum (11 themes) drives `backgroundTheme.color`, `foregroundColor` (green/black switch), `foregroundNSColor`, `App.colorScheme`, and a Settings picker. Stats format lives in `ChatMessage.statsLine` (`Models.swift`). See `specs/` deltas for required behavior.

## Goals / Non-Goals

**Goals:**
- One fixed palette, zero theme branches in UI code or settings.
- Compact stats with tok/s.
- Keep Highlightr `atom-one-dark` (already One Dark: purple keywords, green strings).

**Non-Goals:**
- New Highlightr theme or custom CSS.
- Migrating/deleting the orphaned `background_theme` UserDefaults key (ignored, harmless).
- Changing streaming, networking, or stats data collection (only display format).

## Decisions

### Palette as constants, enum deleted
Define fixed `Color`/`NSColor` constants (`#282C34` bg, `#ABB2BF` text) and replace all `backgroundTheme.*` / `foregroundColor` / `foregroundNSColor` usages. Delete `BackgroundTheme` enum, `backgroundThemeRaw` AppStorages, Settings picker section, and `App.colorScheme` theme logic.
- Alternative: keep enum with single case (rejected — dead abstraction, user explicitly asked removal from code too).

### Stats format in `statsLine`
`"↑\(prompt) ↓\(completion) · \(tok/s) · \(time)s"`, each field independently `—` when data missing. tok/s = `completionTokens / responseTime`, one decimal, only when both present and time > 0. Arrow mapping (recorded assumption): вх/prompt = ↑ (upload), исх/completion = ↓ (download).

### Highlightr untouched
`atom-one-dark` already renders keywords purple and strings green on dark background — matches requested accents without code changes. Code card background stays subtle text-color overlay; header/secondary UI uses system secondary.

## Risks / Trade-offs

- [Risk] Hardcoded hex in several views drifts over time → Mitigation: single constants location, all usages reference it.
- [Risk] tok/s division by ~0 time → Mitigation: guard `responseTime > 0`, else "—".
- [Risk] Old `background_theme` value confuses future debugging → Mitigation: documented as intentionally ignored; no migration.

## Migration Plan

1. Add palette constants; replace usages file by file; delete enum, picker, colorScheme logic.
2. Rework `statsLine` + verify format strings.
3. Build, visual check of chat/settings/input/code cards, stats line with and without usage data.
4. Rollback: revert the 4 source files (no data migration).

## Open Questions

None.
