import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/maps/kz_map.dart';
import 'package:kz_servicos_app/features/trip/data/services/directions_service.dart';

class MapRoutePreview extends StatefulWidget {
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final double height;

  const MapRoutePreview({
    super.key,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    this.height = 130,
  });

  @override
  State<MapRoutePreview> createState() => _MapRoutePreviewState();
}

class _MapRoutePreviewState extends State<MapRoutePreview> {
  final Completer<KzMapController> _controllerCompleter = Completer();
  final DirectionsService _directionsService = DirectionsService();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _routeLoaded = false;

  LatLng get _origin => LatLng(widget.originLat, widget.originLng);
  LatLng get _destination =>
      LatLng(widget.destinationLat, widget.destinationLng);

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final points = await _directionsService.fetchRoute(
      origin: _origin,
      destination: _destination,
    );

    if (!mounted) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('origin'),
          position: _origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      };

      if (points.isNotEmpty) {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: AppColors.secondary,
            width: 3,
          ),
        };
      }

      _routeLoaded = true;
    });

    _fitBounds();
  }

  Future<void> _fitBounds() async {
    final controller = await _controllerCompleter.future;
    final bounds = LatLngBounds(
      southwest: LatLng(
        _origin.latitude < _destination.latitude
            ? _origin.latitude
            : _destination.latitude,
        _origin.longitude < _destination.longitude
            ? _origin.longitude
            : _destination.longitude,
      ),
      northeast: LatLng(
        _origin.latitude > _destination.latitude
            ? _origin.latitude
            : _destination.latitude,
        _origin.longitude > _destination.longitude
            ? _origin.longitude
            : _destination.longitude,
      ),
    );

    await controller.fitBounds(bounds, padding: 40);
  }

  @override
  Widget build(BuildContext context) {
    final midLat = (_origin.latitude + _destination.latitude) / 2;
    final midLng = (_origin.longitude + _destination.longitude) / 2;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            AbsorbPointer(
              child: KzMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(midLat, midLng),
                  zoom: 11,
                ),
                onMapCreated: (controller) {
                  if (!_controllerCompleter.isCompleted) {
                    _controllerCompleter.complete(controller);
                  }
                  if (_routeLoaded) _fitBounds();
                },
                markers: _markers,
                polylines: _polylines,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                liteModeEnabled: true,
              ),
            ),
            if (!_routeLoaded)
              Container(
                color: const Color(0xFFF5F5F5),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
