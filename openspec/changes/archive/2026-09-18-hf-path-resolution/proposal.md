## Why

App shows `hf command failed: env: hf: No such file or directory` when launched from Finder/Dock (e.g. after copying to /Applications), even though `hf` is installed and on the shell PATH. GUI apps do not inherit the user's shell PATH — the spawn in `ChatViewModel.loadModelsFromHF()` uses `/usr/bin/env hf`, which resolves against the minimal GUI PATH (`/usr/bin:/bin:/usr/sbin:/sbin`) and fails. Model loading is therefore broken for the packaged app.

## What Changes

- Resolve the `hf` executable independently of the inherited GUI PATH: search common install locations (`/opt/homebrew/bin`, `/usr/local/bin`, `~/.local/bin`, `~/Library/Python/*/bin`, plus the process `PATH` env) for an executable `hf`.
- Add a manual override: `hf_binary_path` setting in UserDefaults (editable via Settings) that takes precedence over auto-discovery.
- Pass an augmented `PATH` environment to the spawned process so `hf`'s own subprocess expectations keep working.
- Improve the error message to state that `hf` was not found in the searched locations (and list them), instead of a bare `env:` error.

## Capabilities

### New Capabilities
- `hf-cli-integration`: Locating and invoking the `hf` CLI for local model cache listing, PATH-independent resolution, user override, and failure reporting.

## Impact

- `LightweightChat/Sources/ChatViewModel.swift` — `loadModelsFromHF()`: executable resolution + augmented environment.
- New small resolver (in `Models.swift` or own file) — pure function, testable.
- `LightweightChat/Sources/SettingsView.swift` — optional `hf_binary_path` override field.
- No network/API changes; `hf cache ls --json` output parsing unchanged.
