## MODIFIED Requirements

### Requirement: Click opens and focuses app
Clicking the menu bar item SHALL bring the app to the foreground (even when another app is active), open the main window if closed, and give it keyboard focus. The main window SHALL be kept alive after ⌘W close (strong registry reference + `isReleasedWhenClosed = false`) so tray click restores the same window.

#### Scenario: Click from another app
- **WHEN** user clicks the menu bar icon while another app is frontmost
- **THEN** app activates, main window comes to front, and keyboard focus lands in it

#### Scenario: Click when window was closed
- **WHEN** user closes the main window with ⌘W and clicks the menu bar icon
- **THEN** the same main window is brought back to front and focused (no window recreation needed)

### Requirement: Menu bar status item with tray icon
The app SHALL display a status item in the system menu bar for the entire app lifetime, created at launch, showing the bundled `locy_tray.jpeg` circular-masked to add transparency outside the circle (source JPEG has no alpha channel). A right-click on the item SHALL open a context menu with two items: `About…` (opens the About panel) and `Quit` (terminates the app); a left click keeps the activate+focus action.

#### Scenario: Item appears at launch
- **WHEN** app finishes launching
- **THEN** menu bar shows the tray icon item

#### Scenario: Legible in light and dark menu bar
- **WHEN** menu bar is displayed in light or dark mode
- **THEN** the circular icon stays legible with no opaque square background around it

#### Scenario: Right-click opens context menu
- **WHEN** user right-clicks the tray icon
- **THEN** context menu appears with `About…` and `Quit` items

#### Scenario: About item
- **WHEN** user clicks `About…` in the tray menu
- **THEN** the About panel opens

#### Scenario: Quit item
- **WHEN** user clicks `Quit` in the tray menu
- **THEN** the app terminates (server processes killed per mlx-server-control)

#### Scenario: Left click unchanged
- **WHEN** user left-clicks the tray icon
- **THEN** context menu does not appear; app activates and window is focused
