import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/maps/kz_map.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:kz_servicos_app/features/trip/data/models/address_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/data/models/recent_destination.dart';
import 'package:kz_servicos_app/features/trip/data/services/directions_service.dart';
import 'package:kz_servicos_app/features/trip/data/services/geocoding_address_service.dart';
import 'package:kz_servicos_app/features/trip/data/services/geocoding_service.dart';
import 'package:kz_servicos_app/features/trip/data/services/marker_animator.dart';
import 'package:kz_servicos_app/features/trip/data/services/place_details_service.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/passenger_form_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_execution_stage.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_request.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_stop.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/pending_confirmations_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/trip_creation_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/trip_creation_state.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/scheduled_trips_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/scheduled_trips_state.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/address_search_sheet.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/passenger_details_panel.dart';
import 'package:kz_servicos_app/features/trip/data/models/driver_candidate_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/mock_driver.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/driver_candidate.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_car_marker.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_confirming_panel.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_en_route_panel.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_selection_panel.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/searching_driver_popup.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/scheduled_trip_card.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_bottom_nav.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_details_sheet.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_type_choice_sheet.dart';
import 'package:kz_servicos_app/features/trip/data/repositories/flash_trip_repository_impl.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_rating_panel.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_summary_panel.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_arrived_sheet.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_top_bar.dart';

enum TripFlowStep {
  idle,
  pickOnMap,
  confirmPickup,
  passengerDetails,
  searchingDriver,
  driverSelection,
  driverSelected,
  driverConfirming,
  driverEnRoute,
  driverArrived,
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const List<String> _bannerAssets = [
    'public/assets/banner.png',
    'public/assets/banner2.png',
  ];

  final Completer<KzMapController> _mapController = Completer();
  final DirectionsService _directionsService = DirectionsService();
  final GeocodingService _geocodingService = GeocodingService();
  final GeocodingAddressService _geocodingAddressService =
      GeocodingAddressService();
  final PlaceDetailsService _placeDetailsService = PlaceDetailsService();

  KzMapController? _controller;
  Marker? _userMarker;
  bool _isSearchActive = false;
  int _currentTripIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  AnimationController? _pulseController;
  List<LatLng> _routePoints = [];

  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 16.5,
  );

  LatLng? _currentLocation;
  int _selectedNavIndex = 0;
  TripFlowStep _step = TripFlowStep.idle;

  LatLng? _destinationLatLng;
  LatLng? _pickupLatLng;

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  String? _currentAddress;
  String? _confirmPickupAddress;
  bool _panelMinimized = false;
  List<LatLng> _stops = [];

  // Place IDs from address selection
  String? _pickupPlaceId;
  String? _destinationPlaceId;

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
  bool _isCreatingTrip = false;
  PassengerFormData? _lastPassengerFormData;
  PassengerFormData? _outboundPassengerFormData;
  PassengerFormData? _returnPassengerFormData;
  bool _isEditingReturnDetails = false;
  bool _isRoundTripRequest = false;
  bool _isFlashRequest = false;
  bool _searchingCanGoHome = false;
  AnimationController? _searchRadarController;

  // Realtime in-trip tracking
  String? _searchingTripId;
  String? _activeTripId;
  String? _activeDriverProfileId;
  RealtimeChannel? _tripChannel;
  RealtimeChannel? _driverLocationChannel;
  MarkerAnimator? _carAnimator;
  TripExecutionStage? _currentExecutionStage;
  int? _currentStopOrder;
  List<TripStop> _tripStops = const [];
  RealtimeChannel? _chatMessagesChannel;
  List<DriverCandidate> _approvedCandidates = [];
  RealtimeChannel? _candidatesChannel;
  LatLng? _liveDriverLocation;
  double _currentBearing = 0;
  LatLng? _previousDriverLocation;
  String? _activeDriverName;
  String? _activeDriverUserId;
  // CHANGE 1: new state variables
  String? _activeDriverPhone;
  String? _activeDriverAvatarUrl;
  double? _activeOfferedPrice;
  String? _activeVehicleSummary;
  String? _activeVehiclePlate;
  int _driverDistanceMeters = 0;
  double _navHeading = 0.0;
  int _tripEtaSeconds = 0;
  int _tripDistanceMeters = 0;
  BitmapDescriptor? _cachedYellowDriverDotIcon;
  final Map<int, BitmapDescriptor> _cachedCarDescriptors = {};

  Future<BitmapDescriptor> _carDescriptorForBearing(double bearing) async {
    final normalized = ((bearing % 360) + 360) % 360;
    final index = (normalized / 30).round() % 12;
    final cached = _cachedCarDescriptors[index];
    if (cached != null) return cached;
    final path = DriverCarMarker.assetForBearing(bearing);
    try {
      final d = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(64, 64)),
        path,
      );
      _cachedCarDescriptors[index] = d;
      return d;
    } catch (e) {
      debugPrint('[KZ-C] car sprite missing for bearing=$index path=$path err=$e');
      _cachedYellowDriverDotIcon ??= await _createYellowDriverDotIcon();
      return _cachedYellowDriverDotIcon!;
    }
  }
  StreamSubscription<Position>? _tripLocationStream;
  DateTime? _lastDriverRouteUpdate;
  List<RecentDestination> _recentDestinations = [];
  int _totalUnreadMessages = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    _requestLocationAndInit();
    _loadScheduledTrips();
    _loadPendingConfirmations();
    unawaited(_loadRecentDestinations());
    _subscribeToChatMessages();
    unawaited(_loadUnreadMessages());
    _startBannerCarousel();
    _searchRadarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addListener(_updateSearchRadar);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_step == TripFlowStep.idle) {
        unawaited(_resetCameraToUserLocation());
      } else if (_step == TripFlowStep.searchingDriver &&
          _searchingTripId != null) {
        _fetchApprovedCandidates(_searchingTripId!);
      }
    }
  }

  void _startBannerCarousel() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final nextIndex = (_currentBannerIndex + 1) % _bannerAssets.length;
      _bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _loadScheduledTrips() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      context.read<ScheduledTripsCubit>().load(authState.user.id);
    }
  }

  void _loadPendingConfirmations() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      context.read<PendingConfirmationsCubit>().load(authState.user.id);
      _checkExistingSearchingTrip(authState.user.id);
    }
  }

  void _subscribeToChatMessages() {
    _chatMessagesChannel?.unsubscribe();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _chatMessagesChannel = Supabase.instance.client
        .channel('client-chat-messages-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (_) => _loadUnreadMessages(),
        )
        .subscribe();
  }

  Future<void> _loadUnreadMessages() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final res = await Supabase.instance.client
          .from('chat_messages')
          .select('id, chat_rooms!inner(client_id)')
          .eq('chat_rooms.client_id', userId)
          .neq('sender_id', userId)
          .eq('is_read', false);
      if (!mounted) return;
      setState(() => _totalUnreadMessages = (res as List).length);
    } catch (_) {}
  }

  Future<void> _loadRecentDestinations() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final savedRows = await Supabase.instance.client
          .from('user_saved_addresses')
          .select('label, addresses(formatted_address, latitude, longitude)')
          .eq('user_id', userId)
          .inFilter('label', ['home', 'work']);

      final rows = await Supabase.instance.client
          .from('trips')
          .select(
            'dropoff:addresses!dropoff_address_id(formatted_address, latitude, longitude)',
          )
          .eq('client_id', userId)
          .not('dropoff_address_id', 'is', null)
          .order('created_at', ascending: false)
          .limit(12);

      final seen = <String>{};
      final recent = <RecentDestination>[];
      for (final row in savedRows as List) {
        final label = row['label'] as String?;
        final address = row['addresses'] as Map<String, dynamic>?;
        final formatted = address?['formatted_address'] as String?;
        final lat = (address?['latitude'] as num?)?.toDouble();
        final lng = (address?['longitude'] as num?)?.toDouble();
        if (label == null || formatted == null || lat == null || lng == null) {
          continue;
        }
        seen.add(formatted.toLowerCase());
        recent.add(
          RecentDestination(
            formattedAddress: formatted,
            latitude: lat,
            longitude: lng,
            savedLabel: label,
          ),
        );
      }
      for (final row in rows as List) {
        final address = row['dropoff'] as Map<String, dynamic>?;
        final formatted = address?['formatted_address'] as String?;
        final lat = (address?['latitude'] as num?)?.toDouble();
        final lng = (address?['longitude'] as num?)?.toDouble();
        if (formatted == null || lat == null || lng == null) continue;
        if (!seen.add(formatted.toLowerCase())) continue;
        recent.add(
          RecentDestination(
            formattedAddress: formatted,
            latitude: lat,
            longitude: lng,
          ),
        );
      }
      if (!mounted) return;
      setState(() => _recentDestinations = recent);
    } catch (_) {}
  }

  Future<void> _saveCurrentDestinationAs(String label) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final position = _destinationLatLng;
    final formattedAddress = _destinationAddress;
    if (userId == null || position == null || formattedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um destino antes de salvar.')),
      );
      return;
    }

    try {
      final structured = _destinationPlaceId != null
          ? await _geocodingAddressService.getAddressFromPlaceId(
              _destinationPlaceId!,
            )
          : await _geocodingAddressService.reverseGeocodeToAddress(position);

      final address = structured ??
          TripAddress(
            googlePlaceId: _destinationPlaceId,
            formattedAddress: formattedAddress,
            city: 'Desconhecida',
            state: 'XX',
            latitude: position.latitude,
            longitude: position.longitude,
          );
      final inserted = await Supabase.instance.client
          .from('addresses')
          .insert(AddressModel.fromEntity(address).toJson())
          .select('id')
          .single();
      final addressId = inserted['id'] as String;

      final existing = await Supabase.instance.client
          .from('user_saved_addresses')
          .select('id')
          .eq('user_id', userId)
          .eq('label', label)
          .maybeSingle();

      if (existing == null) {
        await Supabase.instance.client.from('user_saved_addresses').insert({
          'user_id': userId,
          'address_id': addressId,
          'label': label,
        });
      } else {
        await Supabase.instance.client
            .from('user_saved_addresses')
            .update({
              'address_id': addressId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id'] as String);
      }

      await _loadRecentDestinations();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            label == 'home'
                ? 'Endereço de casa salvo.'
                : 'Endereço de trabalho salvo.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o endereço.')),
      );
    }
  }

  void _onRecentDestinationSelected(RecentDestination destination) {
    setState(() {
      _destinationAddress = destination.formattedAddress;
      _destinationLatLng = LatLng(destination.latitude, destination.longitude);
      _destinationPlaceId = null;
      if (_pickupLatLng == null && _currentLocation != null) {
        _pickupLatLng = _currentLocation;
        _pickupPlaceId = '_current_location_';
      }
      _isSearchActive = false;
    });
    unawaited(_drawSelectedRoutePreview(fitCamera: true));
    unawaited(_onConfirmAddresses());
  }

  Future<void> _checkExistingSearchingTrip(String clientId) async {
    if (_step != TripFlowStep.idle) return;
    try {
      final response = await Supabase.instance.client
          .from('trips')
          .select(
            'id, status, driver_profile_id, started_at, driver_arrived_at',
          )
          .eq('client_id', clientId)
          .inFilter('status', ['searching_drivers', 'started'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null || !mounted) return;
      final tripId = response['id'] as String;
      final status = response['status'] as String;
      final driverProfileId = response['driver_profile_id'] as String?;
      final startedAt = response['started_at'];
      final driverArrivedAt = response['driver_arrived_at'];

      if (status == 'searching_drivers') {
        if (_searchingTripId == tripId) return;
        setState(() {
          _searchingTripId = tripId;
          _step = TripFlowStep.driverSelection;
        });
        _subscribeToTripStart(tripId);
      } else if (status == 'started' && driverProfileId != null) {
        // Resume an active trip the client navigated away from
        await _fetchDriverNameAndStartTracking(tripId, driverProfileId);
        if (!mounted) return;
        if (startedAt != null) {
          setState(() => _step = TripFlowStep.tripStarted);
          _enterInTripMapView();
        } else if (driverArrivedAt != null) {
          setState(() => _step = TripFlowStep.driverArrived);
          _enterDriverArrivedMapView();
        }
        // If neither, driverEnRoute was already set by _fetchDriverNameAndStartTracking
      }
    } catch (e) {
      debugPrint('[KZ] _checkExistingSearchingTrip error: $e');
    }
  }

  Future<void> _openSearch() async {
    final tripKind = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PointerInterceptor(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const TripTypeChoiceSheet(),
        ),
      ),
    );
    if (tripKind == null || !mounted) return;
    if (tripKind == 'flash') {
      setState(() {
        _isFlashRequest = true;
        _isRoundTripRequest = false;
        _isEditingReturnDetails = false;
        _outboundPassengerFormData = null;
        _returnPassengerFormData = null;
        _lastPassengerFormData = null;
      });
      _resolveCurrentAddress();
      setState(() => _isSearchActive = true);
      return;
    }
    final isRoundTrip = await _showTripTypePicker();
    if (isRoundTrip == null || !mounted) return;
    setState(() {
      _isFlashRequest = false;
      _isRoundTripRequest = isRoundTrip;
      _isEditingReturnDetails = false;
      _outboundPassengerFormData = null;
      _returnPassengerFormData = null;
      _lastPassengerFormData = null;
    });
    _resolveCurrentAddress();
    setState(() => _isSearchActive = true);
  }

  Future<bool?> _showTripTypePicker() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PointerInterceptor(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Qual o tipo da viagem?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _TripTypeOption(
                icon: Icons.arrow_forward_rounded,
                title: 'Somente ida',
                subtitle: 'Uma origem e um destino',
                onTap: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: 10),
              _TripTypeOption(
                icon: Icons.sync_alt_rounded,
                title: 'Ida e volta',
                subtitle: 'A corrida será sinalizada para retorno',
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resolveCurrentAddress() async {
    if (_currentLocation == null || _currentAddress != null) return;
    final address = await _geocodingService.reverseGeocode(_currentLocation!);
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
      await controller.animateTo(target: latLng, zoom: 17.5);
    } catch (_) {}
  }

  Future<void> _resetCameraToUserLocation() async {
    final location = _currentLocation;
    if (location == null) return;
    try {
      final controller = await _mapController.future;
      await controller.animateTo(target: location, zoom: 17.5);
    } catch (_) {}
  }

  // ──── Address selection ────

  Future<void> _onDestinationSelected(PlacePrediction prediction) async {
    _destinationPlaceId = prediction.placeId;
    final latLng = await _placeDetailsService.getPlaceLatLng(
      prediction.placeId,
    );
    if (!mounted) return;
    final destIcon = await _createYellowCircleIcon();
    setState(() {
      _destinationLatLng = latLng;
      _destinationAddress = prediction.description;
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
      if (_pickupLatLng == null && _currentLocation != null) {
        _pickupLatLng = _currentLocation;
      }
      await _drawSelectedRoutePreview(fitCamera: true);
    }
  }

  Future<void> _onPickupSelected(PlacePrediction prediction) async {
    _pickupPlaceId = prediction.placeId;
    LatLng? latLng;
    if (prediction.placeId == '_current_location_' &&
        _currentLocation != null) {
      latLng = _currentLocation;
    } else {
      latLng = await _placeDetailsService.getPlaceLatLng(prediction.placeId);
    }
    if (!mounted || latLng == null) return;
    setState(() {
      _pickupLatLng = latLng;
      _pickupAddress = prediction.description;
    });
    await _drawSelectedRoutePreview(fitCamera: _destinationLatLng != null);
  }

  Future<void> _onConfirmAddresses() async {
    // If pickup not explicitly set, use current location
    if (_pickupLatLng == null && _currentLocation != null) {
      _pickupLatLng = _currentLocation;
    }
    if (_pickupLatLng == null || _destinationLatLng == null) return;
    setState(() => _isSearchActive = false);
    await _showRouteAndProceed();
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
    final center = _controller!.center;
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
    await controller.animateTo(target: _pickupLatLng!, zoom: 19);
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
    final center = _controller!.center;
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

  Future<void> _drawSelectedRoutePreview({bool fitCamera = false}) async {
    final pickup = _pickupLatLng ?? _currentLocation;
    final destination = _destinationLatLng;
    if (pickup == null || destination == null) return;

    final routePoints = await _directionsService.fetchRoute(
      origin: pickup,
      destination: destination,
      waypoints: _stops,
    );
    if (!mounted) return;

    final pickupIcon = await _createYellowPinIcon();
    final destIcon = await _createYellowCircleIcon();
    if (!mounted) return;

    setState(() {
      _routePoints = routePoints;
      _markers = {
        ..._markers.where(
          (m) =>
              m.markerId.value != 'pickup' && m.markerId.value != 'destination',
        ),
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: pickupIcon,
          anchor: const Offset(0.5, 1.0),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          icon: destIcon,
          anchor: const Offset(0.5, 0.5),
        ),
      };
      _polylines = routePoints.isEmpty
          ? {}
          : {
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
    });
    if (routePoints.isNotEmpty) {
      _startPulseAnimation(routePoints);
    } else {
      _stopPulseAnimation();
    }
    if (fitCamera) {
      await _fitPoints(
        routePoints.isNotEmpty ? routePoints : [pickup, destination],
        padding: 72,
        maxZoom: 16,
      );
    }
  }

  void _dismissSearch() {
    setState(() => _isSearchActive = false);
    unawaited(_resetCameraToUserLocation());
  }

  // ──── Map utilities ────

  Future<BitmapDescriptor> _createBlueDotIcon() async {
    const size = 24.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      8,
      Paint()..color = const Color(0xFF4285F4),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createYellowDriverDotIcon() async {
    const size = 32.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      13,
      Paint()..color = AppColors.highlight.withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      8,
      Paint()..color = AppColors.highlight,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  void _startPulseAnimation(List<LatLng> points) {
    _stopPulseAnimation();
    if (points.length < 2) return;
    _setPulseRoutePoints(points);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _pulseController!.addListener(_updatePulsePolyline);
    _pulseController!.repeat();
  }

  void _setPulseRoutePoints(List<LatLng> points) {
    _routePoints = points;
    _routeDistances = _computeSegmentDistances(points);
    _routeTotalLength = _routeDistances.isEmpty ? 0 : _routeDistances.last;
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
    final hav =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
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
            color: AppColors.highlight.withValues(alpha: 0.60 * fadeFactor),
            width: 12,
          ),
        // Traveling highlight — bright core segment
        if (glowPoints.length >= 2)
          Polyline(
            polylineId: const PolylineId('pulse_core'),
            points: glowPoints,
            color: const Color(0xFFFFE08A).withValues(alpha: fadeFactor),
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

  bool _isScheduledRequest(PassengerFormData formData) {
    return formData.scheduledDatetime.difference(DateTime.now()) >
        const Duration(minutes: 5);
  }

  String? _roundTripObservations({
    required PassengerFormData outbound,
    PassengerFormData? inbound,
  }) {
    if (!_isRoundTripRequest || inbound == null) {
      return outbound.observations;
    }

    final parts = <String>[];
    void addSection(String title, PassengerFormData data) {
      final section = <String>[];
      if (data.hasChildren && data.childrenDescription?.isNotEmpty == true) {
        section.add('Crianças: ${data.childrenDescription}');
      }
      if (data.hasLuggage && data.luggageDescription?.isNotEmpty == true) {
        section.add('Bagagem: ${data.luggageDescription}');
      }
      if (data.observations?.isNotEmpty == true) {
        section.add(data.observations!);
      }
      if (section.isNotEmpty) {
        parts.add('$title:\n${section.join('\n')}');
      }
    }

    addSection('Detalhes da ida', outbound);
    addSection('Detalhes da volta', inbound);
    return parts.isEmpty ? null : parts.join('\n\n');
  }

  void _startSearchRadar() {
    _searchRadarController?.repeat();
    _updateSearchRadar();
  }

  void _stopSearchRadar() {
    _searchRadarController?.stop();
    if (_circles.any((c) => c.circleId.value.startsWith('search_radar'))) {
      setState(() {
        _circles = {
          ..._circles.where(
            (c) => !c.circleId.value.startsWith('search_radar'),
          ),
        };
      });
    }
  }

  void _updateSearchRadar() {
    if (!mounted || _step != TripFlowStep.searchingDriver) return;
    final center = _pickupLatLng ?? _currentLocation;
    if (center == null) return;
    final progress = _searchRadarController?.value ?? 0;
    final rings = <Circle>{};
    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1.0;
      final alpha = (1.0 - phase).clamp(0.0, 1.0);
      rings.add(
        Circle(
          circleId: CircleId('search_radar_$i'),
          center: center,
          radius: 25 + phase * 120,
          strokeWidth: 2,
          strokeColor: AppColors.highlight.withValues(alpha: alpha * 0.75),
          fillColor: AppColors.highlight.withValues(alpha: alpha * 0.10),
          zIndex: 4,
        ),
      );
    }
    setState(() {
      _circles = {
        ..._circles.where((c) => !c.circleId.value.startsWith('search_radar')),
        ...rings,
      };
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPulseAnimation();
    _stopTripTracking();
    _candidatesChannel?.unsubscribe();
    _chatMessagesChannel?.unsubscribe();
    _searchingTimer?.cancel();
    _confirmingTimer?.cancel();
    _driverMoveTimer?.cancel();
    _tripSummaryTimer?.cancel();
    _bannerTimer?.cancel();
    _searchRadarController?.dispose();
    _bannerController.dispose();
    _tripLocationStream?.cancel();
    super.dispose();
  }

  void _goToNextTrip(int total) {
    if (total <= 1) return;
    setState(() => _currentTripIndex = (_currentTripIndex + 1) % total);
  }

  void _goToPrevTrip(int total) {
    if (total <= 1) return;
    setState(
      () => _currentTripIndex = ((_currentTripIndex - 1) + total) % total,
    );
  }

  Future<void> _fitBounds() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;

    final allPoints = <LatLng>[
      if (_routePoints.isNotEmpty) ..._routePoints,
      _pickupLatLng!,
      _destinationLatLng!,
      ..._stops,
    ];
    await _fitPoints(
      allPoints,
      padding: 82,
      maxZoom: 16,
      verticalOffset: MediaQuery.of(context).size.height * 0.18,
    );
  }

  Future<void> _fitPoints(
    List<LatLng> points, {
    double padding = 88,
    double maxZoom = 16,
    double verticalOffset = 0,
  }) async {
    if (points.isEmpty) return;
    final controller = await _mapController.future;

    final allPoints = points;
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
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    if (latSpan < 0.0004 && lngSpan < 0.0004) {
      await controller.animateTo(target: allPoints.first, zoom: maxZoom);
      if (verticalOffset != 0) {
        await controller.scrollBy(0, verticalOffset);
      }
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await controller.fitBounds(bounds, padding: padding, maxZoom: maxZoom);
    if (verticalOffset != 0) {
      await controller.scrollBy(0, verticalOffset);
    }
  }

  Future<void> _onPassengerDetailsConfirmed(PassengerFormData formData) async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;
    if (_isCreatingTrip) return;

    if (_isRoundTripRequest && !_isEditingReturnDetails) {
      setState(() {
        _outboundPassengerFormData = formData;
        _returnPassengerFormData ??= PassengerFormData(
          adults: formData.adults,
          scheduledDatetime:
              formData.scheduledDatetime.add(const Duration(hours: 2)),
          hasChildren: formData.hasChildren,
          childrenDescription: formData.childrenDescription,
          hasLuggage: formData.hasLuggage,
          luggageDescription: formData.luggageDescription,
          observations: formData.observations,
          paymentMethod: formData.paymentMethod,
          isRoundTrip: true,
        );
        _lastPassengerFormData = _returnPassengerFormData;
        _isEditingReturnDetails = true;
        _panelMinimized = false;
      });
      return;
    }

    final outboundFormData = _outboundPassengerFormData ?? formData;
    final returnFormData =
        _isRoundTripRequest ? formData : null;

    // Get current user ID before async gaps
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão expirada. Faça login novamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final userId = authState.user.id;
    final tripCubit = context.read<TripCreationCubit>();

    setState(() {
      _returnPassengerFormData = returnFormData;
      _lastPassengerFormData = returnFormData ?? outboundFormData;
      _searchingCanGoHome = _isScheduledRequest(outboundFormData);
      _isCreatingTrip = true;
      _step = TripFlowStep.searchingDriver;
    });
    _startSearchRadar();

    try {
      // Resolve structured addresses
      final pickupAddress =
          _pickupPlaceId != null && _pickupPlaceId != '_current_location_'
          ? await _geocodingAddressService.getAddressFromPlaceId(
              _pickupPlaceId!,
            )
          : await _geocodingAddressService.reverseGeocodeToAddress(
              _pickupLatLng!,
            );

      final dropoffAddress = _destinationPlaceId != null
          ? await _geocodingAddressService.getAddressFromPlaceId(
              _destinationPlaceId!,
            )
          : await _geocodingAddressService.reverseGeocodeToAddress(
              _destinationLatLng!,
            );

      if (pickupAddress == null || dropoffAddress == null) {
        throw Exception('Could not resolve addresses');
      }

      // ── Flash flow ─────────────────────────────────────────────
      if (_isFlashRequest) {
        final flashRepo = FlashTripRepositoryImpl(
          client: Supabase.instance.client,
        );
        final tripId = await flashRepo.createFlashTripFromAddresses(
          pickupAddress: pickupAddress,
          dropoffAddress: dropoffAddress,
          passengerCount: outboundFormData.adults,
          childrenCount: outboundFormData.hasChildren ? 1 : 0,
          luggageCount: outboundFormData.hasLuggage ? 1 : 0,
          observations: outboundFormData.observations ?? '',
        );
        if (!mounted) return;
        setState(() {
          _isFlashRequest = false;
          _step = TripFlowStep.idle;
        });
        context.go('/flash/searching/$tripId');
        return;
      }

      // Build trip request
      final tripRequest = TripRequest(
        clientId: userId,
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        scheduledDatetime: outboundFormData.scheduledDatetime,
        passengerCount: outboundFormData.adults,
        childrenDescription: outboundFormData.childrenDescription,
        luggageDescription: outboundFormData.luggageDescription,
        observations: _roundTripObservations(
          outbound: outboundFormData,
          inbound: returnFormData,
        ),
        paymentMethod: outboundFormData.paymentMethod,
        isRoundTrip: _isRoundTripRequest,
        returnDatetime: returnFormData?.scheduledDatetime,
      );

      // Submit via cubit
      if (!mounted) return;
      await tripCubit.submit(tripRequest);
    } catch (e) {
      debugPrint('[KZ] Trip creation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao criar viagem. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _step = TripFlowStep.passengerDetails);
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingTrip = false);
      }
    }
  }

  // ──── Realtime tracking ────

  void _startTripTracking(
    String tripId,
    String driverProfileId,
    String driverName,
  ) {
    _activeTripId = tripId;
    _activeDriverProfileId = driverProfileId;
    _activeDriverName = driverName;

    final supabase = Supabase.instance.client;

    debugPrint(
      '[KZ-C] _startTripTracking subscribing trip-$tripId driverProfileId=$driverProfileId',
    );
    _tripChannel = supabase
        .channel('trip-$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'trips',
          callback: (payload) {
            // Filtrar manualmente: sem REPLICA IDENTITY FULL, o filtro
            // Postgres em UPDATE pode falhar para colunas não-PK.
            final id = payload.newRecord['id'] as String?;
            if (id != tripId) return;
            _onTripUpdate(payload);
          },
        )
        .subscribe((status, error) {
          debugPrint('[KZ-C] trip-$tripId channel status=$status err=$error');
        });

    _carAnimator = MarkerAnimator(vsync: this, duration: const Duration(seconds: 5));

    _driverLocationChannel = supabase
        .channel('driver-loc-$driverProfileId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'driver_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_profile_id',
            value: driverProfileId,
          ),
          callback: _onDriverLocationUpdate,
        )
        .subscribe();

    _fetchInitialDriverLocation(driverProfileId);
    unawaited(_fetchTripStops(tripId));
  }

  Future<void> _fetchInitialDriverLocation(String driverProfileId) async {
    try {
      final data = await Supabase.instance.client
          .from('driver_locations')
          .select('latitude, longitude')
          .eq('driver_profile_id', driverProfileId)
          .maybeSingle();
      if (data == null || !mounted) return;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      setState(() {
        _liveDriverLocation = LatLng(lat, lng);
        _lastDriverRouteUpdate = null;
      });
      unawaited(_updateDriverMarker());
      unawaited(_fetchDriverToPickupRoute(fitCamera: true));
    } catch (e) {
      debugPrint('[KZ-C] _fetchInitialDriverLocation error: $e');
    }
  }

  Future<void> _fetchTripStops(String tripId) async {
    try {
      final rows = await Supabase.instance.client
          .from('trip_stops')
          .select('id, stop_order, addresses(latitude, longitude, formatted_address)')
          .eq('trip_id', tripId)
          .order('stop_order', ascending: true);
      if (!mounted) return;
      setState(() {
        _tripStops = (rows as List).map((r) {
          final m = r as Map<String, dynamic>;
          final addr = (m['addresses'] as Map?) ?? const {};
          return TripStop(
            id: m['id'] as String,
            stopOrder: (m['stop_order'] as num).toInt(),
            location: LatLng(
              (addr['latitude'] as num?)?.toDouble() ?? 0,
              (addr['longitude'] as num?)?.toDouble() ?? 0,
            ),
            address: addr['formatted_address'] as String? ?? '',
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('[KZ-C] _fetchTripStops error: $e');
      if (mounted) setState(() => _tripStops = const []);
    }
  }

  void _stopTripTracking() {
    _tripChannel?.unsubscribe();
    _driverLocationChannel?.unsubscribe();
    _tripChannel = null;
    _driverLocationChannel = null;
    _carAnimator?.dispose();
    _carAnimator = null;
    _currentExecutionStage = null;
    _currentStopOrder = null;
    _tripStops = const [];
    _previousDriverLocation = null;
  }

  void _onTripUpdate(PostgresChangePayload payload) {
    debugPrint(
      '[KZ-C] _onTripUpdate received: new=${payload.newRecord} old=${payload.oldRecord}',
    );
    if (!mounted) {
      debugPrint('[KZ-C] _onTripUpdate IGNORED (not mounted)');
      return;
    }
    if (payload.eventType == PostgresChangeEvent.delete) {
      _handleRemoteTripCancelled();
      return;
    }
    final record = payload.newRecord;
    final driverArrivedAt = record['driver_arrived_at'];
    final startedAt = record['started_at'];
    final status = record['status'] as String?;
    final currentStep = _step;
    debugPrint(
      '[KZ-C] _onTripUpdate parsed: driverArrivedAt=$driverArrivedAt startedAt=$startedAt status=$status currentStep=$currentStep',
    );

    if (status == 'cancelled') {
      _handleRemoteTripCancelled();
      return;
    }

    final stageWire = record['execution_stage'] as String?;
    final stopOrder = (record['current_stop_order'] as num?)?.toInt();
    final newStage = TripExecutionStage.fromString(stageWire);
    if (newStage != _currentExecutionStage || stopOrder != _currentStopOrder) {
      setState(() {
        _currentExecutionStage = newStage;
        _currentStopOrder = stopOrder;
      });
    }

    // Trip finalizada — prioridade máxima, ignora outras transições.
    if (status == 'finished') {
      debugPrint('[KZ-C] Transition → tripRating (finished)');
      _stopTripTracking();
      _tripSummaryTimer?.cancel();
      setState(() => _step = TripFlowStep.tripRating);
      return;
    }

    if (startedAt != null && currentStep != TripFlowStep.tripStarted) {
      debugPrint('[KZ-C] Transition → tripStarted');
      setState(() => _step = TripFlowStep.tripStarted);
      _enterInTripMapView();
    } else if (driverArrivedAt != null &&
        currentStep == TripFlowStep.driverEnRoute) {
      debugPrint('[KZ-C] Transition → driverArrived');
      setState(() => _step = TripFlowStep.driverArrived);
      _enterDriverArrivedMapView();
    } else {
      debugPrint('[KZ-C] No transition (conditions not met)');
    }
  }

  void _handleRemoteTripCancelled() {
    if (!mounted) return;
    _tripChannel?.unsubscribe();
    _tripChannel = null;
    _candidatesChannel?.unsubscribe();
    _candidatesChannel = null;
    _stopTripTracking();
    _resetToIdle();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esta corrida foi cancelada pela KZ.')),
    );
    context.go('/trip');
  }

  void _onDriverLocationUpdate(PostgresChangePayload payload) {
    if (!mounted) return;
    final record = payload.newRecord;
    final lat = (record['latitude'] as num?)?.toDouble();
    final lng = (record['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    final target = LatLng(lat, lng);
    final previous = _previousDriverLocation ?? _liveDriverLocation ?? target;
    var newBearing = _currentBearing;
    if (previous.latitude != target.latitude || previous.longitude != target.longitude) {
      final b = Geolocator.bearingBetween(
        previous.latitude, previous.longitude,
        target.latitude, target.longitude,
      );
      if (!b.isNaN) newBearing = b;
    }

    _previousDriverLocation = target;

    final animator = _carAnimator;
    if (animator == null) {
      // Fallback: no animator, snap directly (edge case: update arrives before start).
      setState(() {
        _liveDriverLocation = target;
        _currentBearing = newBearing;
      });
      unawaited(_updateDriverMarker(bearing: newBearing));
    } else {
      animator.animateTo(
        target: target,
        bearing: newBearing,
        onTick: (interpPos, interpBearing) {
          if (!mounted) return;
          setState(() {
            _liveDriverLocation = interpPos;
            _currentBearing = interpBearing;
          });
          unawaited(_updateDriverMarker(bearing: interpBearing));
        },
      );
    }

    if (_step == TripFlowStep.driverEnRoute && _pickupLatLng != null) {
      final now = DateTime.now();
      if (_lastDriverRouteUpdate == null ||
          now.difference(_lastDriverRouteUpdate!).inSeconds >= 15) {
        _lastDriverRouteUpdate = now;
        _fetchDriverToPickupRoute();
      }
    }
  }

  // CHANGE 2: fetchRouteWithDuration + ETA + distance + camera fit
  Future<void> _fetchDriverToPickupRoute({bool fitCamera = false}) async {
    if (_liveDriverLocation == null || _pickupLatLng == null) return;
    await _updateDriverMarker();
    final result = await _directionsService.fetchRouteWithDuration(
      origin: _liveDriverLocation!,
      destination: _pickupLatLng!,
    );
    if (!mounted || result.points.isEmpty) return;
    final etaMin = (result.durationSeconds / 60).ceil().clamp(1, 120);
    setState(() {
      _driverEtaMinutes = etaMin;
      _driverDistanceMeters = result.distanceMeters;
      _polylines = {
        ..._polylines.where(
          (p) =>
              p.polylineId.value != 'driver_route_glow' &&
              p.polylineId.value != 'driver_route' &&
              p.polylineId.value != 'route_glow' &&
              p.polylineId.value != 'route' &&
              p.polylineId.value != 'pulse_glow' &&
              p.polylineId.value != 'pulse_core',
        ),
        Polyline(
          polylineId: const PolylineId('route_glow'),
          points: result.points,
          color: AppColors.highlight.withValues(alpha: 0.18),
          width: 12,
        ),
        Polyline(
          polylineId: const PolylineId('route'),
          points: result.points,
          color: AppColors.highlight,
          width: 5,
        ),
      };
    });
    _startPulseAnimation(result.points);
    if (_liveDriverLocation != null && _pickupLatLng != null) {
      await _fitPoints(
        [_liveDriverLocation!, _pickupLatLng!, ...result.points],
        padding: 72,
        maxZoom: 16.5,
      );
    }
  }

  Future<void> _updateDriverMarker({double? bearing}) async {
    if (_liveDriverLocation == null) return;
    final clientLocation = _pickupLatLng ?? _currentLocation;
    _cachedBlueDotIcon ??= await _createBlueDotIcon();
    final carIcon = await _carDescriptorForBearing(bearing ?? _currentBearing);
    if (!mounted) return;
    setState(() {
      _markers = {
        ..._markers.where(
          (m) =>
              m.markerId.value != 'live_driver' &&
              m.markerId.value != 'client_location' &&
              m.markerId.value != 'pickup',
        ),
        if (clientLocation != null)
          Marker(
            markerId: const MarkerId('client_location'),
            position: clientLocation,
            icon: _cachedBlueDotIcon!,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 9,
          ),
        Marker(
          markerId: const MarkerId('live_driver'),
          position: _liveDriverLocation!,
          icon: carIcon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 10,
        ),
      };
    });
  }

  Future<void> _enterInTripMapView() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;

    setState(() {
      _polylines = {};
      _markers = _markers
          .where((m) => m.markerId.value == 'user_location')
          .toSet();
    });

    final origin = _pickupLatLng!;
    final result = await _directionsService.fetchRouteWithDuration(
      origin: origin,
      destination: _destinationLatLng!,
    );
    if (!mounted) return;

    if (result.points.isNotEmpty) {
      final destMarker = Marker(
        markerId: const MarkerId('destination'),
        position: _destinationLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      );
      setState(() {
        _routePoints = result.points;
        _tripEtaSeconds = result.durationSeconds;
        _tripDistanceMeters = result.distanceMeters;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route_glow'),
            points: result.points,
            color: AppColors.highlight.withValues(alpha: 0.18),
            width: 12,
          ),
          Polyline(
            polylineId: const PolylineId('route'),
            points: result.points,
            color: AppColors.highlight,
            width: 5,
          ),
        };
        _markers = {..._markers, destMarker};
      });
      _startPulseAnimation(result.points);
      await _fitPoints(result.points, padding: 84, maxZoom: 16.5);
    }

    if (!mounted) return;

    // GPS navigation: high-accuracy stream with bearing/tilt camera follow
    _tripLocationStream?.cancel();
    _tripLocationStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((pos) async {
          if (!mounted) return;
          final latLng = LatLng(pos.latitude, pos.longitude);
          final heading = pos.heading >= 0 ? pos.heading : 0.0;
          _cachedBlueDotIcon ??= await _createBlueDotIcon();
          if (!mounted) return;
          setState(() {
            _currentLocation = latLng;
            _navHeading = heading;
            _userMarker = Marker(
              markerId: const MarkerId('user_location'),
              position: latLng,
              icon: _cachedBlueDotIcon!,
              anchor: const Offset(0.5, 0.5),
              zIndexInt: 99,
              flat: true,
              rotation: heading,
            );
            _markers = {
              ..._markers.where((m) => m.markerId.value != 'user_location'),
              _userMarker!,
            };
          });
        });
  }

  void _subscribeToTripStart(String tripId) {
    final supabase = Supabase.instance.client;
    debugPrint('[KZ-C] _subscribeToTripStart subscribing trip-start-$tripId');
    _tripChannel = supabase
        .channel('trip-start-$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tripId,
          ),
          callback: (payload) {
            debugPrint('[KZ-C] trip-start payload: ${payload.newRecord}');
            if (payload.eventType == PostgresChangeEvent.delete) {
              _handleRemoteTripCancelled();
              return;
            }
            final status = payload.newRecord['status'] as String?;
            final driverProfileId =
                payload.newRecord['driver_profile_id'] as String?;
            if (status == 'cancelled') {
              _handleRemoteTripCancelled();
              return;
            }
            if (status == 'started' && driverProfileId != null) {
              debugPrint(
                '[KZ-C] status=started → handing off to _fetchDriverNameAndStartTracking',
              );
              _tripChannel?.unsubscribe();
              _tripChannel = null;
              _fetchDriverNameAndStartTracking(tripId, driverProfileId);
            }
          },
        )
        .subscribe((status, error) {
          debugPrint(
            '[KZ-C] trip-start-$tripId channel status=$status err=$error',
          );
        });
    _subscribeToApprovedCandidates(tripId);
    _fetchApprovedCandidates(tripId);
  }

  Future<void> _fetchApprovedCandidates(String tripId) async {
    try {
      final response = await Supabase.instance.client
          .from('trip_driver_candidates')
          .select(
            'id, trip_id, driver_profile_id, status, offered_price, admin_approved, '
            'driver_profiles(id, '
            'provider_profiles(users(full_name, avatar_url)), '
            'driver_profile_photos(photo_url, sort_order), '
            'vehicles(id, brand, model, year, color, license_plate, is_active, '
            'vehicle_photos(photo_url, photo_type)))',
          )
          .eq('trip_id', tripId)
          .eq('admin_approved', true);
      if (!mounted) return;
      final candidates = (response as List)
          .map((json) => DriverCandidateModel.fromJson(json).toEntity())
          .toList();
      debugPrint('[KZ] Approved candidates fetched: ${candidates.length}');
      setState(() {
        _approvedCandidates = candidates;
        if (candidates.isNotEmpty &&
            (_step == TripFlowStep.searchingDriver ||
                (_step == TripFlowStep.idle && _searchingTripId == tripId))) {
          _step = TripFlowStep.driverSelection;
        }
      });
    } catch (e) {
      debugPrint('[KZ] Error fetching approved candidates: $e');
    }
  }

  void _subscribeToApprovedCandidates(String tripId) {
    final supabase = Supabase.instance.client;
    debugPrint('[KZ] Subscribing to candidates for tripId=$tripId');
    _candidatesChannel = supabase
        .channel('candidates-$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_driver_candidates',
          callback: (payload) {
            debugPrint(
              '[KZ] candidates event: type=${payload.eventType} '
              'new=${payload.newRecord} old=${payload.oldRecord}',
            );
            // Always refetch — the fetch query itself filters by tripId,
            // so we don't need to filter in the callback. Without
            // REPLICA IDENTITY FULL, UPDATE payloads omit unchanged
            // columns (including trip_id), making payload-level filtering
            // unreliable.
            _fetchApprovedCandidates(tripId);
          },
        )
        .subscribe((status, error) {
          debugPrint('[KZ] candidates channel status=$status err=$error');
        });
  }

  // CHANGE 4: fetch phone, avatar_url, and restore trip coordinates if missing
  Future<void> _fetchDriverNameAndStartTracking(
    String tripId,
    String driverProfileId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('driver_profiles')
          .select(
            'provider_profiles(user_id, users(full_name, phone, avatar_url))',
          )
          .eq('id', driverProfileId)
          .single();
      final fullName =
          (data['provider_profiles']?['users']?['full_name'] as String?) ??
          'Motorista';
      final userId = data['provider_profiles']?['user_id'] as String?;
      final phone = data['provider_profiles']?['users']?['phone'] as String?;
      final avatarUrl =
          data['provider_profiles']?['users']?['avatar_url'] as String?;

      // Restore pickup/dropoff coordinates and addresses from DB if missing
      // (happens when app was opened after trip was already in progress,
      //  or when _finishScheduledTripFlow was called and cleared them)
      if (_pickupLatLng == null || _destinationLatLng == null) {
        final tripData = await supabase
            .from('trips')
            .select(
              'pickup:addresses!pickup_address_id(latitude,longitude),'
              'dropoff:addresses!dropoff_address_id(latitude,longitude)',
            )
            .eq('id', tripId)
            .maybeSingle();
        if (tripData != null) {
          final pLat = (tripData['pickup']?['latitude'] as num?)?.toDouble();
          final pLng = (tripData['pickup']?['longitude'] as num?)?.toDouble();
          final dLat = (tripData['dropoff']?['latitude'] as num?)?.toDouble();
          final dLng = (tripData['dropoff']?['longitude'] as num?)?.toDouble();
          if (pLat != null && pLng != null) _pickupLatLng = LatLng(pLat, pLng);
          if (dLat != null && dLng != null)
            _destinationLatLng = LatLng(dLat, dLng);
        }
      }

      if (!mounted) return;
      _activeDriverUserId = userId;
      _activeDriverPhone = phone;
      _activeDriverAvatarUrl = avatarUrl;
      setState(() => _step = TripFlowStep.driverEnRoute);
      _startTripTracking(tripId, driverProfileId, fullName);

      // Resolve address strings for display panels if missing
      _resolveAddressesForSummary();
    } catch (e) {
      debugPrint('[KZ-C] _fetchDriverNameAndStartTracking error: $e');
    }
  }

  Future<void> _cancelSearchingTrip() async {
    await _cancelSearchingTripRequest();
    _tripChannel?.unsubscribe();
    _tripChannel = null;
    _candidatesChannel?.unsubscribe();
    _candidatesChannel = null;
    _searchingTripId = null;
    _onDetailsBack();
  }

  Future<void> _cancelSearchingTripRequest() async {
    final tripId = _searchingTripId;
    if (tripId != null) {
      try {
        await Supabase.instance.client
            .from('trips')
            .update({'status': 'cancelled'})
            .eq('id', tripId);
      } catch (e) {
        debugPrint('[KZ] Cancel trip error: $e');
      }
    }
  }

  Future<void> _returnToPassengerDetailsFromSearching() async {
    await _cancelSearchingTripRequest();
    _tripChannel?.unsubscribe();
    _tripChannel = null;
    _candidatesChannel?.unsubscribe();
    _candidatesChannel = null;
    _searchingTripId = null;
    if (!mounted) return;
    _stopSearchRadar();
    setState(() {
      _step = TripFlowStep.passengerDetails;
      _panelMinimized = false;
      _isCreatingTrip = false;
      _approvedCandidates = [];
    });
    context.read<TripCreationCubit>().reset();
  }

  void _goHomeFromScheduledSearch() {
    _searchingTimer?.cancel();
    _searchingTimer = null;
    _stopSearchRadar();
    setState(() {
      _step = TripFlowStep.idle;
      _isSearchActive = false;
      _isCreatingTrip = false;
      _panelMinimized = false;
      _polylines = {};
      _markers = {};
      _circles = {};
      _routePoints = [];
      _destinationLatLng = null;
      _pickupLatLng = null;
      _stops = [];
      _pickupPlaceId = null;
      _destinationPlaceId = null;
      _approvedCandidates = [];
      _searchingCanGoHome = false;
      _lastPassengerFormData = null;
      _outboundPassengerFormData = null;
      _returnPassengerFormData = null;
      _isEditingReturnDetails = false;
    });
    context.read<TripCreationCubit>().reset();
    _loadScheduledTrips();
    unawaited(_resetCameraToUserLocation());
  }

  void _onDetailsBack() {
    if (_isRoundTripRequest && _isEditingReturnDetails) {
      setState(() {
        _returnPassengerFormData = _lastPassengerFormData;
        _lastPassengerFormData = _outboundPassengerFormData;
        _isEditingReturnDetails = false;
        _panelMinimized = false;
      });
      return;
    }

    _stopPulseAnimation();
    _stopSearchRadar();
    _searchingTimer?.cancel();
    _confirmingTimer?.cancel();
    _driverMoveTimer?.cancel();
    _tripSummaryTimer?.cancel();
    _tripChannel?.unsubscribe();
    _tripChannel = null;
    _candidatesChannel?.unsubscribe();
    _candidatesChannel = null;
    setState(() {
      _step = TripFlowStep.idle;
      _polylines = {};
      _markers = {};
      _circles = {};
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
      _pickupPlaceId = null;
      _destinationPlaceId = null;
      _outboundPassengerFormData = null;
      _returnPassengerFormData = null;
      _isEditingReturnDetails = false;
      _isCreatingTrip = false;
      _isSearchActive = false;
      _approvedCandidates = [];
      _searchingTripId = null;
      _searchingCanGoHome = false;
      // CHANGE 13: clear phone on back
      _activeDriverPhone = null;
    });
    context.read<TripCreationCubit>().reset();
    unawaited(_resetCameraToUserLocation());
  }

  Future<void> _cancelActiveTrip() async {
    final tripId = _activeTripId ?? _searchingTripId;
    if (tripId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar corrida?'),
          content: const Text('Tem certeza que deseja cancelar esta corrida?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Voltar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Cancelar corrida'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('trips')
          .update({'status': 'cancelled'})
          .eq('id', tripId);
    } catch (e) {
      debugPrint('[KZ] Cancel active trip error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao cancelar corrida. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    _stopTripTracking();
    _resetToIdle();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Corrida cancelada.')));
  }

  void _onSearchingComplete() {
    _searchingTimer?.cancel();
    if (!mounted) return;
    setState(() => _step = TripFlowStep.driverSelection);
  }

  // CHANGE 5: call _finishScheduledTripFlow instead of snackbar
  Future<void> _onDriverAccepted(DriverCandidate candidate) async {
    _activeOfferedPrice = candidate.offeredPrice;
    _activeVehicleSummary = candidate.vehicleSummary;
    _activeVehiclePlate = candidate.vehiclePlate;
    setState(() => _step = TripFlowStep.driverSelected);
    try {
      await context.read<PendingConfirmationsCubit>().acceptCandidate(
        tripId: candidate.tripId,
        driverProfileId: candidate.driverProfileId,
        vehicleId: candidate.vehicleId,
        offeredPrice: candidate.offeredPrice,
      );
      if (!mounted) return;
      _loadScheduledTrips();
      final confirmedTripId = candidate.tripId;
      _finishScheduledTripFlow();
      _subscribeToConfirmedTrip(confirmedTripId);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _step = TripFlowStep.driverSelection);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao confirmar motorista: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onDriverConfirmed() {
    _confirmingTimer?.cancel();
    if (!mounted) return;
    setState(() => _step = TripFlowStep.driverEnRoute);
    _startFakeDriverMovement();
  }

  Future<void> _startFakeDriverMovement() async {
    if (_pickupLatLng == null) return;
    _cachedBlueDotIcon ??= await _createBlueDotIcon();
    _cachedYellowDriverDotIcon ??= await _createYellowDriverDotIcon();

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
      _driverDistanceMeters = _polylineDistanceMeters(route);
      _markers = {
        ..._markers.where(
          (m) =>
              m.markerId.value != 'fake_driver' &&
              m.markerId.value != 'client_location' &&
              m.markerId.value != 'pickup',
        ),
        Marker(
          markerId: const MarkerId('client_location'),
          position: _pickupLatLng!,
          icon: _cachedBlueDotIcon!,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 9,
        ),
        Marker(
          markerId: const MarkerId('fake_driver'),
          position: route.first,
          icon: _cachedYellowDriverDotIcon!,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 10,
        ),
      };
      _polylines = {
        ..._polylines.where(
          (p) =>
              p.polylineId.value != 'pulse_glow' &&
              p.polylineId.value != 'pulse_core' &&
              p.polylineId.value != 'driver_route' &&
              p.polylineId.value != 'route_glow' &&
              p.polylineId.value != 'route',
        ),
        Polyline(
          polylineId: const PolylineId('route'),
          points: route,
          color: AppColors.highlight,
          width: 5,
        ),
      };
    });
    _startPulseAnimation(route);

    await _fitPoints([driverStart, _pickupLatLng!, ...route], padding: 96);
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
      _driverDistanceMeters = _polylineDistanceMeters(remaining);
      _markers = {
        ..._markers.where(
          (m) =>
              m.markerId.value != 'fake_driver' &&
              m.markerId.value != 'client_location' &&
              m.markerId.value != 'pickup',
        ),
        Marker(
          markerId: const MarkerId('client_location'),
          position: _pickupLatLng!,
          icon: _cachedBlueDotIcon!,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 9,
        ),
        Marker(
          markerId: const MarkerId('fake_driver'),
          position: pos,
          icon: _cachedYellowDriverDotIcon!,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 10,
        ),
      };
      _polylines = {
        ..._polylines.where(
          (p) =>
              p.polylineId.value != 'driver_route' &&
              p.polylineId.value != 'route_glow' &&
              p.polylineId.value != 'route' &&
              p.polylineId.value != 'pulse_glow' &&
              p.polylineId.value != 'pulse_core',
        ),
        Polyline(
          polylineId: const PolylineId('route'),
          points: remaining,
          color: AppColors.highlight,
          width: 5,
        ),
      };
    });
    if (_pulseController == null) {
      _startPulseAnimation(remaining);
    } else {
      _setPulseRoutePoints(remaining);
    }
  }

  int _polylineDistanceMeters(List<LatLng> points) {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      total += Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        current.latitude,
        current.longitude,
      );
    }
    return total.round();
  }

  // CHANGE 6: driverArrived step + 8s simulate then tripStarted
  void _onDriverArrived() {
    _driverMoveTimer?.cancel();
    setState(() {
      _step = TripFlowStep.driverArrived;
      _driverEtaMinutes = 0;
      _markers = {..._markers.where((m) => m.markerId.value != 'fake_driver')};
      _polylines = {
        ..._polylines.where((p) => p.polylineId.value != 'driver_route'),
      };
    });
    _enterDriverArrivedMapView();

    // Simulate driver clicking "iniciar corrida" after 8s
    _tripSummaryTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || _step != TripFlowStep.driverArrived) return;
      setState(() => _step = TripFlowStep.tripStarted);
      _enterInTripMapView();
      _tripSummaryTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted) return;
        _resolveAddressesForSummary();
        setState(() => _step = TripFlowStep.tripSummary);
        _tripSummaryTimer = Timer(const Duration(seconds: 10), () {
          if (!mounted) return;
          setState(() => _step = TripFlowStep.tripRating);
        });
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
      final addr = await _geocodingService.reverseGeocode(_destinationLatLng!);
      if (mounted && addr != null) {
        setState(() => _destinationAddress = addr);
      }
    }
  }

  Future<void> _onRatingSubmitted(int rating, String comment) async {
    debugPrint('[KZ] Rating: $rating stars, comment: $comment');
    final supabase = Supabase.instance.client;
    final raterId = supabase.auth.currentUser?.id;
    final tripId = _activeTripId;
    final ratedId = _activeDriverUserId;
    if (raterId != null && tripId != null && ratedId != null) {
      try {
        await supabase.from('ratings').insert({
          'trip_id': tripId,
          'rater_id': raterId,
          'rated_id': ratedId,
          'rating': rating,
          'comment': comment.trim().isEmpty ? null : comment.trim(),
        });
      } catch (e) {
        debugPrint('[KZ] Failed to save rating: $e');
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obrigado pelo feedback!'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
    }
    _resetToIdle();
  }

  void _onRatingClosed() {
    _resetToIdle();
  }

  Future<void> _onReportProblem() async {
    // Número do suporte KZ no WhatsApp (sem +, formato internacional).
    const supportNumber = '5511999999999';
    final tripId = _activeTripId ?? '—';
    final driver = _activeDriverName ?? 'motorista';
    final origin = _pickupAddress ?? '—';
    final destination = _destinationAddress ?? '—';
    final message =
        'Olá, tive um problema com a corrida.\n'
        'Viagem: $tripId\n'
        'Motorista: $driver\n'
        'Origem: $origin\n'
        'Destino: $destination';
    final url = Uri.parse(
      'https://wa.me/$supportNumber?text=${Uri.encodeComponent(message)}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[KZ] Failed to open WhatsApp: $e');
    }
  }

  // CHANGE 8: clear _activeDriverPhone in _resetToIdle
  void _resetToIdle() {
    _stopPulseAnimation();
    _stopSearchRadar();
    _tripSummaryTimer?.cancel();
    _tripLocationStream?.cancel();
    _tripLocationStream = null;
    setState(() {
      _step = TripFlowStep.idle;
      _polylines = {};
      _markers = {};
      _circles = {};
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
      _pickupPlaceId = null;
      _destinationPlaceId = null;
      _outboundPassengerFormData = null;
      _returnPassengerFormData = null;
      _lastPassengerFormData = null;
      _isEditingReturnDetails = false;
      _isRoundTripRequest = false;
      _isCreatingTrip = false;
      _searchingCanGoHome = false;
      _activeDriverPhone = null;
      _activeDriverAvatarUrl = null;
      _activeOfferedPrice = null;
      _activeVehicleSummary = null;
      _activeVehiclePlate = null;
      _driverDistanceMeters = 0;
      _navHeading = 0.0;
      _tripEtaSeconds = 0;
      _tripDistanceMeters = 0;
    });
    context.read<TripCreationCubit>().reset();
    unawaited(_resetCameraToUserLocation());
  }

  // CHANGE 12: new methods before // ──── Build ────
  void _finishScheduledTripFlow() {
    _stopSearchRadar();
    _searchingTimer?.cancel();
    _confirmingTimer?.cancel();
    _driverMoveTimer?.cancel();
    _tripSummaryTimer?.cancel();
    _tripChannel?.unsubscribe();
    _tripChannel = null;
    _candidatesChannel?.unsubscribe();
    _candidatesChannel = null;
    setState(() {
      _step = TripFlowStep.idle;
      _polylines = {};
      _markers = {};
      _circles = {};
      _routePoints = [];
      _panelMinimized = false;
      // NOTE: intentionally NOT clearing _pickupLatLng, _destinationLatLng,
      // _pickupAddress, _destinationAddress — they're needed for the
      // subsequent driverEnRoute → tripStarted tracking phases.
      _stops = [];
      _selectedDriver = null;
      _driverToPickupRoute = [];
      _driverRouteIndex = 0;
      _enRoutePanelExpanded = false;
      _driverEtaMinutes = 0;
      _driverDistanceMeters = 0;
      _pickupPlaceId = null;
      _destinationPlaceId = null;
      _isCreatingTrip = false;
      _approvedCandidates = [];
      _searchingTripId = null;
      _searchingCanGoHome = false;
      _activeDriverPhone = null;
      _activeDriverAvatarUrl = null;
      _activeOfferedPrice = null;
    });
    context.read<TripCreationCubit>().reset();
    unawaited(_resetCameraToUserLocation());
  }

  void _subscribeToConfirmedTrip(String tripId) {
    _tripChannel?.unsubscribe();
    final supabase = Supabase.instance.client;
    debugPrint('[KZ-C] _subscribeToConfirmedTrip: $tripId');
    _tripChannel = supabase
        .channel('confirmed-trip-$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tripId,
          ),
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.delete) {
              _handleRemoteTripCancelled();
              return;
            }
            final status = payload.newRecord['status'] as String?;
            final driverProfileId =
                payload.newRecord['driver_profile_id'] as String?;
            debugPrint('[KZ-C] confirmed trip update: status=$status');
            if (status == 'cancelled') {
              _handleRemoteTripCancelled();
              return;
            }
            if (status == 'started' && driverProfileId != null && mounted) {
              _tripChannel?.unsubscribe();
              _tripChannel = null;
              _fetchDriverNameAndStartTracking(tripId, driverProfileId);
            }
          },
        )
        .subscribe();
  }

  Future<void> _onDriverRejected(
    DriverCandidate candidate, [
    String? reason,
  ]) async {
    try {
      await Supabase.instance.client
          .from('trip_driver_candidates')
          .update({
            'status': 'rejected',
            'responded_at': DateTime.now().toUtc().toIso8601String(),
            if (reason != null && reason.trim().isNotEmpty)
              'observations': reason.trim(),
          })
          .eq('id', candidate.candidateId);
    } catch (e) {
      debugPrint('[KZ] Failed to reject candidate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao recusar motorista. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDriverChat() async {
    final tripId = _searchingTripId ?? _activeTripId;
    if (tripId == null || _activeDriverUserId == null) return;
    final clientId = Supabase.instance.client.auth.currentUser?.id;
    if (clientId == null) return;
    try {
      final existing = await Supabase.instance.client
          .from('chat_rooms')
          .select('id')
          .eq('trip_id', tripId)
          .maybeSingle();
      final String chatRoomId;
      if (existing != null) {
        chatRoomId = existing['id'] as String;
      } else {
        final inserted = await Supabase.instance.client
            .from('chat_rooms')
            .insert({
              'trip_id': tripId,
              'client_id': clientId,
              'provider_id': _activeDriverUserId!,
            })
            .select('id')
            .single();
        chatRoomId = inserted['id'] as String;
      }
      if (mounted) context.push('/chat/$chatRoomId');
    } catch (e) {
      debugPrint('[KZ] Error opening chat: $e');
    }
  }

  Future<void> _enterDriverArrivedMapView() async {
    _stopPulseAnimation();
    setState(() {
      _polylines = _polylines
          .where(
            (p) =>
                p.polylineId.value != 'driver_route_glow' &&
                p.polylineId.value != 'driver_route',
          )
          .toSet();
    });
    if (_pickupLatLng == null) return;

    final pickupIcon = await _createYellowPinIcon();
    final userIcon = await _createBlueDotIcon();

    List<LatLng> routePoints = [];
    if (_currentLocation != null) {
      final result = await _directionsService.fetchRouteWithDuration(
        origin: _currentLocation!,
        destination: _pickupLatLng!,
      );
      routePoints = result.points;
    }
    if (!mounted) return;

    if (routePoints.isNotEmpty) {
      setState(() {
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
        _markers = {
          if (_currentLocation != null)
            Marker(
              markerId: const MarkerId('user_current'),
              position: _currentLocation!,
              icon: userIcon,
              anchor: const Offset(0.5, 0.5),
            ),
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupLatLng!,
            icon: pickupIcon,
            anchor: const Offset(0.5, 1.0),
          ),
        };
      });
      _startPulseAnimation(routePoints);
    } else {
      setState(() {
        _polylines = {};
        _markers = {
          if (_currentLocation != null)
            Marker(
              markerId: const MarkerId('user_current'),
              position: _currentLocation!,
              icon: userIcon,
              anchor: const Offset(0.5, 0.5),
            ),
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupLatLng!,
            icon: pickupIcon,
            anchor: const Offset(0.5, 1.0),
          ),
        };
      });
    }

    if (_currentLocation != null) {
      await _fitPoints(
        routePoints.isNotEmpty
            ? routePoints
            : [_currentLocation!, _pickupLatLng!],
        padding: 120,
      );
    } else {
      final controller = await _mapController.future;
      await controller.animateTo(target: _pickupLatLng!, zoom: 17);
    }
  }

  // ──── Build ────

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TripCreationCubit, TripCreationState>(
          listener: (context, state) {
            if (state is TripCreationSuccess) {
              debugPrint('[KZ] Trip created: ${state.tripId}');
              _searchingTripId = state.tripId;
              _loadScheduledTrips();
              _subscribeToTripStart(state.tripId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Viagem criada com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
              // Real trip subscription is active — do NOT start the mock
              // searching flow, as both paths would race to driverEnRoute
              // and cause duplicate Supabase channels.
              _searchingTimer?.cancel();
              _searchingTimer = null;
            } else if (state is TripCreationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() => _step = TripFlowStep.passengerDetails);
            }
          },
        ),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            _buildMap(),
            if (_step == TripFlowStep.idle && !_isSearchActive)
              _buildTopBanner(),
            if (_step == TripFlowStep.idle && !_isSearchActive)
              _buildNotificationButton(),
            _buildFakeSearchBar(),
            _buildScheduledTripsList(),
            _buildBottomNav(),
            if (_totalUnreadMessages > 0) _buildChatNotificationBubble(),
            _buildMapTapOverlay(),
            if (!_isSearchActive) _buildBottomPanel(),
            if (_step == TripFlowStep.passengerDetails ||
                _step == TripFlowStep.driverSelection ||
                _step == TripFlowStep.searchingDriver)
              _buildDetailsBackButton(),
            if (_step == TripFlowStep.confirmPickup)
              _buildConfirmPickupOverlay(),
            if (_step == TripFlowStep.pickOnMap) _buildCenterPin(),
            _buildSearchOverlay(),
            if (_step == TripFlowStep.tripStarted) _buildNavigationBanner(),
            if (_step == TripFlowStep.searchingDriver)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SearchingDriverSheet(
                  onCancel: _cancelSearchingTrip,
                  onGoHome:
                      _searchingCanGoHome &&
                          _searchingTripId != null &&
                          !_isCreatingTrip
                      ? _goHomeFromScheduledSearch
                      : null,
                ),
              ),
          ],
        ),
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
            onTap: _step == TripFlowStep.searchingDriver
                ? () => unawaited(_returnToPassengerDetailsFromSearching())
                : _onDetailsBack,
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
        child: Icon(Icons.location_on, size: 48, color: AppColors.highlight),
      ),
    );
  }

  Widget _buildChatNotificationBubble() {
    final bottom = MediaQuery.of(context).padding.bottom + 92;
    return Positioned(
      right: 18,
      bottom: bottom,
      child: PointerInterceptor(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => context.push('/messages'),
            child: Container(
              height: 56,
              padding: const EdgeInsets.only(left: 16, right: 12),
              decoration: BoxDecoration(
                color: AppColors.highlight,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Mensagem',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'QuasimodoSemiBold',
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$_totalUnreadMessages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    return KzMap(
      initialCameraPosition: _defaultCamera,
      onMapCreated: (ctrl) async {
        if (!_mapController.isCompleted) {
          _mapController.complete(ctrl);
        }
        _controller = ctrl;
      },
      onCameraIdle: () async {
        if (_step != TripFlowStep.confirmPickup || _controller == null) return;
        _resolveConfirmPickupAddress(_controller!.center);
      },
      onTap: (_) {},
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      polylines: _polylines,
      markers: {..._markers, ?_userMarker},
      circles: _circles,
      padding: EdgeInsets.zero,
    );
  }

  double _tripTopBannerHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final usableWidth = (width - 24).clamp(0.0, 760.0);
    return (usableWidth / 3.27).clamp(92.0, 164.0);
  }

  Widget _centeredTabletWidth(Widget child, {double maxWidth = 760}) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  Widget _buildTopBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: _tripTopBannerHeight(context),
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _bannerController,
                    itemCount: _bannerAssets.length,
                    onPageChanged: (index) {
                      setState(() => _currentBannerIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return Image.asset(
                        _bannerAssets[index],
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: _tripTopBannerHeight(context) + 28,
            right: 20,
          ),
          child: const TripTopBar(),
        ),
      ),
    );
  }

  Widget _buildFakeSearchBar() {
    final show = _step == TripFlowStep.idle && !_isSearchActive;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      bottom: show ? 118 : -80,
      left: 20,
      right: 20,
      child: _centeredTabletWidth(
        PointerInterceptor(
          child: GestureDetector(
            onTap: _openSearch,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.highlight,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.highlight.withValues(alpha: 0.40),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.black45),
                    const SizedBox(width: 12),
                    Text(
                      'Para onde vamos hoje?',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                  onConfirmAddresses: () => unawaited(_onConfirmAddresses()),
                  recentDestinations: _recentDestinations,
                  onRecentDestinationSelected: _onRecentDestinationSelected,
                  onSaveCurrentDestinationAs: _saveCurrentDestinationAs,
                )
              : const SizedBox.shrink(key: ValueKey('no_search')),
        ),
      ),
    );
  }

  Widget _buildScheduledTripsList() {
    final show = _step == TripFlowStep.idle && !_isSearchActive;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      bottom: show ? 190 : -240,
      left: 0,
      right: 0,
      child: BlocBuilder<ScheduledTripsCubit, ScheduledTripsState>(
        builder: (context, state) {
          if (state is! ScheduledTripsLoaded || state.trips.isEmpty) {
            return const SizedBox.shrink();
          }
          final total = state.trips.length;
          final index = _currentTripIndex.clamp(0, total - 1);
          final trip = state.trips[index];
          return PointerInterceptor(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v.abs() < 80) return;
                if (v < 0) {
                  _goToNextTrip(total);
                } else {
                  _goToPrevTrip(total);
                }
              },
              child: _centeredTabletWidth(
                SizedBox(
                  height: 185,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ScheduledTripCard(
                      key: ValueKey(index),
                      trip: trip,
                      onTap: () => TripDetailsSheet.show(context, trip),
                      onPrevTap: () => _goToPrevTrip(total),
                      onNextTap: () => _goToNextTrip(total),
                      currentIndex: index,
                      totalCount: total,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: PointerInterceptor(
        child: _centeredTabletWidth(
          AnimatedSwitcher(
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
            initialData: _lastPassengerFormData,
            isRoundTrip: _isRoundTripRequest,
          ),
        );
      case TripFlowStep.searchingDriver:
        return const SizedBox.shrink(key: ValueKey('searching'));
      // CHANGE 10: pass onDriverRejected
      case TripFlowStep.driverSelection:
        return DriverSelectionPanel(
          key: const ValueKey('driverSelection'),
          candidates: _approvedCandidates,
          onDriverAccepted: _onDriverAccepted,
          onDriverRejected: _onDriverRejected,
        );
      case TripFlowStep.driverSelected:
        return const SizedBox.shrink(key: ValueKey('driverSelected'));
      case TripFlowStep.driverConfirming:
        return _selectedDriver != null
            ? DriverConfirmingPanel(
                key: const ValueKey('driverConfirming'),
                driver: _selectedDriver!,
              )
            : const SizedBox.shrink(key: ValueKey('none'));
      // CHANGE 11: pass driverPhone + onOpenChat, fix etaMinutes in realtime path
      case TripFlowStep.driverEnRoute:
        if (_selectedDriver != null) {
          return DriverEnRoutePanel(
            key: const ValueKey('driverEnRoute'),
            driver: _selectedDriver!,
            etaMinutes: _driverEtaMinutes,
            distanceMeters: _driverDistanceMeters,
            isExpanded: _enRoutePanelExpanded,
            driverPhone: _activeDriverPhone,
            driverAvatarUrl: _activeDriverAvatarUrl,
            onOpenChat: _openDriverChat,
            onCancel: _cancelActiveTrip,
            onToggleExpand: () =>
                setState(() => _enRoutePanelExpanded = !_enRoutePanelExpanded),
          );
        }
        // Realtime path — show driver en route with real driver data
        final driverName = _activeDriverName ?? 'Motorista';
        final driverInitials = driverName
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join()
            .toUpperCase();
        return DriverEnRoutePanel(
          key: const ValueKey('driverEnRoute'),
          driver: MockDriver(
            id: 'realtime_driver',
            name: driverName,
            initials: driverInitials,
            carModel: _activeVehicleSummary ?? '',
            carColor: '',
            licensePlate: _activeVehiclePlate ?? '',
            rating: 0.0,
            description: '',
            rg: '',
            birthDate: DateTime.now(),
            extras: [],
          ),
          etaMinutes: _driverEtaMinutes,
          distanceMeters: _driverDistanceMeters,
          isExpanded: _enRoutePanelExpanded,
          driverPhone: _activeDriverPhone,
          driverAvatarUrl: _activeDriverAvatarUrl,
          onOpenChat: _openDriverChat,
          onCancel: _cancelActiveTrip,
          onToggleExpand: () =>
              setState(() => _enRoutePanelExpanded = !_enRoutePanelExpanded),
        );
      case TripFlowStep.driverArrived:
        return DriverArrivedSheet(
          key: const ValueKey('driverArrived'),
          driverName: _activeDriverName ?? 'Motorista',
          pickupAddress: _pickupAddress,
          destinationAddress: _destinationAddress,
          driverPhone: _activeDriverPhone,
          driverAvatarUrl: _activeDriverAvatarUrl,
          onOpenChat: _openDriverChat,
        );
      case TripFlowStep.tripStarted:
        return KeyedSubtree(
          key: const ValueKey('tripStarted'),
          child: _buildInTripInfoStrip(),
        );
      case TripFlowStep.tripSummary:
        return TripSummaryPanel(
          key: const ValueKey('tripSummary'),
          pickupAddress: _pickupAddress ?? 'Carregando...',
          destinationAddress: _destinationAddress ?? 'Carregando...',
          paymentMethod: 'À vista (PIX)',
        );
      case TripFlowStep.tripRating:
        return TripRatingPanel(
          key: const ValueKey('tripRating'),
          driverName: _activeDriverName ?? _selectedDriver?.name ?? 'Motorista',
          driverAvatarUrl: _activeDriverAvatarUrl,
          onClose: _onRatingClosed,
          onSubmit: _onRatingSubmitted,
          onReportProblem: _onReportProblem,
        );
      default:
        return const SizedBox.shrink(key: ValueKey('none'));
    }
  }

  Widget _buildNavigationBanner() {
    final etaMin = _tripEtaSeconds > 0
        ? ((_tripEtaSeconds / 60).ceil()).clamp(1, 999)
        : null;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.highlight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.highlight.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Em viagem',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (etaMin != null)
                        Text(
                          'Chegada estimada: $etaMin min',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInTripInfoStrip() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final driverName = _activeDriverName ?? 'Motorista';
    final firstName = driverName.split(' ').first;
    final initials = driverName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.highlight,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _destinationAddress ?? 'Destino',
                  style: const TextStyle(
                    fontFamily: 'QuasimodoSemiBold',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_activeOfferedPrice != null) ...[
                const SizedBox(width: 12),
                Text(
                  'R\$ ${_activeOfferedPrice!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ],
            ],
          ),
          if (_tripEtaSeconds > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${((_tripEtaSeconds / 60).ceil()).clamp(1, 999)} min',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_tripDistanceMeters > 0) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.route_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _tripDistanceMeters >= 1000
                        ? '${(_tripDistanceMeters / 1000).toStringAsFixed(1)} km'
                        : '$_tripDistanceMeters m',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildInTripDriverAvatar(44, initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName,
                      style: const TextStyle(
                        fontFamily: 'QuasimodoSemiBold',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Em corrida',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_activeDriverPhone != null)
                    _buildInTripIconButton(
                      Icons.phone_rounded,
                      const Color(0xFF22C55E),
                      () async {
                        final uri = Uri.parse('tel:$_activeDriverPhone');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                    ),
                  if (_activeDriverPhone != null) const SizedBox(width: 8),
                  _buildInTripIconButton(
                    Icons.chat_rounded,
                    AppColors.highlight,
                    _openDriverChat,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInTripDriverAvatar(double size, String initials) {
    final avatarUrl = _activeDriverAvatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppColors.highlight.withValues(alpha: 0.15),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.highlight.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.37,
            fontWeight: FontWeight.w700,
            color: AppColors.highlight,
          ),
        ),
      ),
    );
  }

  Widget _buildInTripIconButton(
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
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

  // CHANGE 9: wrap TripBottomNav in BlocBuilder for scheduledCount
  Widget _buildBottomNav() {
    final show = _step == TripFlowStep.idle && !_isSearchActive;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      bottom: show ? 24 : -120,
      left: 20,
      right: 20,
      child: _centeredTabletWidth(
        BlocBuilder<ScheduledTripsCubit, ScheduledTripsState>(
          builder: (context, state) {
            final count = state is ScheduledTripsLoaded
                ? state.trips.length
                : 0;
            return TripBottomNav(
              selectedIndex: _selectedNavIndex,
              scheduledCount: count,
              onItemSelected: (index) {
                if (index == 1) {
                  context.go('/scheduled-trips');
                  return;
                }
                if (index == 2) {
                  context.go('/services');
                  return;
                }
                if (index == 3) {
                  context.go('/profile');
                  return;
                }
                setState(() => _selectedNavIndex = index);
              },
            );
          },
        ),
      ),
    );
  }
}

class _TripTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TripTypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.highlight.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.highlight, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
