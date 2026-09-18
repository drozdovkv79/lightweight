## Context

`ChatViewModel.loadModelsFromHF()` (ChatViewModel.swift:63-65) spawns `/usr/bin/env hf cache ls --json`. Child inherits the app's environment; Finder-launched GUI apps get minimal PATH, so `env hf` fails with `env: hf: No such file or directory`. `ModelLoader.parseHFModels` only parses output — untouched. `hfError` is already surfaced in Settings UI. User confirmed `hf` is on their shell PATH (terminal works).

## Goals / Non-Goals

**Goals:**
- Model loading works regardless of how the app was launched.
- Deterministic, testable path resolution.
- Escape hatch for exotic installs (override setting).

**Non-Goals:**
- Bundling `hf` or its Python runtime with the app.
- Invoking `hf` through a login shell (slow, output pollution from shell rc files, breaks if user's shell differs).
- Replacing `hf` with direct Hugging Face cache scanning (separate concern; cache layout is an implementation detail of `hf`).

## Decisions

- **Pure resolver function `HFCLI.resolveExecutable(extraPath: String?) -> String?`** in a new `Sources/HFCLI.swift`: checks (1) UserDefaults `hf_binary_path` if set and executable, (2) each dir in inherited `PATH` env, (3) fixed common dirs: `/opt/homebrew/bin`, `/usr/local/bin`, `~/.local/bin`, `~/Library/Python/*/bin` (glob). Candidate check: `FileManager.isExecutableFile`. Returns absolute path or nil. Rationale: pure function over (override, envPath, fm) → unit-testable without spawning processes. Alternative rejected: `which hf` subprocess — itself depends on PATH, same problem one level down.
- **Spawn resolved absolute path** via `task.executableURL = URL(fileURLWithPath: resolved)`, arguments `["cache", "ls", "--json"]` (drop `/usr/bin/env` hop).
- **Augmented PATH for child**: set `task.environment = ProcessInfo env + ["PATH": commonDirs.joined(:) + ":" + inheritedPath]`. Keeps `hf`'s internal subprocess lookups working (git, python helpers).
- **Error message**: on nil resolution → `"hf not found. Searched: <override>, PATH, /opt/homebrew/bin, /usr/local/bin, ~/.local/bin, ~/Library/Python/*/bin. Install: brew install hf or set hf path in Settings."`
- **Settings UI**: single `TextField` "Path to hf binary (optional)" bound to `@AppStorage("hf_binary_path")` in Models section next to Refresh button. Empty = auto-discovery.
- **No caching of resolved path** (resolve per invocation): refresh is rare, resolution is cheap (few `stat` calls), avoids staleness after reinstall.

## Risks / Trade-offs

- [Common-dirs list misses exotic installs (pyenv shims, conda)] → override field covers it; list covers Homebrew (Apple Silicon + Intel), pipx default, and Python user installs.
- [`~/Library/Python/*/bin` glob on every refresh] → few dirs, negligible; glob only when earlier steps miss.
- [User sets override to broken path] → resolver validates `isExecutableFile` before use; falls through to discovery, no crash.

## Migration Plan

No storage format change (new optional key `hf_binary_path`). Rollback = revert; key ignored by old build.

## Open Questions

None.
