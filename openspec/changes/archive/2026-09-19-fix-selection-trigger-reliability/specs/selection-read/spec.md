## MODIFIED Requirements

### Requirement: Read selected text from frontmost app
System SHALL read selected text via AX API from frontmost application. When `kAXSelectedTextAttribute` on the focused element is unavailable or empty, the system SHALL fall back to the marker range API: copy `kAXSelectedTextMarkerRangeAttribute` from the focused element (or its enclosing web area) and resolve it via `AXUIElementCopyParameterizedAttributeValue` with `kAXStringForMarkerRangeParameterizedAttribute`. Only when both paths fail SHALL the system return nil.

#### Scenario: Text is selected
- **WHEN** user has text selected in any AX-compatible app
- **THEN** system returns selected string via `kAXSelectedTextAttribute`

#### Scenario: Safari/WebKit selection
- **WHEN** user selects text in Safari web content (static page, not editable field)
- **THEN** system returns the selected text via the marker range fallback

#### Scenario: No text selected
- **WHEN** no text is selected
- **THEN** system returns nil

#### Scenario: App has limited AX support
- **WHEN** frontmost app exposes neither selected text nor marker ranges (no AX support at all)
- **THEN** system returns nil gracefully (no crash)
