import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/routes/app_router.dart';

void main() {
  runApp(const KzServicosApp());
}

class KzServicosApp extends StatelessWidget {
  const KzServicosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KZ Serviços',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
