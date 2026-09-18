## MODIFIED Requirements

### Requirement: Preset buttons
Panel SHALL display preset buttons derived from stored preset objects (name + template). Default presets: Translate, Summarize. Button order SHALL match preset list order.

#### Scenario: Default presets shown
- **WHEN** panel opens
- **THEN** buttons for Translate and Summarize visible

#### Scenario: Panel reflects Settings changes
- **WHEN** user adds, edits, deletes, or reorders presets in Settings
- **THEN** next panel open shows the updated names and order

#### Scenario: Preset selected passes template
- **WHEN** user clicks a preset button
- **THEN** panel dismisses and the preset template (not just the name) is passed to the chat pipeline

## REMOVED Requirements

### Requirement: Configurable custom presets
**Reason**: Superseded by the `preset-templates` capability, which defines full CRUD and template storage.
**Migration**: Settings preset management is now specified in `preset-templates`; panel behavior in the modified "Preset buttons" requirement above.
