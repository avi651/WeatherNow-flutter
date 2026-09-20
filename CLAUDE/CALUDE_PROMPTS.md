**\*\*# CLAUDE Prompts\*\***

This document records the CLAUDE prompts used during the development of the WeatherNow Flutter application.

The prompts were used for implementation support, debugging, test generation, code review, architecture discussions, and documentation. Each AI-generated suggestion was reviewed against the existing codebase and application requirements.

**\*\*---\*\***

**\*\*## Phase 1: Project Setup and Architecture\*\***

**\*\*### Prompt 1 — Review the Existing Project\*\***

Review the existing WeatherNow Flutter project before making any changes.

Understand:

\\- Current folder structure

\\- Architecture and dependencies

\\- State management approach

\\- Networking implementation

\\- Existing tests

\\- Current application behavior

Do not make changes until the existing implementation and conventions are understood.

**\*\*### Prompt 2 — Follow Clean Architecture\*\***

Implement the requested functionality while following the existing Clean Architecture-inspired structure.

Keep responsibilities separated between:

\\- Data

\\- Domain

\\- Presentation

Avoid placing business logic inside widgets and do not introduce unnecessary dependencies.

**\*\*### Prompt 3 — Use Riverpod Consistently\*\***

Review the existing Riverpod implementation.

Reuse existing providers where possible and create new providers only when required.

Keep asynchronous states explicit and ensure that providers remain focused and testable.

**\*\*---\*\***

**\*\*## Phase 2: Networking and API\*\***

**\*\*### Prompt 4 — Review API Client\*\***

Review the existing Dio API client and identify opportunities to improve:

\\- Error handling

\\- Timeout handling

\\- Request configuration

\\- Response parsing

\\- Exception mapping

\\- Logging

Do not expose API keys or sensitive information in logs.

**\*\*### Prompt 5 — Implement Weather API\*\***

Implement current weather and forecast API services using the existing API client.

Follow the current repository and domain contracts. Write tests before implementation where practical.

Cover:

\\- Successful response

\\- Invalid response

\\- Network failure

\\- Timeout

\\- API error

**\*\*### Prompt 6 — Mock Environment\*\***

Review the mock API environment.

Ensure that mock mode can run without a live API key or network connection and that mock responses follow the same models as the live API.

**\*\*---\*\***

**\*\*## Phase 3: Search and Location\*\***

**\*\*### Prompt 7 — Fix City Selection\*\***

Review the city search flow.

When a user selects a city from the suggestions:

\\- Close the suggestions dropdown immediately.

\\- Hide the dropdown.

\\- Update the search field.

\\- Fetch weather for the selected city.

\\- Update the weather card.

\\- Handle loading and error states.

Add regression tests for this behavior.

**\*\*### Prompt 8 — Implement Current Location\*\***

Review the Current Location button implementation.

Ensure that it:

1\\. Requests location permission when required.

2\\. Fetches the device's current coordinates.

3\\. Performs reverse geocoding.

4\\. Updates the search field with the detected city.

5\\. Displays weather for the same city.

6\\. Shows a local loading indicator.

7\\. Displays a user-friendly error when the operation fails.

Follow the existing architecture and add tests for success and failure scenarios.

**\*\*### Prompt 9 — Fix Location Timeout\*\***

Investigate why the application remains on the loading screen when the device location is unavailable.

Review the Geolocator implementation and add appropriate timeout handling.

The application should:

\\- Stop waiting after a reasonable timeout.

\\- Display a readable error message.

\\- Provide retry support.

\\- Allow the user to search for a city manually.

\\- Avoid requesting location unnecessarily when a saved city exists.

Add a regression test for the timeout scenario.

**\*\*### Prompt 10 — Review Platform Differences\*\***

Review the location flow for Android Emulator and iOS Simulator behavior.

Identify assumptions related to:

\\- Location availability

\\- Permission handling

\\- Simulator configuration

\\- Timeout behavior

\\- App lifecycle

Do not assume that behavior verified on Android will be identical on iOS.

**\*\*---\*\***

**\*\*## Phase 4: Favorites and Offline Support\*\***

**\*\*### Prompt 11 — Review Favorites Flow\*\***

Review the favorites implementation.

Ensure that:

\\- Cities can be added and removed.

\\- Favorite state is persisted correctly.

\\- Favorite cities are not incorrectly treated as the last-searched city.

\\- Loading, empty, and error states are handled.

\\- Existing tests remain valid.

**\*\*### Prompt 12 — Implement Offline Caching\*\***

Review the Hive caching implementation.

The offline storage setting should be the single source of truth.

When enabled:

\\- Save successful weather responses.

\\- Use cached data as fallback when appropriate.

\\- Preserve freshness information.

When disabled:

\\- Do not save new weather data.

\\- Do not use cached weather data as fallback.

\\- Persist the setting across restarts.

Add tests for both enabled and disabled states.

**\*\*### Prompt 13 — Protect Cached Data\*\***

Review the repository behavior when an API request fails.

Ensure that a failed request does not overwrite valid cached data.

Handle:

\\- Network failure

\\- Timeout

\\- Invalid response

\\- Empty cache

\\- Stale cache

Keep the behavior predictable and testable.

**\*\*---\*\***

**\*\*## Phase 5: Settings and UI\*\***

**\*\*### Prompt 14 — Review Settings Screen\*\***

Review the Settings screen and compare its behavior with the existing application requirements.

Verify:

\\- Temperature unit selection

\\- Theme selection

\\- Offline storage setting

\\- Persistence after restart

\\- Correct UI state after changes

\\- Accessibility and consistent spacing

Avoid unrelated UI refactoring.

**\*\*### Prompt 15 — Improve UI Consistency\*\***

Review the application UI for consistency.

Focus on:

\\- Spacing

\\- Typography

\\- Colors

\\- Loading indicators

\\- Empty states

\\- Error states

\\- Light and dark themes

\\- Responsive layouts

Reuse existing widgets where possible and avoid duplicating UI logic.

**\*\*---\*\***

**\*\*## Phase 6: Testing and Debugging\*\***

**\*\*### Prompt 16 — Write Tests First\*\***

Before implementing the requested behavior:

1\\. Review the existing code.

2\\. Identify the expected behavior.

3\\. Write focused tests.

4\\. Implement the smallest suitable change.

5\\. Run the relevant tests.

6\\. Review possible side effects.

Do not modify unrelated code.

**\*\*### Prompt 17 — Investigate a Failing Test\*\***

Review the failing test and identify whether the failure is caused by:

\\- The current change

\\- Existing implementation behavior

\\- Test setup

\\- Mock configuration

\\- An unrelated pre-existing issue

Do not silently change unrelated functionality just to make the test pass.

**\*\*### Prompt 18 — Add Regression Coverage\*\***

For the reported bug, add a regression test that fails before the fix and passes after the fix.

The test should verify user-visible behavior rather than only implementation details.

**\*\*### Prompt 19 — Review Test Coverage\*\***

Review the current test suite and identify missing cases for:

\\- API failures

\\- Permission denial

\\- Location timeout

\\- Empty search results

\\- Offline mode

\\- Settings persistence

\\- Favorites

\\- Loading and error states

Suggest focused tests without unnecessarily increasing complexity.

**\*\*---\*\***

\*\*

**## Phase 7: Security, Hive Encryption, and Device Integrity**

**### Prompt 20 — Audit Existing Local Storage Security**

Review the existing WeatherNow Flutter project before making any security-related changes.

The application already uses Hive for local storage and \`flutter_secure_storage\` for secure storage.

Audit:

\- All Hive boxes and stored keys

\- Hive initialization and box-opening logic

\- Existing encryption configuration

\- Encryption key generation and retrieval

\- \`flutter_secure_storage\` configuration

\- Sensitive data stored locally

\- Logging and error handling

\- Existing Android and iOS security configuration

Do not assume that a security feature is implemented. Verify every claim directly against the source code.

Do not modify the application until the audit findings and risks are clearly reported.

**### Prompt 21 — Secure Existing Hive Storage**

Secure the existing Hive implementation using the already integrated \`flutter_secure_storage\`.

Requirements:

\- Reuse the existing Hive implementation and architecture.

\- Store the Hive encryption key securely through \`flutter_secure_storage\`.

\- Use iOS Keychain and Android Keystore-backed protection where supported and verified.

\- Never hardcode the Hive encryption key.

\- Preserve existing Hive box names, keys, models, and TypeAdapters.

\- Do not replace Hive with another database.

\- Do not change existing business logic, UI, or user workflows.

\- Do not delete or reset existing user data.

\- Handle missing, invalid, or corrupted encryption keys safely.

\- Review backward compatibility for existing unencrypted or differently configured boxes.

\- Do not perform a destructive migration without explicit approval.

First provide an implementation plan and migration-risk assessment. Make only the minimum necessary changes after the existing code has been reviewed.

**### Prompt 22 — Review Hive Encryption Key Management**

Review the complete lifecycle of the Hive encryption key.

Verify:

\- How the key is generated.

\- Whether the key is cryptographically random.

\- Where the key is stored.

\- How the key is retrieved on application startup.

\- Whether the same key is reused for existing encrypted boxes.

\- What happens when secure storage is unavailable.

\- What happens when the key is missing or invalid.

\- Whether keys or sensitive values are written to logs.

\- Whether backup, restore, reinstall, and device migration scenarios are handled.

Do not claim that secure storage makes the key impossible to extract. Document realistic limitations and failure scenarios.

Add focused tests where practical without changing unrelated functionality.

**### Prompt 23 — Add iOS Jailbreak Detection**

Review the existing iOS security implementation and add jailbreak detection only if it is required and approved.

Before implementation:

\- Check whether jailbreak detection already exists.

\- Review available package and native implementation options.

\- Assess false-positive risks.

\- Assess simulator limitations.

\- Define the behavior when jailbreak detection returns a positive result.

\- Ensure that the app handles detection failures gracefully.

The implementation must:

\- Follow the existing architecture.

\- Avoid blocking normal users because of an unverified or unreliable signal.

\- Avoid exposing technical details to users.

\- Clearly document detection limitations.

\- Include tests for the application-level handling where practical.

\- Avoid claiming that jailbreak detection is impossible to bypass.

If the feature is not implemented, document it as not implemented. Do not mark it as completed.

**### Prompt 24 — Add Android Root Detection**

Review the existing Android security implementation and add root detection only if it is required and approved.

Before implementation:

\- Check whether root detection already exists.

\- Review package and native implementation options.

\- Assess false-positive risks.

\- Consider emulator behavior and test limitations.

\- Define how the app responds to a positive detection result.

\- Ensure errors do not crash the application.

The implementation must:

\- Follow the existing architecture.

\- Avoid unrelated refactoring.

\- Handle unsupported or inconclusive results safely.

\- Clearly document limitations and possible bypasses.

\- Add focused tests for application-level behavior where practical.

Do not claim that root detection guarantees device integrity.

If the feature is not implemented, document it as not implemented.

**### Prompt 25 — Security Logging and Sensitive Data Review**

Perform a security-focused review of the application.

Check:

\- API keys in source code and configuration.

\- API keys in request and response logs.

\- Hive encryption keys in logs.

\- Secure storage values in logs.

\- Tokens, credentials, and personal data.

\- Debug prints and exception messages.

\- Crash reporting payloads.

\- User-facing error messages.

\- Backup and local storage exposure.

Remove or redact sensitive information only where required and without changing unrelated behavior.

Report every security finding with:

\- Severity

\- File and location

\- Risk

\- Recommended fix

\- Whether the issue was fixed or left unchanged

Do not expose actual secrets in the report or commit history.

**### Prompt 26 — Verify Security Changes**

After implementing approved security changes:

1\. Run \`dart format\` on modified Dart files.

2\. Run \`flutter analyze\`.

3\. Run \`flutter test\`.

4\. Review the Git diff.

5\. Confirm that existing Hive data and box names were not unintentionally changed.

6\. Confirm that no secrets or encryption keys were added to the repository.

7\. Confirm that only intended files were modified.

8\. Document test failures, pre-existing issues, and environment limitations separately.

Do not silently fix unrelated test failures.

Do not push changes without explicit approval.

\*\*

**## Phase 8: Code Quality and Performance\*\***

**\*\*### Prompt 27 — Review Code Quality\*\***

Review the modified code as a senior Flutter developer.

Focus on:

\\- SOLID principles

\\- Separation of concerns

\\- Naming

\\- Readability

\\- Testability

\\- Error handling

\\- Unnecessary duplication

\\- Unnecessary abstractions

Only recommend changes that provide a practical benefit.

**\*\*### Prompt 28 — Review Widget Rebuilds\*\***

Review the affected widgets for unnecessary rebuilds.

Check:

\\- Provider scope

\\- Widget responsibilities

\\- State consumption

\\- Search field updates

\\- Loading indicators

\\- List rendering

Do not optimize prematurely or change behavior without tests.

**\*\*### Prompt 29 — Review Platform Compatibility\*\***

Review the changes for Android and iOS compatibility.

Pay attention to:

\\- Permissions

\\- Location services

\\- Native configuration

\\- Deployment target

\\- Simulator behavior

\\- Release configuration

Clearly distinguish verified issues from assumptions.

**\*\*---\*\***

**\*\*## Phase 8: Documentation\*\***

**\*\*### Prompt 30 — Update README\*\***

Review the project implementation and prepare a professional README suitable for a senior Flutter developer.

Include:

\\- Project overview

\\- Features

\\- Architecture

\\- Riverpod usage

\\- API setup

\\- Mock and live environments

\\- Offline caching

\\- Location behavior

\\- Testing commands

\\- Known limitations

\\- Possible future improvements

Do not document features that are not implemented or verified.

**\*\*### Prompt 31 — Update CLAUDE.md\*\***

Create development guidelines for AI-assisted work on this project.

Include:

\\- Architecture rules

\\- Riverpod conventions

\\- Networking guidelines

\\- Error handling

\\- Testing expectations

\\- Location behavior

\\- Offline caching rules

\\- Git hygiene

\\- Definition of done

The guidelines should be practical and aligned with the existing codebase.

**\*\*### Prompt 32 — Document Lessons Learned\*\***

Document the important technical lessons from the implementation.

For each issue, describe:

\\- Problem

\\- Root cause

\\- Solution

\\- Verification

\\- Lesson learned

Clearly separate confirmed findings from assumptions and environment limitations.

**\*\*### Prompt 33 — Document AI Prompts\*\***

Review the development history and organize the AI prompts into meaningful phases.

Keep the prompts understandable to another developer and avoid including:

\\- API keys

\\- Personal information

\\- Local machine-specific paths

\\- Unverified claims

\\- Sensitive configuration

**\*\*---\*\***



\*\*---

**## AI Review Checklist\*\***

Before accepting an AI-generated change:

\\- [ ] Existing code was reviewed first.

\\- [ ] The change follows the current architecture.

\\- [ ] No unnecessary dependency was added.

\\- [ ] Business logic is not placed inside widgets.

\\- [ ] Error and loading states are handled.

\\- [ ] Relevant tests were added or updated.

\\- [ ] Platform-specific behavior was considered.

\\- [ ] No secrets were introduced.

\\- [ ] Formatting and static analysis were run.

\\- [ ] The final Git diff was reviewed.

\- [ ] Hive encryption status was verified against the source code.

\- [ ] Hive encryption keys are not hardcoded.

\- [ ] \`flutter_secure_storage\` usage was reviewed.

\- [ ] Existing Hive data and migration risks were considered.

\- [ ] Jailbreak and Root detection claims were verified before documentation.

\- [ ] Security limitations and false-positive risks were documented.

\- [ ] No sensitive information was added to logs or documentation.



**\*\*---\*\***

**\*\*## General Prompt Template\*\***

Use the following template for future development tasks:

\\> Review the existing implementation before making changes.

\\>

\\> Understand the current architecture, state management, dependencies, and tests.

\\>

\\> Implement only the requested behavior while following existing project conventions.

\\>

\\> Avoid unrelated refactoring and unnecessary dependencies.

\\>

\\> Handle loading, success, empty, and failure states.

\\>

\\> Write or update regression tests for the affected behavior.

\\>

\\> Run formatting, static analysis, and relevant tests.

\\>

\\> Clearly report modified files, test results, assumptions, and any remaining limitations.
