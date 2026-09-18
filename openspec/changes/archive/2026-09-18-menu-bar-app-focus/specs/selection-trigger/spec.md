## ADDED Requirements

### Requirement: App activation on assistant invocation
When a selection-assistant prompt is dispatched to the chat pipeline (direct-mode trigger or preset click in ActionBar mode), the app SHALL bring its main window to front and give it keyboard focus, so the streamed response is visible immediately.

#### Scenario: Direct mode dispatch
- **WHEN** a selection is sent to the chat via direct mode trigger
- **THEN** app activates and main window receives keyboard focus

#### Scenario: Preset click dispatch
- **WHEN** user clicks a preset button on the action bar panel
- **THEN** app activates and main window receives keyboard focus as the response begins
