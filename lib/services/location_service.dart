import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:userlocation/providers/location_provider.dart';

class LocationService {
  final LocationProvider _locationProvider = LocationProvider();
  StreamSubscription<Position>? _positionSubscription;

  Future<bool> handlePermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationProvider.setError('Location services are disabled.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationProvider.setError('Location permissions are denied.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationProvider.setError(
            'Location permissions are permanently denied. Please enable them in settings.');
        return false;
      }

      return true;
    } catch (e) {
      _locationProvider.setError('Error checking location permission: $e');
      return false;
    }
  }

  Future<void> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Failed to get address: operation timed out');
        },
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _locationProvider.updateLocation(
          lat: position.latitude,
          lng: position.longitude,
          area: place.street,
          locality: place.locality,
          subLocality: place.subLocality,
          postalCode: place.postalCode,
          country: place.country,
          administrativeArea: place.administrativeArea,
          thoroughfare: place.thoroughfare,
        );
      }
    } on TimeoutException catch (e) {
      // For geocoding timeout, we'll just update coordinates without address
      _locationProvider.updateLocation(
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (e) {
      // For other errors, we'll still update coordinates
      _locationProvider.updateLocation(
        lat: position.latitude,
        lng: position.longitude,
      );
    }
  }

  Future<void> getCurrentLocation() async {
    _locationProvider.setLoading(true);
    _locationProvider.setError(null);

    try {
      final hasPermission = await handlePermission();
      if (!hasPermission) {
        _locationProvider.setLoading(false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
              'Failed to get current location: operation timed out');
        },
      );

      await getAddressFromLatLng(position);
    } on TimeoutException catch (e) {
      _locationProvider
          .setError('Location request timed out. Please try again.');
    } catch (e) {
      _locationProvider.setError('Error getting current location: $e');
    } finally {
      _locationProvider.setLoading(false);
    }
  }

  void startLocationStream() async {
    _positionSubscription?.cancel();

    final hasPermission = await handlePermission();
    if (!hasPermission) return;

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) async {
          // Clear any previous errors
          _locationProvider.setError(null);
          await getAddressFromLatLng(position);
        },
        onError: (error) {
          _locationProvider.setError('Location stream error: $error');
        },
        cancelOnError: false,
      );
    } catch (e) {
      _locationProvider.setError('Error starting location stream: $e');
    }
  }

  void stopLocationStream() {
    _positionSubscription?.cancel();
    _locationProvider.reset();
  }

  void dispose() {
    stopLocationStream();
  }
}
