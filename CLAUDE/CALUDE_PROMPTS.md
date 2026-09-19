
# CLAUDE Prompts

This document records the CLAUDE prompts used during the development of the WeatherNow Flutter application.

The prompts were used for implementation support, debugging, test generation, code review, architecture discussions, and documentation. Each AI-generated suggestion was reviewed against the existing codebase and application requirements.

---

## Phase 1: Project Setup and Architecture

### Prompt 1 — Review the Existing Project

Review the existing WeatherNow Flutter project before making any changes.

Understand:

- Current folder structure
- Architecture and dependencies
- State management approach
- Networking implementation
- Existing tests
- Current application behavior

Do not make changes until the existing implementation and conventions are understood.

### Prompt 2 — Follow Clean Architecture

Implement the requested functionality while following the existing Clean Architecture-inspired structure.

Keep responsibilities separated between:

- Data
- Domain
- Presentation

Avoid placing business logic inside widgets and do not introduce unnecessary dependencies.

### Prompt 3 — Use Riverpod Consistently

Review the existing Riverpod implementation.

Reuse existing providers where possible and create new providers only when required.

Keep asynchronous states explicit and ensure that providers remain focused and testable.

---

## Phase 2: Networking and API

### Prompt 4 — Review API Client

Review the existing Dio API client and identify opportunities to improve:

- Error handling
- Timeout handling
- Request configuration
- Response parsing
- Exception mapping
- Logging

Do not expose API keys or sensitive information in logs.

### Prompt 5 — Implement Weather API

Implement current weather and forecast API services using the existing API client.

Follow the current repository and domain contracts. Write tests before implementation where practical.

Cover:

- Successful response
- Invalid response
- Network failure
- Timeout
- API error

### Prompt 6 — Mock Environment

Review the mock API environment.

Ensure that mock mode can run without a live API key or network connection and that mock responses follow the same models as the live API.

---

## Phase 3: Search and Location

### Prompt 7 — Fix City Selection

Review the city search flow.

When a user selects a city from the suggestions:

- Close the suggestions dropdown immediately.
- Hide the dropdown.
- Update the search field.
- Fetch weather for the selected city.
- Update the weather card.
- Handle loading and error states.

Add regression tests for this behavior.

### Prompt 8 — Implement Current Location

Review the Current Location button implementation.

Ensure that it:

1. Requests location permission when required.
2. Fetches the device's current coordinates.
3. Performs reverse geocoding.
4. Updates the search field with the detected city.
5. Displays weather for the same city.
6. Shows a local loading indicator.
7. Displays a user-friendly error when the operation fails.

Follow the existing architecture and add tests for success and failure scenarios.

### Prompt 9 — Fix Location Timeout

Investigate why the application remains on the loading screen when the device location is unavailable.

Review the Geolocator implementation and add appropriate timeout handling.

The application should:

- Stop waiting after a reasonable timeout.
- Display a readable error message.
- Provide retry support.
- Allow the user to search for a city manually.
- Avoid requesting location unnecessarily when a saved city exists.

Add a regression test for the timeout scenario.

### Prompt 10 — Review Platform Differences

Review the location flow for Android Emulator and iOS Simulator behavior.

Identify assumptions related to:

- Location availability
- Permission handling
- Simulator configuration
- Timeout behavior
- App lifecycle

Do not assume that behavior verified on Android will be identical on iOS.

---

## Phase 4: Favorites and Offline Support

### Prompt 11 — Review Favorites Flow

Review the favorites implementation.

Ensure that:

- Cities can be added and removed.
- Favorite state is persisted correctly.
- Favorite cities are not incorrectly treated as the last-searched city.
- Loading, empty, and error states are handled.
- Existing tests remain valid.

### Prompt 12 — Implement Offline Caching

Review the Hive caching implementation.

The offline storage setting should be the single source of truth.

When enabled:

- Save successful weather responses.
- Use cached data as fallback when appropriate.
- Preserve freshness information.

When disabled:

- Do not save new weather data.
- Do not use cached weather data as fallback.
- Persist the setting across restarts.

Add tests for both enabled and disabled states.

### Prompt 13 — Protect Cached Data

Review the repository behavior when an API request fails.

Ensure that a failed request does not overwrite valid cached data.

Handle:

- Network failure
- Timeout
- Invalid response
- Empty cache
- Stale cache

Keep the behavior predictable and testable.

---

## Phase 5: Settings and UI

### Prompt 14 — Review Settings Screen

Review the Settings screen and compare its behavior with the existing application requirements.

Verify:

- Temperature unit selection
- Theme selection
- Offline storage setting
- Persistence after restart
- Correct UI state after changes
- Accessibility and consistent spacing

Avoid unrelated UI refactoring.

### Prompt 15 — Improve UI Consistency

Review the application UI for consistency.

Focus on:

- Spacing
- Typography
- Colors
- Loading indicators
- Empty states
- Error states
- Light and dark themes
- Responsive layouts

Reuse existing widgets where possible and avoid duplicating UI logic.

---

## Phase 6: Testing and Debugging

### Prompt 16 — Write Tests First

Before implementing the requested behavior:

1. Review the existing code.
2. Identify the expected behavior.
3. Write focused tests.
4. Implement the smallest suitable change.
5. Run the relevant tests.
6. Review possible side effects.

Do not modify unrelated code.

### Prompt 17 — Investigate a Failing Test

Review the failing test and identify whether the failure is caused by:

- The current change
- Existing implementation behavior
- Test setup
- Mock configuration
- An unrelated pre-existing issue

Do not silently change unrelated functionality just to make the test pass.

### Prompt 18 — Add Regression Coverage

For the reported bug, add a regression test that fails before the fix and passes after the fix.

The test should verify user-visible behavior rather than only implementation details.

### Prompt 19 — Review Test Coverage

Review the current test suite and identify missing cases for:

- API failures
- Permission denial
- Location timeout
- Empty search results
- Offline mode
- Settings persistence
- Favorites
- Loading and error states

Suggest focused tests without unnecessarily increasing complexity.

---

## Phase 7: Code Quality and Performance

### Prompt 20 — Review Code Quality

Review the modified code as a senior Flutter developer.

Focus on:

- SOLID principles
- Separation of concerns
- Naming
- Readability
- Testability
- Error handling
- Unnecessary duplication
- Unnecessary abstractions

Only recommend changes that provide a practical benefit.

### Prompt 21 — Review Widget Rebuilds

Review the affected widgets for unnecessary rebuilds.

Check:

- Provider scope
- Widget responsibilities
- State consumption
- Search field updates
- Loading indicators
- List rendering

Do not optimize prematurely or change behavior without tests.

### Prompt 22 — Review Platform Compatibility

Review the changes for Android and iOS compatibility.

Pay attention to:

- Permissions
- Location services
- Native configuration
- Deployment target
- Simulator behavior
- Release configuration

Clearly distinguish verified issues from assumptions.

---

## Phase 8: Documentation

### Prompt 23 — Update README

Review the project implementation and prepare a professional README suitable for a senior Flutter developer.

Include:

- Project overview
- Features
- Architecture
- Riverpod usage
- API setup
- Mock and live environments
- Offline caching
- Location behavior
- Testing commands
- Known limitations
- Possible future improvements

Do not document features that are not implemented or verified.

### Prompt 24 — Update CLAUDE.md

Create development guidelines for AI-assisted work on this project.

Include:

- Architecture rules
- Riverpod conventions
- Networking guidelines
- Error handling
- Testing expectations
- Location behavior
- Offline caching rules
- Git hygiene
- Definition of done

The guidelines should be practical and aligned with the existing codebase.

### Prompt 25 — Document Lessons Learned

Document the important technical lessons from the implementation.

For each issue, describe:

- Problem
- Root cause
- Solution
- Verification
- Lesson learned

Clearly separate confirmed findings from assumptions and environment limitations.

### Prompt 26 — Document AI Prompts

Review the development history and organize the AI prompts into meaningful phases.

Keep the prompts understandable to another developer and avoid including:

- API keys
- Personal information
- Local machine-specific paths
- Unverified claims
- Sensitive configuration

---

## AI Review Checklist

Before accepting an AI-generated change:

- [ ] Existing code was reviewed first.
- [ ] The change follows the current architecture.
- [ ] No unnecessary dependency was added.
- [ ] Business logic is not placed inside widgets.
- [ ] Error and loading states are handled.
- [ ] Relevant tests were added or updated.
- [ ] Platform-specific behavior was considered.
- [ ] No secrets were introduced.
- [ ] Formatting and static analysis were run.
- [ ] The final Git diff was reviewed.

---

## General Prompt Template

Use the following template for future development tasks:

> Review the existing implementation before making changes.
>
> Understand the current architecture, state management, dependencies, and tests.
>
> Implement only the requested behavior while following existing project conventions.
>
> Avoid unrelated refactoring and unnecessary dependencies.
>
> Handle loading, success, empty, and failure states.
>
> Write or update regression tests for the affected behavior.
>
> Run formatting, static analysis, and relevant tests.
>
> Clearly report modified files, test results, assumptions, and any remaining limitations.