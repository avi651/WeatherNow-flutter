import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/error/weather_api_exception.dart';
import 'package:weather_now_flutter/data/datasources/weather_api_service.dart';
import 'package:weather_now_flutter/data/repositories/weather_repository_impl.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';

class MockWeatherApiService extends Mock implements WeatherApiService {}

void main() {
  late MockWeatherApiService mockApiService;
  late WeatherRepositoryImpl repository;

  const latitude = 12.34;
  const longitude = 56.78;

  setUp(() {
    mockApiService = MockWeatherApiService();
    repository = WeatherRepositoryImpl(dataSource: mockApiService);
  });

  Map<String, dynamic> currentWeatherJson() => {
    'weather': [
      {'id': 800, 'main': 'Clear', 'description': 'clear sky', 'icon': '01d'},
    ],
    'main': {
      'temp': 21.5,
      'feels_like': 20.0,
      'pressure': 1013,
      'humidity': 60,
    },
    'wind': {'speed': 3.2},
    'dt': 1789558849,
  };

  Map<String, dynamic> forecastJson() => {
    'list': [
      {
        'dt': 1789560000,
        'main': {
          'temp': 25.0,
          'feels_like': 24.0,
          'pressure': 1010,
          'humidity': 55,
        },
        'weather': [
          {
            'id': 500,
            'main': 'Rain',
            'description': 'light rain',
            'icon': '10d',
          },
        ],
        'pop': 0.4,
      },
    ],
  };

  group('WeatherRepositoryImpl.getCurrentWeather', () {
    test('returns a mapped CurrentWeather on success', () async {
      when(
        () => mockApiService.getCurrentWeather(
          latitude: latitude,
          longitude: longitude,
        ),
      ).thenAnswer((_) async => currentWeatherJson());

      final result = await repository.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (weather) {
        expect(weather.temperatureCelsius, 21.5);
        expect(weather.condition, WeatherCondition.clear);
        expect(weather.humidityPercent, 60);
      });
    });

    test('returns a RemoteDataFailure carrying the status code when the '
        'data source throws', () async {
      when(
        () => mockApiService.getCurrentWeather(
          latitude: latitude,
          longitude: longitude,
        ),
      ).thenThrow(WeatherApiException('Not found', statusCode: 404));

      final result = await repository.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<RemoteDataFailure>());
        expect(failure.message, 'Not found');
        expect((failure as RemoteDataFailure).statusCode, 404);
      }, (_) => fail('expected Left'));
    });

    test(
      'returns a DataParsingFailure when the response is malformed',
      () async {
        when(
          () => mockApiService.getCurrentWeather(
            latitude: latitude,
            longitude: longitude,
          ),
        ).thenAnswer((_) async => <String, dynamic>{'unexpected': 'shape'});

        final result = await repository.getCurrentWeather(
          latitude: latitude,
          longitude: longitude,
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<DataParsingFailure>()),
          (_) => fail('expected Left'),
        );
      },
    );
  });

  group('WeatherRepositoryImpl.getForecast', () {
    test('returns a mapped Forecast on success', () async {
      when(
        () => mockApiService.getForecast(
          latitude: latitude,
          longitude: longitude,
        ),
      ).thenAnswer((_) async => forecastJson());

      final result = await repository.getForecast(
        latitude: latitude,
        longitude: longitude,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (forecast) {
        expect(forecast.entries, hasLength(1));
        expect(forecast.entries.single.condition, WeatherCondition.rain);
        expect(forecast.entries.single.precipitationProbability, 0.4);
      });
    });

    test('returns a RemoteDataFailure when the data source throws', () async {
      when(
        () => mockApiService.getForecast(
          latitude: latitude,
          longitude: longitude,
        ),
      ).thenThrow(WeatherApiException('Server error', statusCode: 500));

      final result = await repository.getForecast(
        latitude: latitude,
        longitude: longitude,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<RemoteDataFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test(
      'returns a DataParsingFailure when the response is malformed',
      () async {
        when(
          () => mockApiService.getForecast(
            latitude: latitude,
            longitude: longitude,
          ),
        ).thenAnswer((_) async => <String, dynamic>{'unexpected': 'shape'});

        final result = await repository.getForecast(
          latitude: latitude,
          longitude: longitude,
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<DataParsingFailure>()),
          (_) => fail('expected Left'),
        );
      },
    );
  });
}
