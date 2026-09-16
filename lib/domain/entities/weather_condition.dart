/// A provider-agnostic classification of weather conditions.
///
/// Mapping a specific provider's representation (e.g. OpenWeatherMap's
/// numeric condition codes) onto this enum is the data layer's job —
/// this file must never reference OpenWeatherMap-specific concepts.
enum WeatherCondition {
  clear,
  clouds,
  rain,
  drizzle,
  thunderstorm,
  snow,
  atmosphere,
  unknown,
}
