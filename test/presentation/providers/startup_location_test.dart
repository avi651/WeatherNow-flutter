import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/data/datasources/geocoding_data_source.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/forecast.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/weather_repository.dart';
import 'package:weather_now_flutter/presentation/providers/active_city_provider.dart';
import 'package:weather_now_flutter/presentation/providers/current_location_city_provider.dart';
import 'package:weather_now_flutter/presentation/providers/home_weather_provider.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/presentation/providers/selected_city_provider.dart';

import '../utils/location_test_overrides.dart';

class MockLocationService extends Mock implements LocationService {}

class MockWeatherRepository extends Mock implements WeatherRepository {}

/// Stands in for the reverse-geocoding API: answers with whichever of its
/// cities is nearest the coordinates it is asked about, and knows nothing
/// about Mumbai/Pune/Bengaluru — so any of those showing up would mean a
/// static fallback leaked into the flow.
class NearestCityGeocodingDataSource implements GeocodingDataSource {
  static const _cities = [
    {'name': 'London', 'country': 'GB', 'lat': 51.5072, 'lon': -0.1276},
    {'name': 'Sydney', 'country': 'AU', 'lat': -33.8688, 'lon': 151.2093},
    {'name': 'Nairobi', 'country': 'KE', 'lat': -1.2921, 'lon': 36.8219},
  ];

  @override
  Future<List<Map<String, dynamic>>> searchCities({
    required String query,
  }) async => const [];

  @override
  Future<List<Map<String, dynamic>>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    Map<String, Object> nearest = _cities.first;
    var best = double.infinity;
    for (final city in _cities) {
      final dLat = (city['lat']! as double) - latitude;
      final dLon = (city['lon']! as double) - longitude;
      final distance = dLat * dLat + dLon * dLon;
      if (distance < best) {
        best = distance;
        nearest = city;
      }
    }
    return [Map<String, dynamic>.from(nearest)];
  }
}

void main() {
  const london = CitySuggestion(
    name: 'London',
    country: 'GB',
    latitude: 51.5,
    longitude: -0.12,
  );

  ProviderContainer build({FakeLastSearchedCityStore? store}) {
    final container = ProviderContainer(
      overrides: [...locationTestOverrides(store: store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('restores the saved city as the startup selection', () {
    final container = build(store: FakeLastSearchedCityStore(london));

    expect(container.read(selectedCityProvider), london);
  });

  test('with no saved city the startup selection is empty', () {
    final container = build(store: FakeLastSearchedCityStore());

    expect(container.read(selectedCityProvider), isNull);
  });

  group('startup weather source', () {
    late MockLocationService locationService;
    late MockWeatherRepository weatherRepository;

    final weather = CurrentWeather(
      temperatureCelsius: 15,
      feelsLikeCelsius: 14,
      humidityPercent: 70,
      pressureHpa: 1010,
      windSpeedMetersPerSecond: 4,
      condition: WeatherCondition.clouds,
      description: 'overcast',
      observedAt: DateTime.utc(2026, 9, 19),
    );

    setUpAll(() => registerFallbackValue(weather));

    setUp(() {
      locationService = MockLocationService();
      weatherRepository = MockWeatherRepository();
      when(
        () => weatherRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(weather));
      when(
        () => weatherRepository.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(Forecast(entries: const [])));
    });

    ProviderContainer buildFor(
      DeviceLocation device, {
      FakeLastSearchedCityStore? store,
    }) {
      when(
        () => locationService.getCurrentLocation(),
      ).thenAnswer((_) async => Right(device));
      final container = ProviderContainer(
        overrides: [
          ...locationTestOverrides(store: store),
          locationServiceProvider.overrideWithValue(locationService),
          weatherRepositoryProvider.overrideWithValue(weatherRepository),
          // The real repository and mapping run; only the network is faked.
          geocodingDataSourceProvider.overrideWithValue(
            NearestCityGeocodingDataSource(),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    for (final (device, expectedCity) in [
      (const DeviceLocation(latitude: 51.5, longitude: -0.13), 'London'),
      (const DeviceLocation(latitude: -33.87, longitude: 151.2), 'Sydney'),
      (const DeviceLocation(latitude: -1.29, longitude: 36.82), 'Nairobi'),
    ]) {
      test('coordinates near $expectedCity resolve to $expectedCity', () async {
        final container = buildFor(device);

        await container.read(homeWeatherProvider.future);
        final city = await container.read(currentLocationCityProvider.future);

        expect(city?.name, expectedCity);
        expect(container.read(activeCityProvider)?.name, expectedCity);
        // Weather is fetched for the device's own coordinates.
        verify(
          () => weatherRepository.getCurrentWeather(
            latitude: device.latitude,
            longitude: device.longitude,
          ),
        ).called(1);
      });
    }

    test('a saved city is fetched by its own coordinates without asking '
        'the device for a location', () async {
      final container = buildFor(
        const DeviceLocation(latitude: -33.87, longitude: 151.2),
        store: FakeLastSearchedCityStore(london),
      );

      await container.read(homeWeatherProvider.future);

      expect(container.read(activeCityProvider)?.name, 'London');
      verifyNever(() => locationService.getCurrentLocation());
      verify(
        () => weatherRepository.getCurrentWeather(
          latitude: london.latitude,
          longitude: london.longitude,
        ),
      ).called(1);
    });

    test(
      'the device-location button still overrides a restored city',
      () async {
        const device = DeviceLocation(latitude: -33.87, longitude: 151.2);
        final container = buildFor(
          device,
          store: FakeLastSearchedCityStore(london),
        );
        await container.read(homeWeatherProvider.future);

        container.read(selectedCityProvider.notifier).useDeviceLocation();
        await container.read(homeWeatherProvider.future);

        verify(() => locationService.getCurrentLocation()).called(1);
        verify(
          () => weatherRepository.getCurrentWeather(
            latitude: device.latitude,
            longitude: device.longitude,
          ),
        ).called(1);
      },
    );

    group('last searched city vs. the Current Location button', () {
      const pune = CitySuggestion(
        name: 'Pune',
        state: 'Maharashtra',
        country: 'IN',
        latitude: 18.52,
        longitude: 73.85,
      );
      const sydneyDevice = DeviceLocation(latitude: -33.87, longitude: 151.2);

      /// A second container over the same store stands in for an app
      /// restart: Riverpod state is gone, only persisted data remains.
      ProviderContainer restart(FakeLastSearchedCityStore store) =>
          buildFor(sydneyDevice, store: store);

      test('search Pune -> Current Location -> restart detects the device '
          'location instead of restoring Pune', () async {
        final store = FakeLastSearchedCityStore();
        final session = buildFor(sydneyDevice, store: store);

        session
            .read(selectedCityProvider.notifier)
            .select(pune, remember: true);
        expect(store.city, pune);

        session.read(selectedCityProvider.notifier).useDeviceLocation();
        expect(store.city, isNull);

        clearInteractions(locationService);
        final relaunched = restart(store);
        expect(relaunched.read(selectedCityProvider), isNull);

        await relaunched.read(homeWeatherProvider.future);
        verify(() => locationService.getCurrentLocation()).called(1);
        verify(
          () => weatherRepository.getCurrentWeather(
            latitude: sydneyDevice.latitude,
            longitude: sydneyDevice.longitude,
          ),
        ).called(1);
      });

      test('search Pune -> restart (no Current Location tap) restores Pune '
          'without asking the device', () async {
        final store = FakeLastSearchedCityStore();
        buildFor(
          sydneyDevice,
          store: store,
        ).read(selectedCityProvider.notifier).select(pune, remember: true);

        final relaunched = restart(store);
        await relaunched.read(homeWeatherProvider.future);

        expect(relaunched.read(selectedCityProvider), pune);
        verifyNever(() => locationService.getCurrentLocation());
      });

      test('Current Location overrides a selected city in the same session '
          'and clears the persisted one', () async {
        final store = FakeLastSearchedCityStore(pune);
        final container = buildFor(sydneyDevice, store: store);
        await container.read(homeWeatherProvider.future);
        expect(container.read(selectedCityProvider), pune);

        container.read(selectedCityProvider.notifier).useDeviceLocation();
        await container.read(homeWeatherProvider.future);

        expect(container.read(selectedCityProvider), isNull);
        expect(store.city, isNull);
        verify(
          () => weatherRepository.getCurrentWeather(
            latitude: sydneyDevice.latitude,
            longitude: sydneyDevice.longitude,
          ),
        ).called(1);
      });

      test('selecting a favorite (no remember) neither saves nor replaces '
          'the persisted last searched city', () {
        final store = FakeLastSearchedCityStore(london);
        final container = buildFor(sydneyDevice, store: store);

        container.read(selectedCityProvider.notifier).select(pune);

        expect(container.read(selectedCityProvider), pune);
        expect(store.city, london);
      });
    });
  });
}
