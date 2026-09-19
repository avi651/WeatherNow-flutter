/// The app's theme preference. Kept as its own domain-pure enum — rather
/// than persisting Flutter's own `ThemeMode` directly — so this layer
/// stays free of Flutter imports; mapping this onto `ThemeMode` is the
/// presentation layer's job.
enum AppThemeMode { system, light, dark }
