import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/config/app_environment.dart';
import 'package:weather_now_flutter/core/constants/weather_api_endpoints.dart';
import 'package:weather_now_flutter/core/network/api_client.dart';
import 'package:weather_now_flutter/core/network/weather_api_params.dart';
import 'package:weather_now_flutter/data/datasources/weather_api_service.dart';
import 'package:weather_now_flutter/data/datasources/weather_mock_data_source.dart';
import 'package:weather_now_flutter/data/repositories/weather_repository_impl.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/forecast.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/weather_repository.dart';
import 'package:weather_now_flutter/domain/usecases/get_current_weather.dart';
import 'package:weather_now_flutter/domain/usecases/get_forecast.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockWeatherApiService extends Mock implements WeatherApiService {}

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  // Needed for the mock-mode test below, which loads the real bundled
  // mock JSON assets through `rootBundle` rather than a mocked message
  // handler.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('provider graph builds without overrides', () {
    test('weatherApiServiceProvider provides a WeatherApiService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(weatherApiServiceProvider),
        isA<WeatherApiService>(),
      );
    });

    test('weatherRepositoryProvider provides a WeatherRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(weatherRepositoryProvider),
        isA<WeatherRepository>(),
      );
    });

    test('weatherRepositoryProvider provides a WeatherRepositoryImpl', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(weatherRepositoryProvider),
        isA<WeatherRepositoryImpl>(),
      );
    });

    test('getCurrentWeatherProvider provides a GetCurrentWeather', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(getCurrentWeatherProvider),
        isA<GetCurrentWeather>(),
      );
    });

    test('getForecastProvider provides a GetForecast', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(getForecastProvider), isA<GetForecast>());
    });
  });

  group('weatherApiServiceProvider wiring', () {
    test(
      'uses the overridden apiClientProvider and AppEnvironment.apiKey',
      () async {
        final mockApiClient = MockApiClient();
        final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(mockApiClient)],
        );
        addTearDown(container.dispose);

        when(
          () => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Right(
            Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(
                path: WeatherApiEndpoints.currentWeather,
              ),
              statusCode: 200,
              data: const {'temp': 21.5},
            ),
          ),
        );

        final service = container.read(weatherApiServiceProvider);
        final result = await service.getCurrentWeather(
          latitude: 1,
          longitude: 2,
        );

        expect(result, {'temp': 21.5});
        verify(
          () => mockApiClient.get<Map<String, dynamic>>(
            WeatherApiEndpoints.currentWeather,
            queryParameters: WeatherApiParams.coordinates(
              latitude: 1,
              longitude: 2,
              apiKey: AppEnvironment.apiKey,
            ),
          ),
        ).called(1);
      },
    );
  });

  group('weatherDataSourceProvider wiring', () {
    test(
      'resolves to WeatherMockDataSource when isMockEnvironmentProvider is true',
      () {
        final container = ProviderContainer(
          overrides: [isMockEnvironmentProvider.overrideWithValue(true)],
        );
        addTearDown(container.dispose);

        expect(
          container.read(weatherDataSourceProvider),
          isA<WeatherMockDataSource>(),
        );
      },
    );

    test('resolves to the weatherApiServiceProvider instance when '
        'isMockEnvironmentProvider is false', () {
      final mockApiService = MockWeatherApiService();
      final container = ProviderContainer(
        overrides: [
          isMockEnvironmentProvider.overrideWithValue(false),
          weatherApiServiceProvider.overrideWithValue(mockApiService),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(weatherDataSourceProvider), same(mockApiService));
    });
  });

  group('weatherRepositoryProvider mock-mode wiring', () {
    test('reads the bundled mock JSON assets end-to-end when '
        'isMockEnvironmentProvider is true', () async {
      final container = ProviderContainer(
        overrides: [isMockEnvironmentProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);

      final repository = container.read(weatherRepositoryProvider);
      final result = await repository.getCurrentWeather(
        latitude: 1,
        longitude: 2,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('expected Right, got $failure'),
        (weather) => expect(weather.condition, WeatherCondition.rain),
      );
    });
  });

  group('weatherRepositoryProvider wiring', () {
    test(
      'uses the overridden weatherApiServiceProvider when not in mock mode',
      () async {
        final mockApiService = MockWeatherApiService();
        final container = ProviderContainer(
          overrides: [
            isMockEnvironmentProvider.overrideWithValue(false),
            weatherApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );
        addTearDown(container.dispose);

        when(
          () => mockApiService.getCurrentWeather(latitude: 1, longitude: 2),
        ).thenAnswer(
          (_) async => {
            'weather': [
              {
                'id': 800,
                'main': 'Clear',
                'description': 'clear sky',
                'icon': '01d',
              },
            ],
            'main': {
              'temp': 21.5,
              'feels_like': 20.0,
              'pressure': 1013,
              'humidity': 60,
            },
            'wind': {'speed': 3.2},
            'dt': 1000,
          },
        );

        final repository = container.read(weatherRepositoryProvider);
        final result = await repository.getCurrentWeather(
          latitude: 1,
          longitude: 2,
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('expected Right'),
          (weather) => expect(weather.condition, WeatherCondition.clear),
        );
        verify(
          () => mockApiService.getCurrentWeather(latitude: 1, longitude: 2),
        ).called(1);
      },
    );
  });

  group('getCurrentWeatherProvider wiring', () {
    test('uses the overridden weatherRepositoryProvider', () async {
      final mockRepository = MockWeatherRepository();
      final container = ProviderContainer(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final weather = CurrentWeather(
        temperatureCelsius: 21.5,
        feelsLikeCelsius: 20.0,
        humidityPercent: 60,
        pressureHpa: 1013,
        windSpeedMetersPerSecond: 3.2,
        condition: WeatherCondition.clear,
        description: 'clear sky',
        observedAt: DateTime.utc(2026, 9, 16),
      );

      when(
        () => mockRepository.getCurrentWeather(latitude: 1, longitude: 2),
      ).thenAnswer((_) async => Right(weather));

      final useCase = container.read(getCurrentWeatherProvider);
      final result = await useCase(latitude: 1, longitude: 2);

      expect(result, Right(weather));
      verify(
        () => mockRepository.getCurrentWeather(latitude: 1, longitude: 2),
      ).called(1);
    });
  });

  group('getForecastProvider wiring', () {
    test('uses the overridden weatherRepositoryProvider', () async {
      final mockRepository = MockWeatherRepository();
      final container = ProviderContainer(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final forecast = Forecast(entries: const []);

      when(
        () => mockRepository.getForecast(latitude: 1, longitude: 2),
      ).thenAnswer((_) async => Right(forecast));

      final useCase = container.read(getForecastProvider);
      final result = await useCase(latitude: 1, longitude: 2);

      expect(result, Right(forecast));
      verify(
        () => mockRepository.getForecast(latitude: 1, longitude: 2),
      ).called(1);
    });
  });
}
