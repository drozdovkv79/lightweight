# Lightweight — Agent Notes

## Language
Отвечай и пиши мне на русском
Технические термины и программы на английском

## Repo overview
macOS native SwiftUI chat client for OpenRouter LLMs. Single executable target `LightweightChat` under `LightweightChat/`. Swift Package Manager, swift-tools-version 5.9, macOS 14+ only.

## Build & run
```sh
make          # build + register app (debug)
make run      # build, register, open
make build    # swift build -c release --package-path LightweightChat
```

## Version bump
```sh
make version VERSION=1.1 BUILD=2
```
`VERSION` must not decrease; `BUILD` must increase. Both validated by Makefile.

## Distribution release
```sh
make version VERSION=x.x BUILD=n
make release    # builds dist → signs → notarizes → staples → validates DMG
```
Requires `Developer ID Application` signing identity and `lightweight-notary` keychain profile. Local builds use `Apple Development`.

## Architecture
- `LightweightChat/Sources/` — all Swift source (8 files)
- `LightweightChat/Resources/` — Info.plist, AppIcon.icns
- Entry: `App.swift` (`@main`), `ChatViewModel.swift` owns streaming logic
- API endpoint: configurable via `provider_url` in `UserDefaults` (fallback: `https://openrouter.ai/api/v1/chat/completions`)
- API key: macOS Keychain (`org.peterc.lightweight` service), falls back to `OPENROUTER_API_KEY` env var
- Models: loaded dynamically from Hugging Face local cache via `hf cache ls --json` CLI. `ModelLoader.parseHFModels()` in `Models.swift`. Requires `hf` CLI installed.
- `ChatViewModel.providerUrl` — configurable provider URL
- `ChatViewModel.models` — dynamic model list from `hf`
- `ChatViewModel.hfError` — error string if `hf` CLI fails

## Key files
- `Makefile` — all build/release commands and version logic
- `LightweightChat/Package.swift` — SPM manifest
- `LightweightChat/Resources/Info.plist` — bundle version, signing ID
- `LightweightChat/Sources/ChatViewModel.swift` — core streaming/cancellation logic

## OpenSpec
- Planning artifacts in `openspec/` (project-local)
- Active changes: `openspec/changes/`
- Specs: `openspec/specs/`
- Commands: `openspec new change`, `openspec status`, `openspec instructions`, `openspec apply`
- `/opsx-propose <name>` creates change with all artifacts
- `/opsx-apply <name>` implements

## Notes
- No tests exist yet
- `.build/`, `*.app/`, `/dist/` in `.gitignore`
- `make clean` → `swift package --package-path LightweightChat clean`
- Streaming uses `URLSession.shared.bytes` with 33ms throttle on UI updates
