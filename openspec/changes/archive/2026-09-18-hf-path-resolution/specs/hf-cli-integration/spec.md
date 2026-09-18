## Purpose
Интеграция с `hf` CLI для загрузки списка локально закешированных моделей: устойчивое определение пути к бинарнику независимо от окружения запуска (Finder/Dock GUI PATH), пользовательский override и понятные ошибки.

## ADDED Requirements

### Requirement: PATH-independent hf resolution
The system SHALL locate the `hf` executable by searching, in order: the user-configured override path, then the process `PATH` environment, then common install locations (`/opt/homebrew/bin`, `/usr/local/bin`, `~/.local/bin`, `~/Library/Python/*/bin`). The first existing executable file named `hf` SHALL be used.

#### Scenario: Launched from Finder without shell PATH
- **WHEN** app is launched from Finder/Dock and `hf` is installed in `/opt/homebrew/bin`
- **THEN** model loading succeeds without shell involvement

#### Scenario: Override path takes precedence
- **WHEN** `hf_binary_path` is set to a valid executable path
- **THEN** that path is used directly, skipping discovery

#### Scenario: No hf found anywhere
- **WHEN** no executable `hf` exists in override, PATH, or common locations
- **THEN** model loading fails with an error listing the searched locations and install hint

### Requirement: Augmented environment for spawned hf
The spawned `hf` process SHALL receive an environment whose `PATH` includes the common install locations in addition to the inherited `PATH`.

#### Scenario: hf spawns subprocesses or plugins
- **WHEN** `hf cache ls --json` runs
- **THEN** the process environment contains the augmented `PATH`

### Requirement: Model loading reports failure gracefully
Model loading failure SHALL set a user-visible error string without crashing and SHALL keep previously loaded models intact.

#### Scenario: hf missing at refresh
- **WHEN** user clicks Refresh Models and `hf` cannot be resolved
- **THEN** error message names the searched locations and suggests `brew install hf`; previously loaded model list remains visible
