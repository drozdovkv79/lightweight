## Purpose
Иконка приложения в системном меню (NSStatusItem): один клик открывает главное окно и передаёт ему клавиатурный фокус, независимо от того, какое приложение сейчас активно. Фиксированные иконки: app icon из `locy_icon.jpeg`, tray icon из `locy_tray.jpeg`.

## ADDED Requirements

### Requirement: Menu bar status item with tray icon
The app SHALL display a status item in the system menu bar for the entire app lifetime, created at launch, showing the bundled `locy_tray.jpeg` circular-masked to add transparency outside the circle (source JPEG has no alpha channel).

#### Scenario: Item appears at launch
- **WHEN** app finishes launching
- **THEN** menu bar shows the tray icon item

#### Scenario: Legible in light and dark menu bar
- **WHEN** menu bar is displayed in light or dark mode
- **THEN** the circular icon stays legible with no opaque square background around it

### Requirement: App icon from provided artwork
The app icon (Dock, Finder, ⌘Tab) SHALL be built from the provided `locy_icon.jpeg` artwork as `AppIcon.icns`.

#### Scenario: Dock and Finder show new icon
- **WHEN** app is launched or viewed in Finder
- **THEN** Dock/Finder/⌘Tab show the `locy_icon.jpeg`-derived icon

### Requirement: Click opens and focuses app
Clicking the menu bar item SHALL bring the app to the foreground (even when another app is active), open the main window if closed, and give it keyboard focus.

#### Scenario: Click from another app
- **WHEN** user clicks the menu bar icon while another app is frontmost
- **THEN** app activates, main window comes to front, and keyboard focus lands in it

#### Scenario: Click when window was closed
- **WHEN** user closes the main window and clicks the menu bar icon
- **THEN** main window is reopened and focused
