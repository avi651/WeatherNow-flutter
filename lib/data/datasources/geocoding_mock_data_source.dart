import 'geocoding_data_source.dart';

/// A bundled list of major world cities, filtered in-memory by name
/// prefix — used in place of [GeocodingApiService] when
/// [AppEnvironment.isMock] is true, so city search works out of the box
/// without a real API key configured (mirrors [WeatherMockDataSource]'s
/// role for weather/forecast).
///
/// This is necessarily a finite list, not a live worldwide index — a real
/// API key (dev/prod env) routes through [GeocodingApiService] instead,
/// which can resolve any city OpenWeatherMap's geocoding index knows
/// about.
class GeocodingMockDataSource implements GeocodingDataSource {
  const GeocodingMockDataSource();

  static const _cities = <Map<String, dynamic>>[
    // India
    {
      'name': 'Mumbai',
      'state': 'Maharashtra',
      'country': 'IN',
      'lat': 19.0760,
      'lon': 72.8777,
    },
    {
      'name': 'Pune',
      'state': 'Maharashtra',
      'country': 'IN',
      'lat': 18.5213738,
      'lon': 73.8545071,
    },
    {
      'name': 'New Delhi',
      'state': 'Delhi',
      'country': 'IN',
      'lat': 28.6139,
      'lon': 77.2090,
    },
    {
      'name': 'Bengaluru',
      'state': 'Karnataka',
      'country': 'IN',
      'lat': 12.9716,
      'lon': 77.5946,
    },
    {
      'name': 'Hyderabad',
      'state': 'Telangana',
      'country': 'IN',
      'lat': 17.3850,
      'lon': 78.4867,
    },
    {
      'name': 'Chennai',
      'state': 'Tamil Nadu',
      'country': 'IN',
      'lat': 13.0827,
      'lon': 80.2707,
    },
    {
      'name': 'Kolkata',
      'state': 'West Bengal',
      'country': 'IN',
      'lat': 22.5726,
      'lon': 88.3639,
    },
    {
      'name': 'Ahmedabad',
      'state': 'Gujarat',
      'country': 'IN',
      'lat': 23.0225,
      'lon': 72.5714,
    },
    {
      'name': 'Jaipur',
      'state': 'Rajasthan',
      'country': 'IN',
      'lat': 26.9124,
      'lon': 75.7873,
    },
    {
      'name': 'Surat',
      'state': 'Gujarat',
      'country': 'IN',
      'lat': 21.1702,
      'lon': 72.8311,
    },
    {
      'name': 'Lucknow',
      'state': 'Uttar Pradesh',
      'country': 'IN',
      'lat': 26.8467,
      'lon': 80.9462,
    },
    {
      'name': 'Chandigarh',
      'state': 'Chandigarh',
      'country': 'IN',
      'lat': 30.7333,
      'lon': 76.7794,
    },
    {
      'name': 'Kochi',
      'state': 'Kerala',
      'country': 'IN',
      'lat': 9.9312,
      'lon': 76.2673,
    },
    {
      'name': 'Nagpur',
      'state': 'Maharashtra',
      'country': 'IN',
      'lat': 21.1458,
      'lon': 79.0882,
    },
    {
      'name': 'Indore',
      'state': 'Madhya Pradesh',
      'country': 'IN',
      'lat': 22.7196,
      'lon': 75.8577,
    },
    // United Kingdom
    {
      'name': 'London',
      'state': 'England',
      'country': 'GB',
      'lat': 51.5072,
      'lon': -0.1276,
    },
    {
      'name': 'Liverpool',
      'state': 'England',
      'country': 'GB',
      'lat': 53.4084,
      'lon': -2.9916,
    },
    {
      'name': 'Manchester',
      'state': 'England',
      'country': 'GB',
      'lat': 53.4808,
      'lon': -2.2426,
    },
    {
      'name': 'Birmingham',
      'state': 'England',
      'country': 'GB',
      'lat': 52.4862,
      'lon': -1.8904,
    },
    {
      'name': 'Edinburgh',
      'state': 'Scotland',
      'country': 'GB',
      'lat': 55.9533,
      'lon': -3.1883,
    },
    // United States
    {
      'name': 'New York',
      'state': 'New York',
      'country': 'US',
      'lat': 40.7128,
      'lon': -74.0060,
    },
    {
      'name': 'Los Angeles',
      'state': 'California',
      'country': 'US',
      'lat': 34.0522,
      'lon': -118.2437,
    },
    {
      'name': 'Chicago',
      'state': 'Illinois',
      'country': 'US',
      'lat': 41.8781,
      'lon': -87.6298,
    },
    {
      'name': 'Houston',
      'state': 'Texas',
      'country': 'US',
      'lat': 29.7604,
      'lon': -95.3698,
    },
    {
      'name': 'San Francisco',
      'state': 'California',
      'country': 'US',
      'lat': 37.7749,
      'lon': -122.4194,
    },
    {
      'name': 'Seattle',
      'state': 'Washington',
      'country': 'US',
      'lat': 47.6062,
      'lon': -122.3321,
    },
    {
      'name': 'Miami',
      'state': 'Florida',
      'country': 'US',
      'lat': 25.7617,
      'lon': -80.1918,
    },
    {
      'name': 'Boston',
      'state': 'Massachusetts',
      'country': 'US',
      'lat': 42.3601,
      'lon': -71.0589,
    },
    // Canada
    {
      'name': 'Toronto',
      'state': 'Ontario',
      'country': 'CA',
      'lat': 43.6532,
      'lon': -79.3832,
    },
    {
      'name': 'Vancouver',
      'state': 'British Columbia',
      'country': 'CA',
      'lat': 49.2827,
      'lon': -123.1207,
    },
    {
      'name': 'Montreal',
      'state': 'Quebec',
      'country': 'CA',
      'lat': 45.5019,
      'lon': -73.5674,
    },
    // Europe
    {
      'name': 'Paris',
      'state': 'Ile-de-France',
      'country': 'FR',
      'lat': 48.8566,
      'lon': 2.3522,
    },
    {
      'name': 'Berlin',
      'state': 'Berlin',
      'country': 'DE',
      'lat': 52.5200,
      'lon': 13.4050,
    },
    {
      'name': 'Munich',
      'state': 'Bavaria',
      'country': 'DE',
      'lat': 48.1351,
      'lon': 11.5820,
    },
    {
      'name': 'Madrid',
      'state': 'Madrid',
      'country': 'ES',
      'lat': 40.4168,
      'lon': -3.7038,
    },
    {
      'name': 'Barcelona',
      'state': 'Catalonia',
      'country': 'ES',
      'lat': 41.3874,
      'lon': 2.1686,
    },
    {
      'name': 'Rome',
      'state': 'Lazio',
      'country': 'IT',
      'lat': 41.9028,
      'lon': 12.4964,
    },
    {
      'name': 'Milan',
      'state': 'Lombardy',
      'country': 'IT',
      'lat': 45.4642,
      'lon': 9.1900,
    },
    {
      'name': 'Amsterdam',
      'state': 'North Holland',
      'country': 'NL',
      'lat': 52.3676,
      'lon': 4.9041,
    },
    {
      'name': 'Zurich',
      'state': 'Zurich',
      'country': 'CH',
      'lat': 47.3769,
      'lon': 8.5417,
    },
    {
      'name': 'Vienna',
      'state': 'Vienna',
      'country': 'AT',
      'lat': 48.2082,
      'lon': 16.3738,
    },
    {
      'name': 'Lisbon',
      'state': 'Lisbon',
      'country': 'PT',
      'lat': 38.7223,
      'lon': -9.1393,
    },
    {
      'name': 'Dublin',
      'state': 'Leinster',
      'country': 'IE',
      'lat': 53.3498,
      'lon': -6.2603,
    },
    {
      'name': 'Stockholm',
      'state': 'Stockholm',
      'country': 'SE',
      'lat': 59.3293,
      'lon': 18.0686,
    },
    {
      'name': 'Oslo',
      'state': 'Oslo',
      'country': 'NO',
      'lat': 59.9139,
      'lon': 10.7522,
    },
    {
      'name': 'Copenhagen',
      'state': 'Capital Region',
      'country': 'DK',
      'lat': 55.6761,
      'lon': 12.5683,
    },
    {
      'name': 'Warsaw',
      'state': 'Masovian',
      'country': 'PL',
      'lat': 52.2297,
      'lon': 21.0122,
    },
    {
      'name': 'Moscow',
      'state': 'Moscow',
      'country': 'RU',
      'lat': 55.7558,
      'lon': 37.6173,
    },
    {
      'name': 'Athens',
      'state': 'Attica',
      'country': 'GR',
      'lat': 37.9838,
      'lon': 23.7275,
    },
    // Asia-Pacific
    {
      'name': 'Tokyo',
      'state': null,
      'country': 'JP',
      'lat': 35.6762,
      'lon': 139.6503,
    },
    {
      'name': 'Osaka',
      'state': null,
      'country': 'JP',
      'lat': 34.6937,
      'lon': 135.5023,
    },
    {
      'name': 'Seoul',
      'state': null,
      'country': 'KR',
      'lat': 37.5665,
      'lon': 126.9780,
    },
    {
      'name': 'Beijing',
      'state': null,
      'country': 'CN',
      'lat': 39.9042,
      'lon': 116.4074,
    },
    {
      'name': 'Shanghai',
      'state': null,
      'country': 'CN',
      'lat': 31.2304,
      'lon': 121.4737,
    },
    {
      'name': 'Hong Kong',
      'state': null,
      'country': 'HK',
      'lat': 22.3193,
      'lon': 114.1694,
    },
    {
      'name': 'Singapore',
      'state': null,
      'country': 'SG',
      'lat': 1.3521,
      'lon': 103.8198,
    },
    {
      'name': 'Bangkok',
      'state': null,
      'country': 'TH',
      'lat': 13.7563,
      'lon': 100.5018,
    },
    {
      'name': 'Jakarta',
      'state': null,
      'country': 'ID',
      'lat': -6.2088,
      'lon': 106.8456,
    },
    {
      'name': 'Manila',
      'state': null,
      'country': 'PH',
      'lat': 14.5995,
      'lon': 120.9842,
    },
    {
      'name': 'Kuala Lumpur',
      'state': null,
      'country': 'MY',
      'lat': 3.1390,
      'lon': 101.6869,
    },
    {
      'name': 'Sydney',
      'state': 'New South Wales',
      'country': 'AU',
      'lat': -33.8688,
      'lon': 151.2093,
    },
    {
      'name': 'Melbourne',
      'state': 'Victoria',
      'country': 'AU',
      'lat': -37.8136,
      'lon': 144.9631,
    },
    {
      'name': 'Auckland',
      'state': null,
      'country': 'NZ',
      'lat': -36.8509,
      'lon': 174.7645,
    },
    // Middle East & Africa
    {
      'name': 'Dubai',
      'state': 'Dubai',
      'country': 'AE',
      'lat': 25.2048,
      'lon': 55.2708,
    },
    {
      'name': 'Abu Dhabi',
      'state': 'Abu Dhabi',
      'country': 'AE',
      'lat': 24.4539,
      'lon': 54.3773,
    },
    {
      'name': 'Doha',
      'state': null,
      'country': 'QA',
      'lat': 25.2854,
      'lon': 51.5310,
    },
    {
      'name': 'Riyadh',
      'state': null,
      'country': 'SA',
      'lat': 24.7136,
      'lon': 46.6753,
    },
    {
      'name': 'Istanbul',
      'state': null,
      'country': 'TR',
      'lat': 41.0082,
      'lon': 28.9784,
    },
    {
      'name': 'Tel Aviv',
      'state': null,
      'country': 'IL',
      'lat': 32.0853,
      'lon': 34.7818,
    },
    {
      'name': 'Cairo',
      'state': null,
      'country': 'EG',
      'lat': 30.0444,
      'lon': 31.2357,
    },
    {
      'name': 'Cape Town',
      'state': 'Western Cape',
      'country': 'ZA',
      'lat': -33.9249,
      'lon': 18.4241,
    },
    {
      'name': 'Johannesburg',
      'state': 'Gauteng',
      'country': 'ZA',
      'lat': -26.2041,
      'lon': 28.0473,
    },
    {
      'name': 'Nairobi',
      'state': null,
      'country': 'KE',
      'lat': -1.2921,
      'lon': 36.8219,
    },
    {
      'name': 'Lagos',
      'state': 'Lagos',
      'country': 'NG',
      'lat': 6.5244,
      'lon': 3.3792,
    },
    // Latin America
    {
      'name': 'Mexico City',
      'state': null,
      'country': 'MX',
      'lat': 19.4326,
      'lon': -99.1332,
    },
    {
      'name': 'Sao Paulo',
      'state': null,
      'country': 'BR',
      'lat': -23.5505,
      'lon': -46.6333,
    },
    {
      'name': 'Rio de Janeiro',
      'state': null,
      'country': 'BR',
      'lat': -22.9068,
      'lon': -43.1729,
    },
    {
      'name': 'Buenos Aires',
      'state': null,
      'country': 'AR',
      'lat': -34.6037,
      'lon': -58.3816,
    },
    {
      'name': 'Santiago',
      'state': null,
      'country': 'CL',
      'lat': -33.4489,
      'lon': -70.6693,
    },
    {
      'name': 'Bogota',
      'state': null,
      'country': 'CO',
      'lat': 4.7110,
      'lon': -74.0721,
    },
    {
      'name': 'Lima',
      'state': null,
      'country': 'PE',
      'lat': -12.0464,
      'lon': -77.0428,
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> searchCities({
    required String query,
  }) async {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) return const [];

    return _cities
        .where(
          (city) =>
              (city['name'] as String).toLowerCase().startsWith(normalized),
        )
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    Map<String, dynamic>? nearest;
    var nearestDistance = double.infinity;

    for (final city in _cities) {
      final dLat = (city['lat'] as num).toDouble() - latitude;
      final dLon = (city['lon'] as num).toDouble() - longitude;
      final distance = dLat * dLat + dLon * dLon;

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = city;
      }
    }

    // Only a genuinely close bundled city counts as a match (~0.5° is
    // about 55 km). Beyond that there is no honest answer, so return
    // nothing rather than pinning the device to whichever bundled city
    // happens to be least far away (e.g. an Indian city for a device in
    // California) — callers then fall back to a generic label.
    if (nearest == null || nearestDistance > _maxMatchDistanceSquared) {
      return const [];
    }

    return [nearest];
  }

  static const _maxMatchDistanceSquared = 0.5 * 0.5;
}
