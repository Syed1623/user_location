import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:userlocation/providers/location_provider.dart';

class LocationService {
  final LocationProvider _locationProvider = LocationProvider();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _retryTimer;
  static const int _retryInterval = 5;

  Future<bool> handlePermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationProvider.setError('Location services are disabled.');
        _scheduleRetry();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationProvider.setError('Location permissions are denied.');
          _scheduleRetry();
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

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: _retryInterval), () {
      startLocationStream();
    });
  }

  Future<void> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
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
    } catch (e) {
      _locationProvider.setError('Error getting address details: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    _locationProvider.setLoading(true);
    _locationProvider.setError(null);

    try {
      final hasPermission = await handlePermission();
      if (!hasPermission) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      await getAddressFromLatLng(position);
    } catch (e) {
      _locationProvider.setError('Error getting current location: $e');
    } finally {
      _locationProvider.setLoading(false);
    }
  }

  void startLocationStream() async {
    _positionSubscription?.cancel();
    _retryTimer?.cancel();

    final hasPermission = await handlePermission();
    if (!hasPermission) return;

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 15),
        ),
      ).listen(
        (Position position) async {
          await getAddressFromLatLng(position);
        },
        onError: (error) {
          _locationProvider.setError('Location stream error: $error');
          _scheduleRetry();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _locationProvider.setError('Error starting location stream: $e');
      _scheduleRetry();
    }
  }

  void stopLocationStream() {
    _positionSubscription?.cancel();
    _retryTimer?.cancel();
    _locationProvider.reset();
  }

  void dispose() {
    stopLocationStream();
  }
}
