import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Idioma da app: português de Angola.
///
/// O `intl` (0.20.x) não tem `pt_AO` (só `pt`, `pt_BR` e `pt_PT`) e o `pt`
/// simples é o do Brasil, por isso usa-se `pt_PT` (norma europeia/angolana).
abstract final class AppLocale {
  static const Locale locale = Locale('pt', 'PT');

  static const List<Locale> supported = [locale];

  static const List<LocalizationsDelegate<dynamic>> delegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
