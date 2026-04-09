import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_address_search_bar.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_bottom_nav.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_top_bar.dart';

class TripHomePage extends StatefulWidget {
  const TripHomePage({super.key});

  @override
  State<TripHomePage> createState() => _TripHomePageState();
}

class _TripHomePageState extends State<TripHomePage> {
  final Completer<GoogleMapController> _mapController = Completer();

  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 15,
  );

  LatLng? _currentLocation;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    _requestLocationAndInit();
  }

  Future<void> _requestLocationAndInit() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() => _currentLocation = latLng);

      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16),
        ),
      );
    } catch (_) {
      // Location unavailable — keep default camera position
    }
  }

  void _onAddressSelected(PlacePrediction prediction) {
    // No-op for now — address input only
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopOverlay(),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: _defaultCamera,
      onMapCreated: _mapController.complete,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildTopOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const TripTopBar(),
            const SizedBox(height: 16),
            TripAddressSearchBar(
              location: _currentLocation,
              onAddressSelected: _onAddressSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: TripBottomNav(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
        ),
      ),
    );
  }
}
