import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UvForecastSummary {
  final String sourceLabel;
  final double currentUvIndex;
  final String observedAtLabel;
  final bool isFallback;

  const UvForecastSummary({
    required this.sourceLabel,
    required this.currentUvIndex,
    required this.observedAtLabel,
    required this.isFallback,
  });
}

class UvForecastService {
  static const double _fallbackLatitude = 6.9271;
  static const double _fallbackLongitude = 79.8612;

  final http.Client _client;
  Future<UvForecastSummary>? _cachedForecast;

  UvForecastService({http.Client? client}) : _client = client ?? http.Client();

  Future<UvForecastSummary> loadCurrentUv({bool forceRefresh = false}) {
    if (forceRefresh || _cachedForecast == null) {
      _cachedForecast = _loadForecast();
    }
    return _cachedForecast!;
  }

  Future<UvForecastSummary> _loadForecast() async {
    try {
      final resolvedLocation = await _resolveLocation().timeout(
        const Duration(seconds: 6),
        onTimeout: () => const _ResolvedUvLocation(
          latitude: _fallbackLatitude,
          longitude: _fallbackLongitude,
          label: 'Regional UV fallback',
          isFallback: true,
        ),
      );
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${resolvedLocation.latitude}',
        'longitude': '${resolvedLocation.longitude}',
        'hourly': 'uv_index',
        'timezone': 'auto',
        'forecast_days': '1',
      });

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('Unable to load live UV forecast right now.');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final hourly =
          json['hourly'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final times = (hourly['time'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>();
      final uvValues = (hourly['uv_index'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => (value as num).toDouble())
          .toList();

      if (times.isEmpty || uvValues.isEmpty) {
        throw Exception('No UV data is available right now.');
      }

      final now = DateTime.now();
      var closestIndex = 0;
      var smallestDifference = const Duration(days: 365);
      for (var i = 0; i < times.length && i < uvValues.length; i++) {
        final parsedTime = DateTime.tryParse(times[i]);
        if (parsedTime == null) {
          continue;
        }
        final difference = parsedTime.difference(now).abs();
        if (difference < smallestDifference) {
          smallestDifference = difference;
          closestIndex = i;
        }
      }

      final observedAt = DateTime.tryParse(times[closestIndex]) ?? now;

      return UvForecastSummary(
        sourceLabel: resolvedLocation.label,
        currentUvIndex: uvValues[closestIndex],
        observedAtLabel: _formatHourLabel(observedAt),
        isFallback: resolvedLocation.isFallback,
      );
    } catch (_) {
      return _buildEstimatedFallback();
    }
  }

  Future<_ResolvedUvLocation> _resolveLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const _ResolvedUvLocation(
        latitude: _fallbackLatitude,
        longitude: _fallbackLongitude,
        label: 'Default UV forecast',
        isFallback: true,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const _ResolvedUvLocation(
        latitude: _fallbackLatitude,
        longitude: _fallbackLongitude,
        label: 'Default UV forecast',
        isFallback: true,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
      ),
    ).timeout(const Duration(seconds: 6));

    return _ResolvedUvLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      label: 'UV forecast for your location',
      isFallback: false,
    );
  }

  String _formatHourLabel(DateTime value) {
    final hour = value.hour;
    final normalizedHour = hour == 0 || hour == 12 ? 12 : hour % 12;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    return '$normalizedHour $suffix';
  }

  UvForecastSummary _buildEstimatedFallback() {
    final now = DateTime.now();
    final hour = now.hour;
    final estimatedUv = switch (hour) {
      < 6 => 0.0,
      < 8 => 2.0,
      < 10 => 4.0,
      < 12 => 7.0,
      < 14 => 9.0,
      < 16 => 6.0,
      < 18 => 3.0,
      _ => 1.0,
    };

    return UvForecastSummary(
      sourceLabel: 'Estimated UV for your region',
      currentUvIndex: estimatedUv,
      observedAtLabel: _formatHourLabel(now),
      isFallback: true,
    );
  }
}

class _ResolvedUvLocation {
  final double latitude;
  final double longitude;
  final String label;
  final bool isFallback;

  const _ResolvedUvLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.isFallback,
  });
}
