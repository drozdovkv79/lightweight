## 1. Resolver

- [x] 1.1 Create `Sources/HFCLI.swift` with `enum HFCLI` and pure `resolveExecutable(override: String?, envPath: String?, fileManager: FileManager = .default) -> String?` searching override → envPath dirs → common dirs (`/opt/homebrew/bin`, `/usr/local/bin`, `~/.local/bin`, `~/Library/Python/*/bin` glob) via `isExecutableFile`; verify with standalone swiftc test script covering: override hit, override invalid → falls through, PATH hit, common-dir hit (create temp executable), nothing found → nil
- [x] 1.2 Add `searchedLocationsDescription` (or equivalent) for error text listing searched locations; verify in test script

## 2. Spawn integration

- [x] 2.1 In `ChatViewModel.loadModelsFromHF()`: replace `/usr/bin/env hf` with resolved absolute path + arguments `["cache", "ls", "--json"]`; set `task.environment` = inherited env with `PATH` prefixed by common dirs; on nil resolution set `hfError` with searched-locations message + `brew install hf` hint; verify `swift build` passes
- [x] 2.2 Preserve previous `models` on failure (do not clear before success) and confirm `hfError` surfaces in Settings alert; verify by code inspection of failure path

## 3. Settings override

- [x] 3.1 Add "Path to hf binary (optional)" TextField bound to `@AppStorage("hf_binary_path")` in Settings Models section; verify build and that empty value keeps auto-discovery

## 4. Verification

- [x] 4.1 `swift build -c debug` and `swift build -c release` pass; resolver test script all PASS
- [x] 4.2 Launch built .app from Finder (not terminal) with `hf` installed in Homebrew path → Refresh Models lists models without error
