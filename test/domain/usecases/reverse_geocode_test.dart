import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/error/failures.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/repositories/geocoding_repository.dart';
import 'package:weather_now_flutter/domain/usecases/reverse_geocode.dart';

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

void main() {
  late MockGeocodingRepository mockRepository;
  late ReverseGeocode useCase;

  const pune = CitySuggestion(
    name: 'Pune',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 18.5213738,
    longitude: 73.8545071,
  );

  setUp(() {
    mockRepository = MockGeocodingRepository();
    useCase = ReverseGeocode(mockRepository);
  });

  test('returns the resolved city from the repository on success', () async {
    when(
      () => mockRepository.reverseGeocode(latitude: 18.52, longitude: 73.85),
    ).thenAnswer((_) async => const Right(pune));

    final result = await useCase(latitude: 18.52, longitude: 73.85);

    expect(result, const Right<Failure, CitySuggestion>(pune));
    verify(
      () => mockRepository.reverseGeocode(latitude: 18.52, longitude: 73.85),
    ).called(1);
  });

  test('returns the Failure from the repository on error', () async {
    const failure = RemoteDataFailure('No connection');
    when(
      () => mockRepository.reverseGeocode(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(latitude: 18.52, longitude: 73.85);

    expect(result, const Left<Failure, CitySuggestion>(failure));
  });
}
