
# WeatherNow

WeatherNow is a Flutter weather application that provides current weather conditions, multi-day forecasts, city search, favorite cities, and offline access to previously fetched weather data.

The app uses OpenWeatherMap for live weather and geocoding data. It also includes a mock environment so the application can be run and reviewed without an API key.

## Features

- Current weather and multi-day forecast
- Search cities using suggestions
- Reverse geocoding for current device location
- Favorite cities with weather information
- Offline weather access using Hive cache
- Configurable temperature units (°C/°F)
- Light, dark, and system themes
- Enable/disable offline data storage
- Restore the last searched city on startup
- User-friendly error messages and retry support
- Material and Cupertino platform-adaptive UI

## Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Riverpod 3
- **Networking:** Dio
- **Local Storage:** Hive
- **Architecture:** Clean Architecture-inspired layered structure
- **Testing:** flutter_test, mocktail, bloc_test where applicable
- **API:** OpenWeatherMap

## Prerequisites

- Flutter SDK with Dart SDK `^3.12.2`
- Android Emulator or iOS Simulator
- OpenWeatherMap API key for live data

Verify your Flutter setup:

```bash
flutter doctor
```

## Getting Started

Install dependencies:

```bash
flutter pub get
```

## Running the Application

### Mock Environment

Mock mode is the default and does not require an API key or network access.

```bash
flutter run --dart-define=ENV=mock
```

A plain `flutter run` also starts the application in mock mode.

Mock data is loaded from:

```text
assets/mock/
```

### Live Development Environment

```bash
flutter run \
  --dart-define=ENV=dev \
  --dart-define=BASE_URL=https://api.openweathermap.org/data/2.5/ \
  --dart-define=GEOCODING_BASE_URL=https://api.openweathermap.org/geo/1.0 \
  --dart-define=API_KEY=YOUR_OPENWEATHERMAP_KEY
```

### Production Configuration

```bash
flutter run --release \
  --dart-define=ENV=prod \
  --dart-define=BASE_URL=https://api.openweathermap.org/data/2.5/ \
  --dart-define=GEOCODING_BASE_URL=https://api.openweathermap.org/geo/1.0 \
  --dart-define=API_KEY=YOUR_OPENWEATHERMAP_KEY
```

Replace `flutter run` with the relevant build command when generating an application artifact:

```bash
flutter build apk
flutter build ios
```

> The project currently uses compile-time `--dart-define` configuration. Native Android and iOS flavors are not configured, so do not pass the `--flavor` argument.

## Environment Configuration

Configuration is managed in:

```text
lib/core/config/app_environment.dart
```

| Define | Purpose | Default |
|---|---|---|
| `ENV` | Selects mock or live environment | `mock` |
| `BASE_URL` | Weather API base URL | Empty |
| `GEOCODING_BASE_URL` | Geocoding API base URL | OpenWeatherMap URL |
| `API_KEY` | OpenWeatherMap API key | Empty |

Only the exact value `mock` selects mock mode. Other values use the live API configuration.

**Never commit API keys to the repository.** Use `--dart-define` for local configuration.

## API Endpoints

The application uses the following OpenWeatherMap endpoints:

- Current weather:
  `GET /data/2.5/weather`
- Five-day forecast:
  `GET /data/2.5/forecast`
- Direct geocoding:
  `/geo/1.0/direct`
- Reverse geocoding:
  `/geo/1.0/reverse`

The API key is passed through compile-time configuration and is redacted from request logs.

## Architecture

The project follows a layered architecture inspired by Clean Architecture.

```text
lib/
├── app/
│   └── Application widget and app-level configuration
├── core/
│   ├── Configuration
│   ├── Constants and user-facing strings
│   ├── Error handling
│   ├── Networking
│   ├── Location services
│   └── Theme
├── data/
│   ├── API services
│   ├── Local data sources
│   ├── Models
│   └── Repository implementations
├── domain/
│   ├── Entities
│   ├── Repository interfaces
│   └── Use cases
├── di/
│   └── Riverpod dependency configuration
└── presentation/
    ├── Screens
    ├── Widgets
    ├── Providers
    └── UI formatting utilities
```

### Domain Layer

Contains business-focused entities, repository contracts, and use cases.

The domain layer should remain independent of Flutter-specific implementation details wherever possible.

### Data Layer

Contains:

- Dio-based API services
- Mock data sources
- Hive data sources
- JSON models
- Repository implementations
- Error-to-failure mapping

Repositories expose results using:

```dart
Either<Failure, T>
```

Exceptions should not cross repository boundaries into the presentation layer.

### Presentation Layer

The presentation layer contains screens, reusable widgets, and Riverpod providers responsible for managing UI state and user interactions.

## Riverpod State Management

Dependency injection is centralized in:

```text
lib/di/providers.dart
```

The application uses Riverpod providers and notifiers for:

- Home weather and forecast data
- Active location
- City search
- Favorites
- Application settings
- Connectivity
- Weather freshness
- Offline synchronization

The active location determines whether the app displays a searched city, a favorite city, or the device's current location.

## Location and Startup Behavior

On first launch:

1. If a last-searched city exists, it is restored.
2. Otherwise, the app requests the device location.
3. The coordinates are reverse-geocoded into a city.
4. Weather data is fetched for that location.

Location requests have a timeout and a visible failure state. This prevents the application from remaining indefinitely on a loading screen, especially on iOS Simulators where a location may not be configured.

The Current Location button:

- Requests the required permission
- Fetches the device's current coordinates
- Performs reverse geocoding
- Updates the search field and weather card
- Shows loading only on the location control
- Handles permission and location failures

## Offline Storage

Hive is used for local persistence.

| Box | Stored Data |
|---|---|
| `favorites` | Favorite cities |
| `current_weather_cache` | Current weather by location |
| `forecast_cache` | Forecast data by location |
| `settings` | User preferences |

The **Store weather for offline access** setting controls caching behavior.

When enabled:

- Successful API responses are stored in Hive.
- Failed requests can fall back to cached data.
- Cached data includes freshness information.
- Favorites can be synchronized using the sync action.

When disabled:

- New weather data is not written to Hive.
- Cached fallback is not used.
- The setting is persisted across application restarts.

A failed request must never overwrite valid cached data.

## Error Handling

Technical exceptions are mapped to safe, user-friendly failures.

Examples include:

- `401/403`: Invalid or unauthorized API key
- `429`: Rate limit exceeded
- `5xx`: Service unavailable
- Timeout: Request timed out
- Network failure: Connection problem
- Parsing failure: Invalid response data

Raw Dio errors, parser exceptions, API keys, and internal implementation details must not be displayed directly to users.

## Testing

Run static analysis:

```bash
flutter analyze
```

Run all tests:

```bash
flutter test
```

Tests are organized to mirror the application structure:

```text
test/
├── core/
├── data/
├── domain/
├── presentation/
└── di/
```

The test suite covers:

- API client and exception mapping
- JSON model parsing
- Repository behavior
- Hive data sources
- Use cases
- Riverpod providers
- Search and location flows
- Favorites and settings
- Offline fallback
- User-facing error messages
- Widget and screen behavior

Every bug fix should include a regression test where practical.

## Performance Review

Performance checks focused on:

- Widget rebuilds
- Search field isolation
- Home screen rendering
- Favorites scrolling
- Unit changes
- Offline and connectivity transitions

Performance measurements were collected using widget tests and profile-mode integration tests on an Android emulator.

The measurements are intended for relative comparison. Emulator rendering does not represent real-device performance exactly. Further profiling on a physical device would be useful before making rendering optimizations.

## Security Considerations

- API keys are supplied using `--dart-define`.
- Secrets must not be committed to Git.
- API keys are redacted in network logs.
- User-facing failures must not expose technical exception details.
- Local configuration files containing secrets should remain outside version control.

## Development Guidelines

- Keep changes focused on the requested feature or bug.
- Follow the existing architecture and code style.
- Prefer reusable widgets and single-responsibility classes.
- Keep user-facing strings in `app_strings.dart`.
- Add regression tests for bug fixes.
- Run `dart format` on modified Dart files.
- Run `flutter analyze` and relevant tests before committing.
- Avoid unnecessary refactoring or changes outside the scope of the task.


## AI-Assisted Development

AI assistance was used during development for code reviews, test creation, debugging, UI improvements, and documentation.

The development prompts and lessons learned are documented separately:

- `CALUDE_PROMPTS.md`
- `CALUDE_FAILURE_FIX_LESSONS.md`

The AI-generated changes were reviewed against the existing architecture, application behavior, and test results rather than being accepted without verification.