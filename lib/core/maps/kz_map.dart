import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

class KzMapController {
  final gm.GoogleMapController _googleController;
  gm.LatLng _center;
  double _zoom;

  KzMapController._(
    this._googleController, {
    required gm.LatLng center,
    required double zoom,
  }) : _center = center,
       _zoom = zoom;

  gm.LatLng get center => _center;

  void _updateCamera(gm.LatLng center, double zoom) {
    _center = center;
    _zoom = zoom;
  }

  Future<void> animateTo({
    required gm.LatLng target,
    required double zoom,
    double bearing = 0,
    double tilt = 0,
  }) async {
    _updateCamera(target, zoom);
    await _googleController.animateCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: target,
          zoom: zoom,
          bearing: bearing,
          tilt: tilt,
        ),
      ),
    );
  }

  Future<void> fitBounds(
    gm.LatLngBounds bounds, {
    double padding = 80,
    double maxZoom = 16,
  }) async {
    final center = _boundsCenter(bounds);
    _updateCamera(center, _zoom);
    await _googleController.animateCamera(
      gm.CameraUpdate.newLatLngBounds(bounds, padding),
    );
    final fittedZoom = await _googleController.getZoomLevel();
    if (fittedZoom > maxZoom) {
      await animateTo(target: center, zoom: maxZoom);
      return;
    }
    _updateCamera(center, fittedZoom);
  }

  Future<void> scrollBy(double dx, double dy) async {
    await _googleController.animateCamera(gm.CameraUpdate.scrollBy(dx, dy));
  }
}

class KzMap extends StatefulWidget {
  final gm.CameraPosition initialCameraPosition;
  final Set<gm.Marker> markers;
  final Set<gm.Polyline> polylines;
  final Set<gm.Circle> circles;
  final ValueChanged<KzMapController>? onMapCreated;
  final ValueChanged<gm.LatLng>? onTap;
  final VoidCallback? onCameraIdle;
  final bool zoomControlsEnabled;
  final bool scrollGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool mapToolbarEnabled;
  final bool compassEnabled;
  final bool liteModeEnabled;
  final EdgeInsets padding;
  final String? style;

  const KzMap({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.polylines = const {},
    this.circles = const {},
    this.onMapCreated,
    this.onTap,
    this.onCameraIdle,
    this.zoomControlsEnabled = true,
    this.scrollGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.mapToolbarEnabled = true,
    this.compassEnabled = true,
    this.liteModeEnabled = false,
    this.padding = EdgeInsets.zero,
    this.style,
  });

  @override
  State<KzMap> createState() => _KzMapState();
}

class _KzMapState extends State<KzMap> {
  KzMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return gm.GoogleMap(
      initialCameraPosition: widget.initialCameraPosition,
      markers: widget.markers,
      polylines: widget.polylines,
      circles: widget.circles,
      onMapCreated: (controller) {
        final kzController = KzMapController._(
          controller,
          center: widget.initialCameraPosition.target,
          zoom: widget.initialCameraPosition.zoom,
        );
        _controller = kzController;
        widget.onMapCreated?.call(kzController);
      },
      onCameraMove: (position) {
        _controller?._updateCamera(position.target, position.zoom);
      },
      onCameraIdle: widget.onCameraIdle,
      onTap: widget.onTap,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
      tiltGesturesEnabled: widget.tiltGesturesEnabled,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      mapToolbarEnabled: widget.mapToolbarEnabled,
      compassEnabled: widget.compassEnabled,
      liteModeEnabled: widget.liteModeEnabled,
      padding: widget.padding,
      style: widget.style,
    );
  }
}

gm.LatLng _boundsCenter(gm.LatLngBounds bounds) {
  return gm.LatLng(
    (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
    (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
  );
}
