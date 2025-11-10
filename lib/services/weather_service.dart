// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple DTO for "current weather" we show on the home screen
class WeatherNow {
  final double tempC; // e.g. 12.4
  final String main; // e.g. Clear, Clouds, Rain, Snow, Drizzle, Thunderstorm
  final String desc; // e.g. light rain
  final String icon; // OpenWeather icon id, e.g. "10d"
  final double windKph; // wind speed in km/h

  const WeatherNow({
    required this.tempC,
    required this.main,
    required this.desc,
    required this.icon,
    required this.windKph,
  });
}

class _WeatherCache {
  WeatherNow? data;
  DateTime? at;
  String? key;
}

class WeatherService {
  /// Prefer passing the key via:
  /// flutter run --dart-define=OWM_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxx
  static const _envKey = String.fromEnvironment('OWM_API_KEY');
  static final _cache = _WeatherCache();

  static Future<WeatherNow?> fetchCurrent({
    required String city,
    String country = 'GB',
    String? apiKey,
    Duration cacheFor = const Duration(minutes: 20),
  }) async {
    final key = (apiKey ?? _envKey).trim();
    if (key.isEmpty) return null;

    final cacheKey = '$city,$country';
    final now = DateTime.now();
    if (_cache.data != null &&
        _cache.key == cacheKey &&
        _cache.at != null &&
        now.difference(_cache.at!) < cacheFor) {
      return _cache.data;
    }

    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?q=$city,$country&appid=$key&units=metric',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final j = jsonDecode(res.body);

    final weatherList = (j['weather'] as List?) ?? const [];
    final w0 = weatherList.isNotEmpty ? weatherList.first as Map? : null;
    final main = (j['main'] as Map?) ?? const {};
    final wind = (j['wind'] as Map?) ?? const {};

    final temp = (main['temp'] as num?)?.toDouble();
    if (temp == null) return null;

    final icon = (w0?['icon'] as String?) ?? '01d';
    final mainTxt = (w0?['main'] as String?) ?? 'Clear';
    final descTxt = (w0?['description'] as String?) ?? '';
    final windMs = (wind['speed'] as num?)?.toDouble() ?? 0.0;
    final windKph = windMs * 3.6;

    final data = WeatherNow(
      tempC: temp,
      main: mainTxt,
      desc: descTxt,
      icon: icon,
      windKph: windKph,
    );

    _cache
      ..data = data
      ..at = now
      ..key = cacheKey;

    return data;
  }
}
