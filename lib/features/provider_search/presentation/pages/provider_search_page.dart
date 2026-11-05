import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/constants/app_maps.dart';
import 'package:kz_servicos_app/core/maps/kz_map.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_categories_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_categories_state.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_requests_list_cubit.dart';
import 'package:kz_servicos_app/features/provider_search/data/models/provider_search_result.dart';
import 'package:kz_servicos_app/features/provider_search/data/repositories/provider_search_repository.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/cubit/provider_search_cubit.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/cubit/provider_search_state.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/widgets/provider_details_sheet.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/widgets/provider_pin_icon.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/widgets/search_radar.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/widgets/service_search_bar.dart';

/// "Buscar prestadores de serviço": mapa + campo com autocomplete de
/// categorias. Ao escolher uma categoria, o radar procura e os prestadores
/// surgem como pins; tocar num pin abre o modal com os dados e o pedido.
///
/// É a primeira tela do Cliente com `trips_enabled=false`; com `true` fica
/// acessível por `/provider-search` ([showBackButton]).
class ProviderSearchPage extends StatelessWidget {
  const ProviderSearchPage({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProviderSearchCubit(
        repository: context.read<ProviderSearchRepository>(),
      ),
      child: _ProviderSearchView(showBackButton: showBackButton),
    );
  }
}

class _ProviderSearchView extends StatefulWidget {
  const _ProviderSearchView({required this.showBackButton});

  final bool showBackButton;

  @override
  State<_ProviderSearchView> createState() => _ProviderSearchViewState();
}

class _ProviderSearchViewState extends State<_ProviderSearchView> {
  /// Raio (m) da área de busca desenhada à volta do cliente. O servidor coloca
  /// os prestadores entre 250 e 1900 m.
  static const double _searchAreaRadius = 1950;

  final Completer<KzMapController> _mapController = Completer();

  LatLng _origin = AppMaps.defaultCenter;
  Future<void>? _locating;
  Marker? _userMarker;

  Set<Marker> _providerMarkers = {};
  Set<Circle> _ripples = {};
  Timer? _revealTimer;
  int _revealGeneration = 0;

  @override
  void initState() {
    super.initState();
    final categories = context.read<ServiceCategoriesCubit>();
    if (categories.state is! ServiceCategoriesLoaded) {
      categories.loadCategories();
    }
    _locating = _locate();
  }

  @override
  void dispose() {
    _revealGeneration++;
    _revealTimer?.cancel();
    super.dispose();
  }

  // ── Localização ──────────────────────────────────────────────────────────

  /// Pede permissão e usa a posição do dispositivo; sem permissão ou sem sinal
  /// fica o centro de Luanda ([AppMaps.defaultCenter]).
  Future<void> _locate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      final dot = await ProviderPinIcon.userDot();
      if (!mounted) return;
      setState(() {
        _origin = latLng;
        _userMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: latLng,
          icon: dot,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 5,
        );
      });
      await _moveCamera(latLng, 15);
    } catch (_) {
      // Mantém o centro de Luanda.
    }
  }

  Future<void> _moveCamera(LatLng target, double zoom) async {
    try {
      final controller = await _mapController.future;
      await controller.animateTo(target: target, zoom: zoom);
    } catch (_) {}
  }

  // ── Pesquisa ─────────────────────────────────────────────────────────────

  Future<void> _search(ServiceCategory category) async {
    FocusManager.instance.primaryFocus?.unfocus();
    _clearProviders();
    // A procura usa a posição do cliente; se ainda a estamos a obter, espera.
    await _locating;
    if (!mounted) return;
    unawaited(_moveCamera(_origin, 14.3));
    await context.read<ProviderSearchCubit>().search(
      category,
      lat: _origin.latitude,
      lng: _origin.longitude,
    );
  }

  void _onCleared() {
    context.read<ProviderSearchCubit>().reset();
    _clearProviders();
    unawaited(_moveCamera(_origin, 15));
  }

  void _clearProviders() {
    _revealGeneration++;
    _revealTimer?.cancel();
    if (_providerMarkers.isEmpty && _ripples.isEmpty) return;
    setState(() {
      _providerMarkers = {};
      _ripples = {};
    });
  }

  void _onSearchState(BuildContext context, ProviderSearchState state) {
    switch (state) {
      case ProviderSearchResults():
        unawaited(_revealProviders(state));
      case ProviderSearchSearching() ||
          ProviderSearchFailure() ||
          ProviderSearchIdle():
        _clearProviders();
    }
  }

  /// Faz os pins surgirem um a um (com uma onda a cada entrada) e, no fim,
  /// enquadra a câmara em todos.
  Future<void> _revealProviders(ProviderSearchResults results) async {
    final generation = ++_revealGeneration;
    _revealTimer?.cancel();
    final icon = await ProviderPinIcon.forCategory(results.category);
    if (!mounted || generation != _revealGeneration) return;

    var next = 0;
    _revealTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted || generation != _revealGeneration) {
        timer.cancel();
        return;
      }
      if (next >= results.providers.length) {
        timer.cancel();
        unawaited(_fitAll(results.providers));
        return;
      }
      final provider = results.providers[next++];
      final rippleId = CircleId('ripple-${provider.providerProfileId}');
      setState(() {
        _providerMarkers = {
          ..._providerMarkers,
          Marker(
            markerId: MarkerId(provider.providerProfileId),
            position: LatLng(provider.lat, provider.lng),
            icon: icon,
            anchor: const Offset(0.5, 0.92),
            zIndexInt: 10,
            onTap: () => _openProvider(provider, results.category),
          ),
        };
        _ripples = {
          ..._ripples,
          Circle(
            circleId: rippleId,
            center: LatLng(provider.lat, provider.lng),
            radius: 140,
            fillColor: AppColors.highlight.withValues(alpha: 0.30),
            strokeColor: AppColors.highlight,
            strokeWidth: 2,
          ),
        };
      });
      Timer(const Duration(milliseconds: 700), () {
        if (!mounted || generation != _revealGeneration) return;
        setState(() {
          _ripples = _ripples.where((c) => c.circleId != rippleId).toSet();
        });
      });
    });
  }

  Future<void> _fitAll(List<ProviderSearchResult> providers) async {
    if (providers.isEmpty) return;
    var south = _origin.latitude;
    var north = _origin.latitude;
    var west = _origin.longitude;
    var east = _origin.longitude;
    for (final p in providers) {
      south = math.min(south, p.lat);
      north = math.max(north, p.lat);
      west = math.min(west, p.lng);
      east = math.max(east, p.lng);
    }
    try {
      final controller = await _mapController.future;
      await controller.fitBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        padding: 120,
        maxZoom: 16,
      );
    } catch (_) {}
  }

  // ── Modal do prestador ───────────────────────────────────────────────────

  Future<void> _openProvider(
    ProviderSearchResult provider,
    ServiceCategory category,
  ) {
    final cubit = context.read<ProviderSearchCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ProviderDetailsSheet(
        provider: provider,
        category: category,
        onRequest: (description) async {
          final id = await cubit.requestService(
            provider: provider,
            description: description,
          );
          // O novo pedido tem de aparecer já em "Serviços" / "Os meus pedidos".
          if (mounted) context.read<ServiceRequestsListCubit>().load();
          return id;
        },
        onViewRequest: (id) {
          Navigator.of(sheetContext).pop();
          if (mounted) context.push('/services/requests/$id');
        },
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: BlocConsumer<ProviderSearchCubit, ProviderSearchState>(
          listener: _onSearchState,
          builder: (context, state) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildMap(state),
                if (state is ProviderSearchSearching) const SearchRadar(),
                _buildTopBar(),
                _buildStatus(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(ProviderSearchState state) {
    final showArea = state is! ProviderSearchIdle;
    return KzMap(
      initialCameraPosition: CameraPosition(target: _origin, zoom: 15),
      onMapCreated: (controller) {
        if (!_mapController.isCompleted) _mapController.complete(controller);
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      tiltGesturesEnabled: false,
      markers: {..._providerMarkers, ?_userMarker},
      circles: {
        if (showArea)
          Circle(
            circleId: const CircleId('search_area'),
            center: _origin,
            radius: _searchAreaRadius,
            fillColor: AppColors.highlight.withValues(alpha: 0.07),
            strokeColor: AppColors.highlight.withValues(alpha: 0.45),
            strokeWidth: 1,
          ),
        ..._ripples,
      },
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showBackButton) ...[
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.pop(),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child:
                    BlocBuilder<ServiceCategoriesCubit, ServiceCategoriesState>(
                      builder: (context, categories) => ServiceSearchBar(
                        categories: categories is ServiceCategoriesLoaded
                            ? categories.categories
                            : const [],
                        onSelected: _search,
                        onCleared: _onCleared,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cartão por cima do menu inferior: dica inicial, contagem, vazio ou erro.
  Widget _buildStatus(ProviderSearchState state) {
    final content = switch (state) {
      ProviderSearchIdle() => const _StatusCard(
        icon: Icons.touch_app_rounded,
        title: 'Que serviço procura?',
        message:
            'Escreva o serviço, por exemplo "canalizador", e veja os '
            'profissionais perto de si.',
      ),
      ProviderSearchSearching() => null,
      ProviderSearchResults(:final category, :final providers)
          when providers.isEmpty =>
        _StatusCard(
          icon: Icons.search_off_rounded,
          title: 'Sem prestadores por perto',
          message:
              'Ainda não há prestadores de ${category.name.toLowerCase()} '
              'perto de si. Experimente outro serviço.',
        ),
      ProviderSearchResults(:final providers) => _StatusCard(
        icon: Icons.location_on_rounded,
        title: providers.length == 1
            ? '1 prestador perto de si'
            : '${providers.length} prestadores perto de si',
        message: 'Toque num pin para ver o preço e pedir o serviço.',
      ),
      ProviderSearchFailure(:final category, :final message) => _StatusCard(
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível procurar',
        message: message,
        actionLabel: 'Tentar novamente',
        onAction: () => _search(category),
      ),
    };
    return Positioned(
      left: 20,
      right: 20,
      bottom: 124,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: content ?? const SizedBox.shrink(),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('status-$title'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandDark.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.highlight.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.highlight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.sheetTextSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: AppColors.highlight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
