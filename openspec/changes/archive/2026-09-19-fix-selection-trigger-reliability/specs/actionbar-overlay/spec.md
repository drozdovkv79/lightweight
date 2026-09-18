## MODIFIED Requirements

### Requirement: Panel appearance and positioning
Overlay panel SHALL be NSPanel with `.borderless`, `.nonactivatingPanel` style, level `.statusBar`, positioned near selection rect. The panel pipeline (trigger → read → dispatch → panel) SHALL work whether or not the main window is open; notification handling SHALL NOT live on a window-scoped SwiftUI view.

#### Scenario: Panel opens near selection
- **WHEN** ActionBar mode triggers
- **THEN** NSPanel appears near selection rect with `collectionBehavior [.canJoinAllSpaces, .fullScreenAuxiliary]`

#### Scenario: Main window is closed
- **WHEN** selection trigger fires while the main window is closed (⌘W earlier)
- **THEN** the panel (actionbar) or chat send (direct) still happens; the notification is not dropped

### Requirement: Direct mode bypass
Direct mode SHALL send selection to chat immediately without showing panel. The DEFAULT selection mode SHALL be `actionbar` so the preset panel appears on selection out of the box; direct remains selectable in Settings.

#### Scenario: Direct mode
- **WHEN** user triggers in direct mode (explicitly chosen in Settings)
- **THEN** no panel shown; text sent to chat immediately

#### Scenario: Default mode on fresh install
- **WHEN** user installs the app and selects text without touching Settings
- **THEN** preset panel appears (actionbar is the default)
