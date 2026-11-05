import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';

/// Pin de prestador no mapa: gota laranja da marca com o ícone da categoria.
abstract final class ProviderPinIcon {
  /// Tamanho lógico do pin no mapa.
  static const double width = 52;
  static const double height = 64;
  static const double _scale = 3;

  static final Map<int, BitmapDescriptor> _cache = {};
  static BitmapDescriptor? _userDot;

  /// Ponto azul da posição do cliente (círculo azul com contorno branco).
  static Future<BitmapDescriptor> userDot() async {
    final cached = _userDot;
    if (cached != null) return cached;
    const size = 24.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_scale);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      11,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      8,
      Paint()..color = const Color(0xFF4285F4),
    );
    final image = await recorder.endRecording().toImage(
      (size * _scale).round(),
      (size * _scale).round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return _userDot = BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: size,
    );
  }

  static Future<BitmapDescriptor> forCategory(ServiceCategory category) async {
    final key = category.icon.codePoint;
    final cached = _cache[key];
    if (cached != null) return cached;
    final bytes = await renderPng(category.icon);
    final descriptor = BitmapDescriptor.bytes(bytes, width: width);
    _cache[key] = descriptor;
    return descriptor;
  }

  /// Desenha o pin (gota + ícone) como PNG, a [_scale]× o tamanho lógico.
  static Future<Uint8List> renderPng(IconData icon) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_scale);

    // Sombra no chão.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(width / 2, height - 3),
        width: 16,
        height: 5,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // Ponta da gota (contorno branco por baixo, laranja por cima).
    final tip = Path()
      ..moveTo(width / 2 - 10, 40)
      ..lineTo(width / 2, height - 5)
      ..lineTo(width / 2 + 10, 40)
      ..close();
    canvas.drawPath(tip, Paint()..color = Colors.white);
    final tipInner = Path()
      ..moveTo(width / 2 - 7, 41)
      ..lineTo(width / 2, height - 9)
      ..lineTo(width / 2 + 7, 41)
      ..close();
    canvas.drawPath(tipInner, Paint()..color = AppColors.highlight);

    // Cabeça: anel branco e miolo laranja.
    const headCenter = Offset(width / 2, 25);
    canvas.drawCircle(headCenter, 24, Paint()..color = Colors.white);
    canvas.drawCircle(headCenter, 20.5, Paint()..color = AppColors.highlight);

    // Ícone da categoria, centrado na cabeça.
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 26,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: AppColors.onPrimary,
        ),
      ),
    )..layout();
    painter.paint(
      canvas,
      headCenter - Offset(painter.width / 2, painter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (width * _scale).round(),
      (height * _scale).round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
