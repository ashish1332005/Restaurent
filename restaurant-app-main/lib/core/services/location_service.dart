import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Acquire current device latitude & longitude using Geolocator
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        try {
          await Geolocator.openLocationSettings();
        } catch (_) {}
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        try {
          await Geolocator.openAppSettings();
        } catch (_) {}
        return null;
      }

      // Try high accuracy (outdoors / clear sky) with 6s timeout
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
      } catch (e) {
        debugPrint('High accuracy position timed out or failed ($e). Falling back to balanced network location...');
      }

      // Fallback: medium accuracy (works indoors via Wi-Fi and cell tower triangulation)
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 6),
          ),
        );
      } catch (e) {
        debugPrint('Medium accuracy position failed ($e). Checking last known location...');
      }

      // Final fallback: return cached last known location
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Haversine formula to compute exact distance in meters between two lat/long points
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double r = 6371000; // Earth radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degree) {
    return degree * (pi / 180.0);
  }

  /// Verifies if a customer's location is within the allowed order radius of the restaurant
  static Future<ProximityResult> checkCustomerProximity({
    required double restaurantLat,
    required double restaurantLong,
    required double allowedRadiusMeters,
  }) async {
    final position = await getCurrentLocation();
    if (position == null) {
      return ProximityResult(
        isWithinRadius: false,
        distanceMeters: -1,
        errorMessage:
            'Unable to acquire your GPS location. Please enable location permissions to place an order.',
      );
    }

    final distance = calculateDistanceMeters(
      restaurantLat,
      restaurantLong,
      position.latitude,
      position.longitude,
    );

    final isWithin = distance <= allowedRadiusMeters;

    return ProximityResult(
      isWithinRadius: isWithin,
      distanceMeters: distance,
      customerLat: position.latitude,
      customerLong: position.longitude,
      errorMessage: isWithin
          ? null
          : 'Location Error: You are ${distance.toStringAsFixed(0)}m away from the restaurant. QR ordering is allowed only within ${allowedRadiusMeters.toStringAsFixed(0)} meters.',
    );
  }
}

class ProximityResult {
  final bool isWithinRadius;
  final double distanceMeters;
  final double? customerLat;
  final double? customerLong;
  final String? errorMessage;

  ProximityResult({
    required this.isWithinRadius,
    required this.distanceMeters,
    this.customerLat,
    this.customerLong,
    this.errorMessage,
  });
}
