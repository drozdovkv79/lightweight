## Purpose

Local models run through rapid-mlx or mlx_lm servers, so the app SHALL let users pick the server, start and stop it from the toolbar, and inspect its console output in a dedicated log window.

## Requirements

### Requirement: Server picker in toolbar
The system SHALL show a server picker with `rapid-mlx` and `mlx_lm` options to the right of the model menu. The selection SHALL persist across launches.

#### Scenario: Server selected
- **WHEN** user picks a server in the toolbar picker
- **THEN** subsequent Start launches that server type and the choice is remembered

### Requirement: Start server with selected model
The system SHALL start the selected server for the currently selected model on port 8008 with `--max-tokens 65000` when the start button is pressed. The exact commands are `rapid-mlx serve {model} --port 8008 --max-tokens 65000` and `mlx_lm.server --model {model} --port 8008 --max-tokens 65000`.

#### Scenario: Server starts successfully
- **WHEN** user presses start with a model selected
- **THEN** the server process launches, the button switches to stop state, and server output flows into the log

#### Scenario: Server binary missing
- **WHEN** the selected server binary is not found in PATH
- **THEN** no process launches and the log shows a clear "binary not found" error

#### Scenario: Start pressed while running
- **WHEN** user presses start while a server is already running
- **THEN** no second process launches (button already shows stop state)

### Requirement: Stop server and free memory
The system SHALL stop the running server process when the stop button is pressed and kill leftover processes so memory is freed. Stopping SHALL also force-kill orphaned descendant processes (workers spawned by the server).

#### Scenario: Server stops
- **WHEN** user presses stop while a server is running
- **THEN** the server process terminates, the button switches to start state, and the log records the stop

#### Scenario: Stop with nothing running
- **WHEN** user presses stop while no server is running
- **THEN** nothing happens (button already shows start state)

#### Scenario: Descendant workers killed
- **WHEN** server stop is requested and the server has spawned worker processes
- **THEN** all descendants are force-killed so no model memory stays allocated

### Requirement: Server killed on app termination
When the app terminates, the running server process tree SHALL be killed synchronously (SIGTERM, then SIGKILL for survivors) and the server port swept, so no processes or memory remain after the app exits.

#### Scenario: App quits while server runs
- **WHEN** user quits the app while a server is running
- **THEN** the server and all its descendants are killed before the process exits

#### Scenario: App quits with no server
- **WHEN** user quits the app with no server running
- **THEN** quit proceeds without delay

### Requirement: Server log window
The system SHALL provide a log button (single icon, next to settings) opening a separate window with the console output of launched servers. The log SHALL auto-scroll to new output and use a monospace font.

#### Scenario: Log inspected
- **WHEN** user opens the log window after starting a server
- **THEN** stdout/stderr of the server process is visible with latest lines at the bottom

#### Scenario: Log window closed and reopened
- **WHEN** user closes and reopens the log window
- **THEN** previously captured output for the session is still shown
