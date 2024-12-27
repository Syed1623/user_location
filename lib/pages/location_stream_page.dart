import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:userlocation/providers/location_provider.dart';
import 'package:userlocation/services/location_service.dart';

class LocationStreamPage extends StatefulWidget {
  const LocationStreamPage({super.key});

  @override
  State<LocationStreamPage> createState() => _LocationStreamPageState();
}

class _LocationStreamPageState extends State<LocationStreamPage>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationService.startLocationStream();
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
  }

  @override
  void dispose() {
    _locationService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not available';
    return DateFormat('MM/dd/yyyy HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _locationService.getCurrentLocation();
              _animationController.reset();
              _animationController.forward();
            },
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          if (locationProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Getting location...'),
                ],
              ),
            );
          }

          if (locationProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      locationProvider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _locationService.startLocationStream(),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  title: 'Coordinates',
                  children: [
                    _buildInfoRow('Latitude', '${locationProvider.latitude}'),
                    _buildInfoRow('Longitude', '${locationProvider.longitude}'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Address Details',
                  children: [
                    _buildInfoRow('Street', locationProvider.area),
                    _buildInfoRow('Locality', locationProvider.locality),
                    _buildInfoRow('Sub-locality', locationProvider.subLocality),
                    _buildInfoRow('Administrative Area',
                        locationProvider.administrativeArea),
                    _buildInfoRow('Postal Code', locationProvider.postalCode),
                    _buildInfoRow('Country', locationProvider.country),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Update Information',
                  children: [
                    _buildInfoRow(
                      'Last Updated',
                      _formatDateTime(locationProvider.lastUpdated),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return SlideTransition(
      position: _animation,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not available',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
