## Context

See `proposal.md` (Why). Current state: toolbar has model `Menu` + Settings gear (`ContentView.swift`); `provider_url` lives in `UserDefaults` via `@AppStorage`, read by `ChatViewModel.apiEndpointURL`; no process management exists (models were loaded via one-shot `hf` calls). See `specs/mlx-server-control/spec.md` and `specs/provider-config/spec.md` for behavior.

Constraints: single executable target, macOS 14+, app sandbox off (local builds); servers bind port 8008 with OpenAI-compatible `/v1/chat/completions`.

## Goals / Non-Goals

**Goals:**
- One-tap server lifecycle tied to selected model, with visible state and logs.
- Chat works immediately after start (provider auto-switch).
- No orphaned server processes or retained GPU/RAM after stop or app quit.

**Non-Goals:**
- Health-check polling or readiness gates (log inspection covers it).
- Managing servers the app did not start, except clearing port-8008 leftovers on stop.
- Custom ports, token limits, or extra server flags in UI (fixed per proposal).

## Decisions

### New `ServerManager` observable object (not inside ChatViewModel)
Separate `ObservableObject` owned by `ContentView` (or `App`): `server: ServerKind` (`rapid-mlx`/`mlx_lm`, persisted), `isRunning`, `log: String`, `start(model:)`, `stop()`. Separation keeps chat streaming logic untouched; ChatViewModel only sees the resulting `provider_url`.
- Alternative: stuff into ChatViewModel (rejected — unrelated responsibilities, harder state).

### Process via `/usr/bin/env` + Pipe, output on background thread
Launch `Process` with `executableURL=/usr/bin/env`, arguments per server type; stdout+stderr merged into one `Pipe`, `readabilityHandler` appends to `@Published log` on main thread (log sizes are modest; cap stored log at ~200KB, drop oldest).
- Termination: `process.terminate()` then, after short grace, `SIGKILL` if still running. Leftover sweep on port 8008 via `lsof -ti:8008 | xargs kill -9` (best-effort, failures only logged).
- App quit: `stop()` from `AppDelegate.applicationWillTerminate` / `onDisappear` path so no orphan keeps RAM.

### Running state
`isRunning` = spawned `Process.isRunning`. No port probing: single source of truth avoids races with foreign processes. Start disabled while running (button shows stop icon); model/server changes while running do not restart — user stops first (log hints this).

### Log window as separate `Window`
SwiftUI `Window("Server Log", id:)` scene bound to shared manager, `TextEditor`-readonly or `ScrollView+Text` monospace with auto-scroll on `log` change. Separate window per user choice (not a sheet).
- Alternative: sheet (rejected — user chose separate window).

### Provider auto-switch
On successful spawn, write `http://127.0.0.1:8008/v1/chat/completions` to the same `provider_url` UserDefaults key ChatViewModel reads. No switch-back on stop (recorded: manual Settings change restores; avoids clobbering user URLs).

## Risks / Trade-offs

- [Risk] Binary missing in PATH (`mlx_lm.server`) → Mitigation: pre-flight `/usr/bin/env <bin>` existence check; clear log error, no spawn.
- [Risk] Port 8008 already taken by foreign process → Mitigation: start still attempted; server error surfaces in log; stop sweep only kills by port as documented.
- [Risk] Log growth over long sessions → Mitigation: 200KB ring cap.
- [Risk] `terminate()` ignored by server → Mitigation: SIGKILL fallback + port sweep.
- [Risk] Stop-while-streaming leaves chat request hanging → Mitigation: out of scope (user can Stop in chat); documented.

## Migration Plan

1. Add `ServerManager`, toolbar UI, log window; wire provider switch.
2. Build; manual: start/stop both servers, missing binary, log content, auto-switch, app-quit cleanup.
3. Rollback: revert new files + toolbar edits (no data migration; `provider_url` may retain 8008 value — harmless).

## Open Questions

None. All user choices resolved (binary form, auto-switch, separate window).
