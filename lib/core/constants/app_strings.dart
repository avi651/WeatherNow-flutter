/// Every user-facing string in the app, in one place.
///
/// Internal values (API URLs, Hive keys, enum values, logging text) do not
/// belong here — only text a user can read on screen.
abstract final class AppStrings {
  // App
  static const appName = 'WeatherNow';
  static const appNamePrefix = 'Weather';
  static const appNameSuffix = 'Now';
  static const appTagline = 'Know today. Plan better.';

  // Navigation
  static const navHome = 'Home';
  static const navFavorites = 'Favorites';
  static const navSettings = 'Settings';

  // Common
  static const retry = 'Retry';
  static const loadingWeather = 'Loading weather…';
  static const currentLocation = 'Current Location';
  static const today = 'Today';
  static const unknownValue = '—';

  // Home
  static const fiveDayForecast = '5 Day Forecast';
  static const genericError = 'Something went wrong. Please try again.';
  static const currentLocationError = 'Could not get your current location.';

  // Search
  static const searchPlaceholderPhrases = <String>[
    'Search Your City',
    'Search Mumbai',
    'Search London',
    'Search New York',
    'Search Tokyo',
    'Search Paris',
  ];
  static const clearSearch = 'Clear search';

  static String noCitiesFound(String query) => 'No cities found for "$query"';

  // Weather details
  static const humidity = 'Humidity';
  static const wind = 'Wind';
  static const pressure = 'Pressure';
  static const feelsLike = 'Feels like';
  static const rain = 'Rain';

  static String feelsLikeValue(String temperature) => '$feelsLike $temperature';

  static String forecastDetails(String label) => '$label forecast details';

  // Forecast detail
  static const noDetailedForecast =
      'No detailed forecast available for this day.';

  static String highLow(String high, String low) => 'High $high · Low $low';

  // Calendar
  static const weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // Offline
  static const offlineBannerPrefix = "You're offline — showing data from ";
  static const offlineShowingSavedWeather =
      "You're offline — showing your last saved weather.";

  // Favorites
  static const favoritesTitle = 'Favorites';
  static const favoritesLoadFailed = 'Failed to load favorites.';
  static const noFavoritesTitle = 'No favorite cities yet';
  static const noFavoritesHint =
      "Tap the star on a city's weather to save it here.";
  static const addToFavorites = 'Add to favorites';
  static const removeFromFavorites = 'Remove from favorites';
  static const removeFromFavoritesMenu = 'Remove from Favorites';
  static const setAsHomeLocation = 'Set as Home location';
  static const moreActions = 'More actions';
  static const noCachedWeatherYet = 'No cached weather yet';
  static const offlineAccess = 'Offline Access';
  static const syncNow = 'Sync Now';
  static const syncing = 'Syncing…';
  static const favoritesCacheHint =
      'Your favorites will be cached here for offline access.';

  static String lastUpdated(String time) => 'Last updated $time';
  static String cachedAt(String time) => 'cached $time';

  // Settings
  static const settingsTitle = 'Settings';
  static const appearance = 'Appearance';
  static const themeSystem = 'System';
  static const themeLight = 'Light';
  static const themeDark = 'Dark';
  static const units = 'Units';
  static const celsius = 'Celsius (°C)';
  static const fahrenheit = 'Fahrenheit (°F)';
  static const offlineData = 'Offline Data';
  static const offlineDataToggleTitle = 'Store weather for offline access';
  static const offlineDataToggleSubtitle =
      'Keep the last fetched weather available without a connection.';
  static const locationAndPermissions = 'Location & Permissions';
  static const permissionChecking = 'Checking…';
  static const permissionUnknown = 'Unknown';
  static const permissionAllowed = 'Allowed';
  static const permissionNotAllowedYet = 'Not allowed yet';
  static const permissionDenied = 'Denied — enable from system settings';
  static const locationServicesOff = 'Location services are off';
  static const manageLocationPermission = 'Manage Location Permission';
  static const about = 'About';
  static const appVersion = 'App Version';

  // Errors
  static const locationServicesDisabled =
      'Location services are turned off. Please enable them to see weather for your location.';
  static const locationPermissionDenied = 'Location permission was denied.';
  static const locationPermissionDeniedForever =
      'Location permission is permanently denied. Enable it from system settings.';
  static const locationTimedOut =
      'Timed out while finding your location. Make sure location is '
      'available on this device, or search for a city instead.';
  static const noLocationForCoordinates =
      'No location found for the given coordinates.';
  static const requestTimedOut = 'The request timed out';
  static const requestCancelled = 'The request was cancelled';
  static const noInternet = 'No internet connection';
  static const unknownNetworkError = 'An unknown network error occurred';
  static const invalidApiKey = 'Invalid or unauthorized API key';
  static const rateLimitExceeded =
      'Too many requests — rate limit exceeded, please try again later';
  static const weatherServiceUnavailable =
      'The weather service is temporarily unavailable';
  static const serverError = 'The server returned an error';
  static const emptyWeatherResponse = 'Empty response from weather service';
  static const offlineDataTurnedOff = 'Offline data is turned off in Settings.';
  static const favoritesSyncFailed =
      'Could not sync favorites — check your connection.';
}
