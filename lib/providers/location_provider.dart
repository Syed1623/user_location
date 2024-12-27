import 'package:flutter/material.dart';

class LocationProvider extends ChangeNotifier {
  double? latitude;
  double? longitude;
  String? area;
  String? locality;
  String? subLocality;
  String? postalCode;
  String? country;
  String? administrativeArea;
  String? thoroughfare;
  bool isLoading = false;
  String? error;
  DateTime? lastUpdated;

  // Singleton pattern
  static final LocationProvider _instance = LocationProvider._internal();

  factory LocationProvider() {
    return _instance;
  }

  LocationProvider._internal();

  void updateLocation({
    double? lat,
    double? lng,
    String? area,
    String? locality,
    String? subLocality,
    String? postalCode,
    String? country,
    String? administrativeArea,
    String? thoroughfare,
  }) {
    latitude = lat;
    longitude = lng;
    this.area = area;
    this.locality = locality;
    this.subLocality = subLocality;
    this.postalCode = postalCode;
    this.country = country;
    this.administrativeArea = administrativeArea;
    this.thoroughfare = thoroughfare;
    lastUpdated = DateTime.now();
    notifyListeners();
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void setError(String? errorMessage) {
    error = errorMessage;
    print("Error $error");
    isLoading = false;
    notifyListeners();
  }

  void reset() {
    latitude = null;
    longitude = null;
    area = null;
    locality = null;
    subLocality = null;
    postalCode = null;
    country = null;
    administrativeArea = null;
    thoroughfare = null;
    error = null;
    isLoading = false;
    lastUpdated = null;
    notifyListeners();
  }
}
