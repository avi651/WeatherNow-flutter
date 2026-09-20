class AppEnvironment {
  const AppEnvironment._();

  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'mock',
  );

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '',
  );

  static const String geocodingBaseUrl = String.fromEnvironment(
    'GEOCODING_BASE_URL',
    defaultValue: '',
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  static bool get isMock => environment == 'mock';

  static bool get isDev => environment == 'dev';

  static bool get isProduction => environment == 'prod';
}
