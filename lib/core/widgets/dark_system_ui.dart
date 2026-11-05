import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Para ecrãs de fundo escuro: ícones claros na barra de estado.
/// Sem isto o tema claro do Flutter desenha hora/bateria em escuro sobre escuro.
class DarkSystemUi extends StatelessWidget {
  const DarkSystemUi({super.key, required this.child});

  final Widget child;

  static const SystemUiOverlayStyle style = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Android
    statusBarBrightness: Brightness.dark, // iOS
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(value: style, child: child);
  }
}
