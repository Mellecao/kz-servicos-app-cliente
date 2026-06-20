import 'package:flutter/widgets.dart';

/// Provides responsive dimension values based on screen width.
/// Tablet breakpoint: >= 600 logical pixels.
class AppDimensions {
  static const double _tabletBreakpoint = 600;

  // ── Typography ──────────────────────────────────────────────────
  final double fontSmall;
  final double fontBody;
  final double fontTitle;
  final double fontHeading;
  final double fontLargeHeading;

  // ── Icons ────────────────────────────────────────────────────────
  final double iconSm;
  final double icon;
  final double iconLg;

  // ── Spacing & padding ────────────────────────────────────────────
  final double paddingH;
  final double paddingV;
  final double paddingCard;
  final double gapSm;
  final double gapMd;
  final double gapLg;

  // ── Components ───────────────────────────────────────────────────
  final double navItemSize;
  final double navItemUnselectedSize;
  final double avatarRadius;
  final double buttonHeight;
  final double mapPreviewHeight;
  final double iconContainerSm;
  final double iconContainerMd;
  final double cardRadius;
  final double topBarButtonSize;

  const AppDimensions._({
    required this.fontSmall,
    required this.fontBody,
    required this.fontTitle,
    required this.fontHeading,
    required this.fontLargeHeading,
    required this.iconSm,
    required this.icon,
    required this.iconLg,
    required this.paddingH,
    required this.paddingV,
    required this.paddingCard,
    required this.gapSm,
    required this.gapMd,
    required this.gapLg,
    required this.navItemSize,
    required this.navItemUnselectedSize,
    required this.avatarRadius,
    required this.buttonHeight,
    required this.mapPreviewHeight,
    required this.iconContainerSm,
    required this.iconContainerMd,
    required this.cardRadius,
    required this.topBarButtonSize,
  });

  static AppDimensions of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= _tabletBreakpoint ? _tablet : _phone;
  }

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _tabletBreakpoint;

  // ── Phone ────────────────────────────────────────────────────────
  static const AppDimensions _phone = AppDimensions._(
    fontSmall: 12,
    fontBody: 13,
    fontTitle: 15,
    fontHeading: 20,
    fontLargeHeading: 22,
    iconSm: 16,
    icon: 22,
    iconLg: 28,
    paddingH: 20,
    paddingV: 16,
    paddingCard: 14,
    gapSm: 4,
    gapMd: 12,
    gapLg: 20,
    navItemSize: 56,
    navItemUnselectedSize: 44,
    avatarRadius: 45,
    buttonHeight: 56,
    mapPreviewHeight: 130,
    iconContainerSm: 36,
    iconContainerMd: 44,
    cardRadius: 16,
    topBarButtonSize: 48,
  );

  // ── Tablet ───────────────────────────────────────────────────────
  static const AppDimensions _tablet = AppDimensions._(
    fontSmall: 15,
    fontBody: 16,
    fontTitle: 19,
    fontHeading: 26,
    fontLargeHeading: 30,
    iconSm: 20,
    icon: 28,
    iconLg: 36,
    paddingH: 32,
    paddingV: 24,
    paddingCard: 20,
    gapSm: 6,
    gapMd: 16,
    gapLg: 28,
    navItemSize: 70,
    navItemUnselectedSize: 56,
    avatarRadius: 60,
    buttonHeight: 72,
    mapPreviewHeight: 190,
    iconContainerSm: 48,
    iconContainerMd: 58,
    cardRadius: 20,
    topBarButtonSize: 62,
  );
}
