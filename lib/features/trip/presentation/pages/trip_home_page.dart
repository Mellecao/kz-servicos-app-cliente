import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/constants/map_styles.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/data/services/directions_service.dart';
import 'package:kz_servicos_app/features/trip/data/services/geocoding_service.dart';
import 'package:kz_servicos_app/features/trip/data/services/place_details_service.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/address_search_sheet.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/passenger_details_panel.dart';
import 'package:kz_servicos_app/features/trip/data/models/mock_driver.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_confirming_panel.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_en_route_panel.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_selection_panel.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/searching_driver_panel.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_bottom_nav.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_rating_panel.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_summary_panel.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_top_bar.dart';

enum TripFlowStep {
  idle,
  pickOnMap,
  confirmPickup,
  passengerDetails,
  searchingDriver,
  driverSelection,
  driverConfirming,
  driverEnRoute,
  tripStarted,
  tripSummary,
  tripRating,
}

class TripHomePage extends StatefulWidget {
  const TripHomePage({super.key});

  @override
  State<TripHomePage> createState() => _TripHomePageState();
}

class _TripHomePageState extends State<TripHomePage>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  final DirectionsService _directionsService = DirectionsService();
  final GeocodingService _geocodingService = GeocodingService();
  final PlaceDetailsService _placeDetailsService = PlaceDetailsService();

  GoogleMapController? _controller;
  Marker? _userMarker;
  bool _isSearchActive = false;

  AnimationController? _pulseController;
  List<LatLng> _routePoints = [];

  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 15,
  );

  LatLng? _currentLocation;
  int _selectedNavIndex = 0;
  TripFlowStep _step = TripFlowStep.idle;

  LatLng? _destinationLatLng;
  LatLng? _pickupLatLng;

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  String? _currentAddress;
  String? _confirmPickupAddress;
  bool _panelMinimized = false;
  List<LatLng> _stops = [];

  // Driver flow state
  MockDriver? _selectedDriver;
  Timer? _searchingTimer;
  Timer? _confirmingTimer;
  Timer? _driverMoveTimer;
  List<LatLng> _driverToPickupRoute = [];
  int _driverRouteIndex = 0;
  bool _enRoutePanelExpanded = false;
  int _driverEtaMinutes = 0;
  Timer? _tripSummaryTimer;
  String? _pickupAddress;
  String? _destinationAddress;
  BitmapDescriptor? _cachedBlueDotIcon;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    _requestLocationAndInit();
  }

  void _openSearch() {
    _resolveCurrentAddress();
    setState(() => _isSearchActive = true);
  }

  Future<void> _resolveCurrentAddress() async {
    if (_currentLocation == null || _currentAddress != null) return;
    final address = await _geocodingService.reverseGeocode(
      _currentLocation!,
    );
    if (mounted && address != null) {
      setState(() => _currentAddress = address);
    }
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
      final blueIcon = await _createBlueDotIcon();
      setState(() {
        _currentLocation = latLng;
        _userMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: latLng,
          icon: blueIcon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 99,
        );
      });
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16),
        ),
      );
    } catch (_) {}
  }

  // ──── Address selection ────

  Future<void> _onDestinationSelected(PlacePrediction prediction) async {
    final latLng = await _placeDetailsService.getPlaceLatLng(
      prediction.placeId,
    );
    if (!mounted) return;
    final destIcon = await _createYellowCircleIcon();
    setState(() {
      _destinationLatLng = latLng;
      if (latLng != null) {
        _markers = {
          Marker(
            markerId: const MarkerId('destination'),
            position: latLng,
            icon: destIcon,
            anchor: const Offset(0.5, 0.5),
          ),
        };
      }
    });
    if (latLng != null) {
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 15),
        ),
      );
    }
  }

  Future<void> _onPickupSelected(PlacePrediction prediction) async {
    LatLng? latLng;
    if (prediction.placeId == '_current_location_' &&
        _currentLocation != null) {
      latLng = _currentLocation;
    } else {
      latLng = await _placeDetailsService.getPlaceLatLng(
        prediction.placeId,
      );
    }
    if (!mounted || latLng == null) return;
    setState(() {
      _pickupLatLng = latLng;
    });
  }

  void _onConfirmAddresses() {
    // If pickup not explicitly set, use current location
    if (_pickupLatLng == null && _currentLocation != null) {
      _pickupLatLng = _currentLocation;
    }
    if (_pickupLatLng == null || _destinationLatLng == null) return;
    setState(() => _isSearchActive = false);
    _enterConfirmPickup();
  }

  void _enterPickOnMapMode() {
    setState(() {
      _isSearchActive = false;
      _step = TripFlowStep.pickOnMap;
      _markers = {};
    });
  }

  Future<void> _onStopSelected(PlacePrediction prediction) async {
    final latLng = await _placeDetailsService.getPlaceLatLng(
      prediction.placeId,
    );
    if (!mounted || latLng == null) return;
    setState(() {
      _stops.add(latLng);
    });
  }

  Future<void> _confirmPinLocation() async {
    if (_controller == null) return;
    final size = MediaQuery.of(context).size;
    final center = await _controller!.getLatLng(
      ScreenCoordinate(
        x: (size.width / 2).round(),
        y: (size.height / 2).round(),
      ),
    );
    await _geocodingService.reverseGeocode(center);
    if (!mounted) return;
    setState(() => _pickupLatLng = center);
    await _showRouteAndProceed();
  }

  Future<void> _enterConfirmPickup() async {
    if (_pickupLatLng == null) return;
    setState(() {
      _step = TripFlowStep.confirmPickup;
      _markers = {};
      _polylines = {};
      _confirmPickupAddress = null;
    });
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _pickupLatLng!, zoom: 19),
      ),
    );
    _resolveConfirmPickupAddress(_pickupLatLng!);
  }

  Future<void> _resolveConfirmPickupAddress(LatLng position) async {
    final address = await _geocodingService.reverseGeocode(position);
    if (mounted && _step == TripFlowStep.confirmPickup) {
      setState(() => _confirmPickupAddress = address);
    }
  }

  Future<void> _confirmPickupLocation() async {
    if (_controller == null) return;
    final size = MediaQuery.of(context).size;
    final center = await _controller!.getLatLng(
      ScreenCoordinate(
        x: (size.width / 2).round(),
        y: (size.height / 2).round(),
      ),
    );
    if (!mounted) return;
    setState(() => _pickupLatLng = center);
    await _showRouteAndProceed();
  }

  Future<void> _showRouteAndProceed() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;
    final routePoints = await _directionsService.fetchRoute(
      origin: _pickupLatLng!,
      destination: _destinationLatLng!,
      waypoints: _stops,
    );
    if (!mounted) return;
    final pickupIcon = await _createYellowPinIcon();
    final destIcon = await _createYellowCircleIcon();
    final stopMarkers = <Marker>{};
    if (_stops.isNotEmpty) {
      final stopIcon = await _createBlackCircleIcon();
      for (int i = 0; i < _stops.length; i++) {
        stopMarkers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: _stops[i],
            icon: stopIcon,
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    }
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: pickupIcon,
          anchor: const Offset(0.5, 1.0),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLatLng!,
          icon: destIcon,
          anchor: const Offset(0.5, 0.5),
        ),
        ...stopMarkers,
      };
      _routePoints = routePoints;
      if (routePoints.isNotEmpty) {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route_glow'),
            points: routePoints,
            color: AppColors.highlight.withValues(alpha: 0.18),
            width: 10,
          ),
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: AppColors.highlight,
            width: 4,
          ),
        };
        _startPulseAnimation(routePoints);
      }
      _step = TripFlowStep.passengerDetails;
      _panelMinimized = false;
    });
    _fitBounds();
  }

  void _dismissSearch() {
    setState(() => _isSearchActive = false);
  }

  // ──── Map utilities ────

  Future<BitmapDescriptor> _createBlueDotIcon() async {
    const size = 28.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = const Color(0x334285F4),
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      8,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      6,
      Paint()..color = const Color(0xFF4285F4),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createYellowPinIcon() async {
    const width = 32.0;
    const height = 44.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = AppColors.highlight;
    // Pin head
    canvas.drawCircle(const Offset(width / 2, 14), 12, paint);
    // Pin point
    final path = Path()
      ..moveTo(width / 2 - 8, 20)
      ..lineTo(width / 2, height - 2)
      ..lineTo(width / 2 + 8, 20)
      ..close();
    canvas.drawPath(path, paint);
    // White inner circle
    canvas.drawCircle(
      const Offset(width / 2, 14),
      5,
      Paint()..color = Colors.white,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createYellowCircleIcon() async {
    const size = 28.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Outer glow
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = AppColors.highlight.withValues(alpha: 0.3),
    );
    // White border
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      9,
      Paint()..color = Colors.white,
    );
    // Yellow center
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      7,
      Paint()..color = AppColors.highlight,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createBlackCircleIcon() async {
    const size = 24.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      8,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      6,
      Paint()..color = Colors.black87,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  void _startPulseAnimation(List<LatLng> points) {
    _stopPulseAnimation();
    if (points.length < 2) return;
    _routeDistances = _computeSegmentDistances(points);
    _routeTotalLength = _routeDistances.isEmpty
        ? 0
        : _routeDistances.last;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _pulseController!.addListener(_updatePulsePolyline);
    _pulseController!.repeat();
  }

  void _stopPulseAnimation() {
    _pulseController?.removeListener(_updatePulsePolyline);
    _pulseController?.dispose();
    _pulseController = null;
  }

  /// Pre-computes cumulative distances along the route.
  List<double> _computeSegmentDistances(List<LatLng> pts) {
    final dists = <double>[0.0];
    for (int i = 1; i < pts.length; i++) {
      final d = _haversine(pts[i - 1], pts[i]);
      dists.add(dists.last + d);
    }
    return dists;
  }

  double _haversine(LatLng a, LatLng b) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final hav = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(a.latitude)) *
            math.cos(_toRad(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(hav), math.sqrt(1 - hav));
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  /// Interpolates a LatLng at a given cumulative distance along the route.
  LatLng _interpolateAtDistance(double dist) {
    if (dist <= 0) return _routePoints.first;
    if (dist >= _routeTotalLength) return _routePoints.last;
    // Binary search for the segment
    int lo = 0, hi = _routeDistances.length - 1;
    while (lo < hi - 1) {
      final mid = (lo + hi) ~/ 2;
      if (_routeDistances[mid] <= dist) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final segStart = _routeDistances[lo];
    final segEnd = _routeDistances[hi];
    final t = (dist - segStart) / (segEnd - segStart);
    final a = _routePoints[lo];
    final b = _routePoints[hi];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  /// Extracts a sub-polyline from cumulative distance [from] to [to].
  List<LatLng> _extractSubRoute(double from, double to) {
    final result = <LatLng>[];
    result.add(_interpolateAtDistance(from));
    for (int i = 0; i < _routeDistances.length; i++) {
      final d = _routeDistances[i];
      if (d > from && d < to) {
        result.add(_routePoints[i]);
      }
    }
    result.add(_interpolateAtDistance(to));
    return result;
  }

  List<double> _routeDistances = [];
  double _routeTotalLength = 0;

  void _updatePulsePolyline() {
    if (_routePoints.length < 2 || !mounted) return;
    final t = _pulseController!.value;
    // Glow segment = 20% of route length, travels start→end
    final segmentRatio = 0.20;
    final headDist = t * (_routeTotalLength * (1 + segmentRatio));
    final tailDist = headDist - _routeTotalLength * segmentRatio;
    final clampedHead = headDist.clamp(0.0, _routeTotalLength);
    final clampedTail = tailDist.clamp(0.0, _routeTotalLength);
    if (clampedHead - clampedTail < 1) {
      // Segment too small, just show base route
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route_glow'),
            points: _routePoints,
            color: AppColors.highlight.withValues(alpha: 0.18),
            width: 10,
          ),
          Polyline(
            polylineId: const PolylineId('route'),
            points: _routePoints,
            color: AppColors.highlight,
            width: 4,
          ),
        };
      });
      return;
    }
    final glowPoints = _extractSubRoute(clampedTail, clampedHead);
    // Fade factor: fade in at start, fade out at end of animation cycle
    final fadeFactor = _computeFade(t, segmentRatio);
    setState(() {
      _polylines = {
        // Base glow (always visible, subtle)
        Polyline(
          polylineId: const PolylineId('route_glow'),
          points: _routePoints,
          color: AppColors.highlight.withValues(alpha: 0.18),
          width: 10,
        ),
        // Core solid line
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: AppColors.highlight,
          width: 4,
        ),
        // Traveling highlight — bright glow segment
        if (glowPoints.length >= 2)
          Polyline(
            polylineId: const PolylineId('pulse_glow'),
            points: glowPoints,
            color:
                Colors.white.withValues(alpha: 0.45 * fadeFactor),
            width: 12,
          ),
        // Traveling highlight — bright core segment
        if (glowPoints.length >= 2)
          Polyline(
            polylineId: const PolylineId('pulse_core'),
            points: glowPoints,
            color:
                Colors.white.withValues(alpha: 0.85 * fadeFactor),
            width: 5,
          ),
      };
    });
  }

  /// Smooth fade-in/fade-out at the start and end of the pulse cycle.
  double _computeFade(double t, double segmentRatio) {
    const fadeZone = 0.08;
    if (t < fadeZone) return t / fadeZone;
    if (t > 1 - fadeZone) return (1 - t) / fadeZone;
    return 1.0;
  }

  @override
  void dispose() {
    _stopPulseAnimation();
    _searchingTimer?.cancel();
    _confirmingTimer?.cancel();
    _driverMoveTimer?.cancel();
    _tripSummaryTimer?.cancel();
    super.dispose();
  }

  Future<void> _fitBounds() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;
    final controller = await _mapController.future;
    final screenHeight = MediaQuery.of(context).size.height;

    final allPoints = <LatLng>[_pickupLatLng!, _destinationLatLng!, ..._stops];
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;
    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    // Bottom padding accounts for the panel (~55% screen)
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
    // Shift the map down so route is visible above the sheet
    await controller.animateCamera(
      CameraUpdate.scrollBy(0, screenHeight * 0.18),
    );
  }

  void _onPassengerDetailsConfirmed() {
    setState(() => _step = TripFlowStep.searchingDriver);
    _searchingTimer = Timer(
      const Duration(seconds: 10),
      _onSearchingComplete,
    );
  }

  void _onDetailsBack() {
    _stopPulseAnimation();
    _searchingTimer?.cancel();
    _confirmingTimer?.cancel();
    _driverMoveTimer?.cancel();
    _tripSummaryTimer?.cancel();
    setState(() {
      _step = TripFlowStep.idle;
      _polylines = {};
      _markers = {};
      _routePoints = [];
      _panelMinimized = false;
      _destinationLatLng = null;
      _pickupLatLng = null;
      _stops = [];
      _selectedDriver = null;
      _driverToPickupRoute = [];
      _driverRouteIndex = 0;
      _enRoutePanelExpanded = false;
      _driverEtaMinutes = 0;
      _pickupAddress = null;
      _destinationAddress = null;
      _isSearchActive = true;
    });
  }

  void _onSearchingComplete() {
    _searchingTimer?.cancel();
    if (!mounted) return;
    setState(() => _step = TripFlowStep.driverSelection);
  }

  void _onDriverAccepted(MockDriver driver) {
    setState(() {
      _selectedDriver = driver;
      _step = TripFlowStep.driverConfirming;
    });
    _confirmingTimer = Timer(
      const Duration(seconds: 10),
      _onDriverConfirmed,
    );
  }

  void _onDriverConfirmed() {
    _confirmingTimer?.cancel();
    if (!mounted) return;
    setState(() => _step = TripFlowStep.driverEnRoute);
    _startFakeDriverMovement();
  }

  Future<void> _startFakeDriverMovement() async {
    if (_pickupLatLng == null) return;
    _stopPulseAnimation();
    _cachedBlueDotIcon ??= await _createBlueDotIcon();

    final startLat = _pickupLatLng!.latitude + 0.018;
    final startLng = _pickupLatLng!.longitude + 0.005;
    final driverStart = LatLng(startLat, startLng);

    final route = await _directionsService.fetchRoute(
      origin: driverStart,
      destination: _pickupLatLng!,
    );
    if (!mounted || route.isEmpty) return;

    // Estimate ETA: ~300ms per 3 points step, total steps = route.length / 3
    final totalSteps = (route.length / 3).ceil();
    final totalSeconds = (totalSteps * 0.3).ceil();
    final etaMin = (totalSeconds / 60).ceil().clamp(1, 60);

    setState(() {
      _driverToPickupRoute = route;
      _driverRouteIndex = 0;
      _driverEtaMinutes = etaMin;
      _markers = {
        ..._markers.where((m) => m.markerId.value != 'fake_driver'),
        Marker(
          markerId: const MarkerId('fake_driver'),
          position: route.first,
          icon: _cachedBlueDotIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      };
      _polylines = {
        ..._polylines.where(
          (p) =>
              p.polylineId.value != 'pulse_glow' &&
              p.polylineId.value != 'pulse_core' &&
              p.polylineId.value != 'driver_route',
        ),
        Polyline(
          polylineId: const PolylineId('driver_route'),
          points: route,
          color: const Color(0xFF4285F4),
          width: 4,
        ),
      };
    });

    await _fitDriverBounds(route.first);
    _driverMoveTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => _moveFakeDriver(),
    );
  }

  void _moveFakeDriver() {
    if (_driverToPickupRoute.isEmpty || !mounted) return;
    _driverRouteIndex += 3;

    if (_driverRouteIndex >= _driverToPickupRoute.length - 1) {
      _driverMoveTimer?.cancel();
      _onDriverArrived();
      return;
    }

    final pos = _driverToPickupRoute[_driverRouteIndex];
    final remaining = _driverToPickupRoute.sublist(_driverRouteIndex);

    // Update ETA based on remaining points
    final remainingSteps = (remaining.length / 3).ceil();
    final remainingSec = (remainingSteps * 0.3).ceil();
    final etaMin = (remainingSec / 60).ceil().clamp(1, 60);

    setState(() {
      _driverEtaMinutes = etaMin;
      _markers = {
        ..._markers.where((m) => m.markerId.value != 'fake_driver'),
        Marker(
          markerId: const MarkerId('fake_driver'),
          position: pos,
          icon: _cachedBlueDotIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      };
      _polylines = {
        ..._polylines.where(
          (p) => p.polylineId.value != 'driver_route',
        ),
        Polyline(
          polylineId: const PolylineId('driver_route'),
          points: remaining,
          color: const Color(0xFF4285F4),
          width: 4,
        ),
      };
    });
  }

  void _onDriverArrived() {
    setState(() {
      _step = TripFlowStep.tripStarted;
      _driverEtaMinutes = 0;
      _markers = {
        ..._markers.where((m) => m.markerId.value != 'fake_driver'),
      };
      _polylines = {
        ..._polylines.where(
          (p) => p.polylineId.value != 'driver_route',
        ),
      };
    });
    if (_routePoints.isNotEmpty) {
      _startPulseAnimation(_routePoints);
    }
    _fitBounds();

    // After 10s of "trip started", simulate arrival and show summary
    _tripSummaryTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _resolveAddressesForSummary();
      setState(() => _step = TripFlowStep.tripSummary);
      // After 10s of summary, show rating
      _tripSummaryTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted) return;
        setState(() => _step = TripFlowStep.tripRating);
      });
    });
  }

  Future<void> _resolveAddressesForSummary() async {
    if (_pickupLatLng != null && _pickupAddress == null) {
      final addr = await _geocodingService.reverseGeocode(_pickupLatLng!);
      if (mounted && addr != null) {
        setState(() => _pickupAddress = addr);
      }
    }
    if (_destinationLatLng != null && _destinationAddress == null) {
      final addr =
          await _geocodingService.reverseGeocode(_destinationLatLng!);
      if (mounted && addr != null) {
        setState(() => _destinationAddress = addr);
      }
    }
  }

  void _onRatingSubmitted(int rating, String comment) {
    debugPrint('[KZ] Rating: $rating stars, comment: $comment');
    _resetToIdle();
  }

  void _onRatingClosed() {
    _resetToIdle();
  }

  void _resetToIdle() {
    _stopPulseAnimation();
    _tripSummaryTimer?.cancel();
    setState(() {
      _step = TripFlowStep.idle;
      _polylines = {};
      _markers = {};
      _routePoints = [];
      _panelMinimized = false;
      _destinationLatLng = null;
      _pickupLatLng = null;
      _stops = [];
      _selectedDriver = null;
      _driverToPickupRoute = [];
      _driverRouteIndex = 0;
      _enRoutePanelExpanded = false;
      _driverEtaMinutes = 0;
      _pickupAddress = null;
      _destinationAddress = null;
    });
  }

  Future<void> _fitDriverBounds(LatLng driverPos) async {
    if (_pickupLatLng == null) return;
    final controller = await _mapController.future;
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(driverPos.latitude, _pickupLatLng!.latitude),
        math.min(driverPos.longitude, _pickupLatLng!.longitude),
      ),
      northeast: LatLng(
        math.max(driverPos.latitude, _pickupLatLng!.latitude),
        math.max(driverPos.longitude, _pickupLatLng!.longitude),
      ),
    );
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 120),
    );
  }

  // ──── Build ────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildMap(),
          if (_step == TripFlowStep.idle && !_isSearchActive)
            _buildNotificationButton(),
          _buildFakeSearchBar(),
          _buildBottomNav(),
          _buildMapTapOverlay(),
          if (!_isSearchActive) _buildBottomPanel(),
          if (_step == TripFlowStep.passengerDetails ||
              _step == TripFlowStep.searchingDriver ||
              _step == TripFlowStep.driverSelection)
            _buildDetailsBackButton(),
          if (_step == TripFlowStep.confirmPickup) _buildConfirmPickupOverlay(),
          if (_step == TripFlowStep.pickOnMap) _buildCenterPin(),
          _buildSearchOverlay(),
        ],
      ),
    );
  }

  Widget _buildDetailsBackButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 22, left: 20),
        child: Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onTap: _onDetailsBack,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.black54,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPin() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 48),
        child: Icon(
          Icons.location_on,
          size: 48,
          color: AppColors.highlight,
        ),
      ),
    );
  }

  Widget _buildConfirmPickupOverlay() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        // Center pin
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 48),
            child: Icon(
              Icons.location_on,
              size: 48,
              color: AppColors.highlight,
            ),
          ),
        ),
        // Back button top-left
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 22, left: 20),
            child: Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: _onDetailsBack,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.black54,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Top label
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Confirme o local de partida',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
        // Address + Confirm button
        Positioned(
          bottom: screenHeight * 0.10,
          left: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_confirmPickupAddress != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.highlight,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _confirmPickupAddress!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirmPickupLocation,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Confirmar local',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.highlight,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapTapOverlay() {
    final shouldMinimizePanel =
        _step == TripFlowStep.passengerDetails && !_panelMinimized;
    final shouldCollapseEnRoute =
        (_step == TripFlowStep.driverEnRoute ||
            _step == TripFlowStep.tripStarted) &&
        _enRoutePanelExpanded;

    if (!shouldMinimizePanel && !shouldCollapseEnRoute) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (shouldMinimizePanel) {
            setState(() => _panelMinimized = true);
          }
          if (shouldCollapseEnRoute) {
            setState(() => _enRoutePanelExpanded = false);
          }
        },
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: _defaultCamera,
      onMapCreated: (ctrl) async {
        _mapController.complete(ctrl);
        _controller = ctrl;
        final style = await MapStyles.loadLight();
        ctrl.setMapStyle(style);
      },
      onCameraIdle: () async {
        if (_step != TripFlowStep.confirmPickup || _controller == null) return;
        final size = MediaQuery.of(context).size;
        final center = await _controller!.getLatLng(
          ScreenCoordinate(
            x: (size.width / 2).round(),
            y: (size.height / 2).round(),
          ),
        );
        _resolveConfirmPickupAddress(center);
      },
      onTap: (_) {},
      myLocationEnabled: !kIsWeb,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      polylines: _polylines,
      markers: {
        ..._markers,
        ?_userMarker,
      },
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildNotificationButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 20),
        child: const Align(
          alignment: Alignment.topRight,
          child: TripTopBar(),
        ),
      ),
    );
  }

  Widget _buildFakeSearchBar() {
    final show = _step == TripFlowStep.idle && !_isSearchActive;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      bottom: show ? 148 : -80,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: _openSearch,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Colors.black45),
              const SizedBox(width: 12),
              Text(
                'Para onde vamos hoje?',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isSearchActive,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          },
          child: _isSearchActive
              ? AddressSearchSheet(
                  key: const ValueKey('search_sheet'),
                  currentLocation: _currentLocation,
                  initialPickupAddress: _currentAddress,
                  onDestinationSelected: _onDestinationSelected,
                  onPickupSelected: _onPickupSelected,
                  onStopSelected: _onStopSelected,
                  onDismissed: _dismissSearch,
                  onSelectPickupOnMap: _enterPickOnMapMode,
                  onConfirmAddresses: _onConfirmAddresses,
                )
              : const SizedBox.shrink(key: ValueKey('no_search')),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: PointerInterceptor(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1.4),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
        child: _panelForStep(),
      ),
      ),
    );
  }

  Widget _panelForStep() {
    switch (_step) {
      case TripFlowStep.pickOnMap:
        return KeyedSubtree(
          key: const ValueKey('pickOnMap'),
          child: _buildSelectLocationButton(),
        );
      case TripFlowStep.passengerDetails:
        return KeyedSubtree(
          key: const ValueKey('passenger'),
          child: PassengerDetailsPanel(
            onConfirm: _onPassengerDetailsConfirmed,
            onBack: _onDetailsBack,
            isMinimized: _panelMinimized,
            onRestore: () => setState(() => _panelMinimized = false),
          ),
        );
      case TripFlowStep.searchingDriver:
        return const SearchingDriverPanel(key: ValueKey('searching'));
      case TripFlowStep.driverSelection:
        return DriverSelectionPanel(
          key: const ValueKey('driverSelection'),
          onDriverAccepted: _onDriverAccepted,
        );
      case TripFlowStep.driverConfirming:
        return _selectedDriver != null
            ? DriverConfirmingPanel(
                key: const ValueKey('driverConfirming'),
                driver: _selectedDriver!,
              )
            : const SizedBox.shrink(key: ValueKey('none'));
      case TripFlowStep.driverEnRoute:
        return _selectedDriver != null
            ? DriverEnRoutePanel(
                key: const ValueKey('driverEnRoute'),
                driver: _selectedDriver!,
                etaMinutes: _driverEtaMinutes,
                isExpanded: _enRoutePanelExpanded,
                onToggleExpand: () => setState(
                  () => _enRoutePanelExpanded = !_enRoutePanelExpanded,
                ),
              )
            : const SizedBox.shrink(key: ValueKey('none'));
      case TripFlowStep.tripStarted:
        return _selectedDriver != null
            ? DriverEnRoutePanel(
                key: const ValueKey('tripStarted'),
                driver: _selectedDriver!,
                etaMinutes: 0,
                isExpanded: _enRoutePanelExpanded,
                onToggleExpand: () => setState(
                  () => _enRoutePanelExpanded = !_enRoutePanelExpanded,
                ),
              )
            : const SizedBox.shrink(key: ValueKey('none'));
      case TripFlowStep.tripSummary:
        return TripSummaryPanel(
          key: const ValueKey('tripSummary'),
          pickupAddress: _pickupAddress ?? 'Carregando...',
          destinationAddress: _destinationAddress ?? 'Carregando...',
          paymentMethod: 'À vista (PIX)',
        );
      case TripFlowStep.tripRating:
        return _selectedDriver != null
            ? TripRatingPanel(
                key: const ValueKey('tripRating'),
                driver: _selectedDriver!,
                onClose: _onRatingClosed,
                onSubmit: _onRatingSubmitted,
              )
            : const SizedBox.shrink(key: ValueKey('none'));
      default:
        return const SizedBox.shrink(key: ValueKey('none'));
    }
  }

  Widget _buildSelectLocationButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _confirmPinLocation,
          icon: const Icon(Icons.check_rounded),
          label: const Text(
            'Selecionar local',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.highlight,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final show = _step == TripFlowStep.idle && !_isSearchActive;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      bottom: show ? 24 : -120,
      left: 20,
      right: 20,
      child: TripBottomNav(
        selectedIndex: _selectedNavIndex,
        onItemSelected: (index) {
          setState(() => _selectedNavIndex = index);
        },
      ),
    );
  }
}
