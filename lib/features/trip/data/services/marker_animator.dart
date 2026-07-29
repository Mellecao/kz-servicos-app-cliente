import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef MarkerTick = void Function(LatLng position, double bearing);

/// Animates a marker's position and bearing between updates.
///
/// - Linear interpolation of latitude/longitude.
/// - Shortest-path interpolation of bearing (handles wrap-around at 360°).
/// - Calling [animateTo] mid-animation restarts from the current interpolated
///   position instead of snapping back to the original start.
/// - Emits ticks via [onTick] on every animation frame (~60fps).
class MarkerAnimator {
  MarkerAnimator({
    required TickerProvider vsync,
    Duration duration = const Duration(seconds: 5),
  })  : _duration = duration,
        _controller = AnimationController(vsync: vsync, duration: duration);

  final Duration _duration;
  final AnimationController _controller;

  LatLng? _startPos;
  LatLng? _targetPos;
  double _startBearing = 0;
  double _targetBearing = 0;
  double _bearingDelta = 0; // shortest-path delta
  MarkerTick? _onTick;
  bool _disposed = false;

  /// Current interpolated position (or last target). Null before first call.
  LatLng? get currentPosition {
    if (_startPos == null || _targetPos == null) return null;
    final t = _controller.value;
    return LatLng(
      _lerp(_startPos!.latitude, _targetPos!.latitude, t),
      _lerp(_startPos!.longitude, _targetPos!.longitude, t),
    );
  }

  /// Current interpolated bearing (normalized 0..360).
  double get currentBearing {
    final t = _controller.value;
    return _normalize(_startBearing + _bearingDelta * t);
  }

  /// Animates from the current interpolated position/bearing (or from
  /// [start]/[startBearing] on first call) to [target]/[bearing].
  ///
  /// If called mid-animation, cancels and restarts from the current
  /// interpolated state (no snap-back).
  void animateTo({
    required LatLng target,
    required double bearing,
    required MarkerTick onTick,
    LatLng? start,
    double? startBearing,
  }) {
    if (_disposed) return;

    // If we have a running interpolation, capture its current interpolated
    // values as the new start; otherwise use provided start (or the last
    // target, or (0,0) as ultimate fallback).
    final effectiveStart = start ??
        currentPosition ??
        _targetPos ??
        const LatLng(0, 0);
    final effectiveStartBearing = startBearing ??
        (_startPos == null ? 0.0 : currentBearing);

    _controller.stop();
    _startPos = effectiveStart;
    _targetPos = target;
    _startBearing = effectiveStartBearing;
    _targetBearing = _normalize(bearing);
    _bearingDelta = _shortestBearingDelta(effectiveStartBearing, _targetBearing);
    _onTick = onTick;

    _controller
      ..removeListener(_emitTick)
      ..addListener(_emitTick)
      ..value = 0.0;

    // Driving the controller forward requires an initialized binding
    // (SchedulerBinding). In unit tests without WidgetsFlutterBinding
    // initialized, callers drive progress via [debugTickAtProgress] instead,
    // so a missing binding is expected and safely ignored.
    if (_isBindingInitialized()) {
      _controller.animateTo(1.0, duration: _duration);
    }
  }

  static bool _isBindingInitialized() {
    try {
      // ignore: unnecessary_statements
      SchedulerBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _emitTick() {
    final pos = currentPosition;
    if (pos != null) _onTick?.call(pos, currentBearing);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _normalize(double d) {
    var v = d % 360;
    if (v < 0) v += 360;
    return v;
  }

  /// Shortest signed delta between two bearings.
  /// e.g. 350 -> 10 returns +20 (not -340).
  static double _shortestBearingDelta(double from, double to) {
    final diff = ((to - from) % 360 + 540) % 360 - 180;
    return diff;
  }

  /// Test-only: drive the animation directly to a given progress in [0..1].
  /// Not intended for production use.
  void debugTickAtProgress(double progress) {
    _controller.value = progress.clamp(0.0, 1.0);
    _emitTick();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _controller.removeListener(_emitTick);
    _controller.dispose();
  }
}
