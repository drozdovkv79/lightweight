# render-performance-fix Specification

## Purpose
Оптимизация рендера: throttle, reuse, lazy parse, spec sync.

## Requirements

### Requirement: Scroll throttle real
System SHALL throttle scroll to ≤1 per 50ms.

#### Scenario: Rapid stream
- **WHEN** 10 chunks in 300ms
- **THEN** scroll executes ≤1/50ms
