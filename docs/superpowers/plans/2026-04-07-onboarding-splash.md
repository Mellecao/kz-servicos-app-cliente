# Onboarding + Login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar projeto Flutter com tela de onboarding (3 slides com transição de cor) e tela de login genérica.

**Architecture:** Projeto Flutter com Clean Architecture. Onboarding usa PageView com interpolação de cor de fundo baseada na posição do scroll. GoRouter para navegação entre onboarding e login.

**Tech Stack:** Flutter, Dart, GoRouter, Google Fonts (local fonts via pubspec)

---

## File Structure

| File | Responsibility |
|------|----------------|
| `lib/core/constants/app_colors.dart` | Constantes de cores do app |
| `lib/core/theme/app_theme.dart` | ThemeData com fontes customizadas |
| `lib/features/onboarding/presentation/pages/onboarding_page.dart` | Página principal do onboarding com PageView e animação de cor |
| `lib/features/onboarding/presentation/widgets/onboarding_slide.dart` | Widget individual de cada slide |
| `lib/features/onboarding/presentation/widgets/onboarding_dots.dart` | Indicadores de ponto (dots) |
| `lib/features/auth/presentation/pages/login_page.dart` | Tela de login genérica |
| `lib/routes/app_router.dart` | Configuração de rotas GoRouter |
| `lib/main.dart` | Entry point do app |
| `test/core/constants/app_colors_test.dart` | Testes das constantes de cor |
| `test/features/onboarding/presentation/pages/onboarding_page_test.dart` | Testes do onboarding |
| `test/features/onboarding/presentation/widgets/onboarding_slide_test.dart` | Testes do slide |
| `test/features/onboarding/presentation/widgets/onboarding_dots_test.dart` | Testes dos dots |
| `test/features/auth/presentation/pages/login_page_test.dart` | Testes da tela de login |
| `test/routes/app_router_test.dart` | Testes de rotas |

---

### Task 0: Criar projeto Flutter e configurar dependências

**Files:**
- Create: projeto Flutter na raiz do repo
- Modify: `pubspec.yaml` (fonts + dependências)

- [ ] **Step 1: Criar projeto Flutter**

```bash
cd c:\Users\v27me\Videos\kz-servicos-app-cliente
flutter create . --org com.kzservicos --project-name kz_servicos_app
```

- [ ] **Step 2: Copiar assets para estrutura Flutter**

Mover logo e fontes para `assets/` na raiz do projeto Flutter:

```bash
mkdir -p assets/images assets/fonts
cp "public/assets/LOGO COLORIDA PNG.png" assets/images/logo.png
cp public/assets/fonts/OUTFIT-BLACK.TTF assets/fonts/
cp public/assets/fonts/Quasimoda-SemiBold.ttf assets/fonts/
```

- [ ] **Step 3: Configurar pubspec.yaml**

Adicionar ao `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^15.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/images/

  fonts:
    - family: OutfitBlack
      fonts:
        - asset: assets/fonts/OUTFIT-BLACK.TTF
    - family: QuasimodoSemiBold
      fonts:
        - asset: assets/fonts/Quasimoda-SemiBold.ttf
```

- [ ] **Step 4: Verificar que o projeto compila**

```bash
flutter pub get
flutter analyze
```

Expected: sem erros

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: init Flutter project with fonts and assets"
```

---

### Task 1: Constantes de cores

**Files:**
- Create: `lib/core/constants/app_colors.dart`
- Test: `test/core/constants/app_colors_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/constants/app_colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

void main() {
  group('AppColors', () {
    test('background should be #F1F0F0', () {
      expect(AppColors.background, const Color(0xFFF1F0F0));
    });

    test('highlight should be #FEBF22', () {
      expect(AppColors.highlight, const Color(0xFFFEBF22));
    });

    test('secondary should be #2261FE', () {
      expect(AppColors.secondary, const Color(0xFF2261FE));
    });

    test('textPrimary should be #5C5956', () {
      expect(AppColors.textPrimary, const Color(0xFF5C5956));
    });

    test('white should be Colors.white', () {
      expect(AppColors.white, Colors.white);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/constants/app_colors_test.dart
```

Expected: FAIL — `app_colors.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFFF1F0F0);
  static const Color highlight = Color(0xFFFEBF22);
  static const Color secondary = Color(0xFF2261FE);
  static const Color textPrimary = Color(0xFF5C5956);
  static const Color white = Colors.white;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/constants/app_colors_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/app_colors.dart test/core/constants/app_colors_test.dart
git commit -m "feat: add AppColors constants with tests"
```

---

### Task 2: Tema do app

**Files:**
- Create: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Write implementation**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

abstract final class AppTheme {
  static const String _fontFamilyTitle = 'OutfitBlack';
  static const String _fontFamilyBody = 'QuasimodoSemiBold';

  static String get fontFamilyTitle => _fontFamilyTitle;
  static String get fontFamilyBody => _fontFamilyBody;

  static ThemeData get light => ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: _fontFamilyBody,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.highlight,
          surface: AppColors.background,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: _fontFamilyTitle,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
          bodyLarge: TextStyle(
            fontFamily: _fontFamilyBody,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      );
}
```

- [ ] **Step 2: Verificar compilação**

```bash
flutter analyze
```

Expected: sem erros.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat: add AppTheme with custom fonts"
```

---

### Task 3: GoRouter e rotas

**Files:**
- Create: `lib/routes/app_router.dart`
- Test: `test/routes/app_router_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/routes/app_router_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/routes/app_router.dart';

void main() {
  group('AppRouter', () {
    test('should have onboarding as initial route', () {
      final router = AppRouter.router;
      expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
    });

    test('router should not be null', () {
      expect(AppRouter.router, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/routes/app_router_test.dart
```

Expected: FAIL — `app_router.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Onboarding'))),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Login'))),
      ),
    ],
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/routes/app_router_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/routes/app_router.dart test/routes/app_router_test.dart
git commit -m "feat: add GoRouter with onboarding and login routes"
```

---

### Task 4: main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Write main.dart**

```dart
// lib/main.dart
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
```

- [ ] **Step 2: Run app to verify no crash**

```bash
flutter analyze
```

Expected: sem erros.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: add main.dart with KzServicosApp"
```

---

### Task 5: Widget OnboardingSlide

**Files:**
- Create: `lib/features/onboarding/presentation/widgets/onboarding_slide.dart`
- Test: `test/features/onboarding/presentation/widgets/onboarding_slide_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/onboarding/presentation/widgets/onboarding_slide_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/onboarding/presentation/widgets/onboarding_slide.dart';

void main() {
  group('OnboardingSlide', () {
    testWidgets('should display title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingSlide(
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              textColor: Colors.white,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('should use correct text color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingSlide(
              title: 'Title',
              subtitle: 'Subtitle',
              textColor: Colors.red,
            ),
          ),
        ),
      );

      final titleWidget = tester.widget<Text>(find.text('Title'));
      expect(titleWidget.style?.color, Colors.red);

      final subtitleWidget = tester.widget<Text>(find.text('Subtitle'));
      expect(subtitleWidget.style?.color, Colors.red);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/onboarding/presentation/widgets/onboarding_slide_test.dart
```

Expected: FAIL — file does not exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/onboarding/presentation/widgets/onboarding_slide.dart
import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.textColor,
    super.key,
  });

  final String title;
  final String subtitle;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyTitle,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyBody,
              fontSize: 16,
              color: textColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/onboarding/presentation/widgets/onboarding_slide_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/widgets/onboarding_slide.dart test/features/onboarding/presentation/widgets/onboarding_slide_test.dart
git commit -m "feat: add OnboardingSlide widget with tests"
```

---

### Task 6: Widget OnboardingDots

**Files:**
- Create: `lib/features/onboarding/presentation/widgets/onboarding_dots.dart`
- Test: `test/features/onboarding/presentation/widgets/onboarding_dots_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/onboarding/presentation/widgets/onboarding_dots_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/onboarding/presentation/widgets/onboarding_dots.dart';

void main() {
  group('OnboardingDots', () {
    testWidgets('should render 3 dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingDots(
              count: 3,
              currentIndex: 0,
              activeColor: Colors.white,
            ),
          ),
        ),
      );

      final containers = find.byType(AnimatedContainer);
      expect(containers, findsNWidgets(3));
    });

    testWidgets('active dot should be larger', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingDots(
              count: 3,
              currentIndex: 1,
              activeColor: Colors.white,
            ),
          ),
        ),
      );

      final dots = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      ).toList();

      // Active dot (index 1) should have width 24, inactive should have width 8
      expect(dots.length, 3);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/onboarding/presentation/widgets/onboarding_dots_test.dart
```

Expected: FAIL — file does not exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/onboarding/presentation/widgets/onboarding_dots.dart
import 'package:flutter/material.dart';

class OnboardingDots extends StatelessWidget {
  const OnboardingDots({
    required this.count,
    required this.currentIndex,
    required this.activeColor,
    super.key,
  });

  final int count;
  final int currentIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : activeColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/onboarding/presentation/widgets/onboarding_dots_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/widgets/onboarding_dots.dart test/features/onboarding/presentation/widgets/onboarding_dots_test.dart
git commit -m "feat: add OnboardingDots widget with tests"
```

---

### Task 7: OnboardingPage com animação de cor

**Files:**
- Create: `lib/features/onboarding/presentation/pages/onboarding_page.dart`
- Test: `test/features/onboarding/presentation/pages/onboarding_page_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/onboarding/presentation/pages/onboarding_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  Widget buildTestApp({String initialRoute = '/onboarding'}) {
    final router = GoRouter(
      initialLocation: initialRoute,
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Login Page'))),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('OnboardingPage', () {
    testWidgets('should display first slide title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Solicitar serviços KZ ficou ainda mais fácil'),
        findsOneWidget,
      );
    });

    testWidgets('should display "Pular" button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Pular'), findsOneWidget);
    });

    testWidgets('should display "Próximo" with arrow', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Próximo'), findsOneWidget);
    });

    testWidgets('should display 3 dots', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('should navigate to next slide on "Próximo" tap',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Próximo'));
      await tester.pumpAndSettle();

      expect(
        find.text('Segurança e Confiabilidade'),
        findsOneWidget,
      );
    });

    testWidgets('should show "Começar" on last slide', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Navigate to slide 2
      await tester.tap(find.textContaining('Próximo'));
      await tester.pumpAndSettle();

      // Navigate to slide 3
      await tester.tap(find.textContaining('Próximo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Começar'), findsOneWidget);
      expect(find.text('Pular'), findsNothing);
    });

    testWidgets('should navigate to login on "Pular" tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('should navigate to login on "Começar" tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Navigate to last slide
      await tester.tap(find.textContaining('Próximo'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Começar'));
      await tester.pumpAndSettle();

      expect(find.text('Login Page'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/onboarding/presentation/pages/onboarding_page_test.dart
```

Expected: FAIL — file does not exist.

- [ ] **Step 3: Write implementation**

```dart
// lib/features/onboarding/presentation/pages/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/onboarding/presentation/widgets/onboarding_dots.dart';
import 'package:kz_servicos_app/features/onboarding/presentation/widgets/onboarding_slide.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  double _currentPage = 0;

  static const _slides = [
    (
      title: 'Solicitar serviços KZ ficou ainda mais fácil',
      subtitle:
          'Nosso novo APP conecta você ao motorista com poucos cliques. Rápido e prático.',
      backgroundColor: AppColors.highlight,
      textColor: AppColors.white,
    ),
    (
      title: 'Segurança e Confiabilidade',
      subtitle:
          'Continuamos moderando e monitorando 24h. Nossos afiliados passam por uma etapa rigorosa de aprovação.',
      backgroundColor: AppColors.secondary,
      textColor: AppColors.white,
    ),
    (
      title: 'Agilidade para agendamento',
      subtitle:
          'Agendar viagens ficou rápido e prático. Conte com acompanhamento em tempo real do seu agendamento.',
      backgroundColor: AppColors.background,
      textColor: AppColors.textPrimary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  Color _interpolateBackgroundColor() {
    final lowerIndex = _currentPage.floor();
    final upperIndex = _currentPage.ceil();
    final t = _currentPage - lowerIndex;

    final lowerColor = _slides[lowerIndex.clamp(0, _slides.length - 1)]
        .backgroundColor;
    final upperColor = _slides[upperIndex.clamp(0, _slides.length - 1)]
        .backgroundColor;

    return Color.lerp(lowerColor, upperColor, t) ?? lowerColor;
  }

  Color _interpolateTextColor() {
    final lowerIndex = _currentPage.floor();
    final upperIndex = _currentPage.ceil();
    final t = _currentPage - lowerIndex;

    final lowerColor =
        _slides[lowerIndex.clamp(0, _slides.length - 1)].textColor;
    final upperColor =
        _slides[upperIndex.clamp(0, _slides.length - 1)].textColor;

    return Color.lerp(lowerColor, upperColor, t) ?? lowerColor;
  }

  int get _currentIndex => _currentPage.round();
  bool get _isLastSlide => _currentIndex == _slides.length - 1;

  void _onNext() {
    if (_isLastSlide) {
      context.go('/login');
    } else {
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkip() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _interpolateBackgroundColor();
    final textColor = _interpolateTextColor();

    return Scaffold(
      body: AnimatedContainer(
        duration: Duration.zero,
        color: backgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              _buildSkipButton(textColor),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return OnboardingSlide(
                      title: slide.title,
                      subtitle: slide.subtitle,
                      textColor: slide.textColor,
                    );
                  },
                ),
              ),
              _buildBottomSection(textColor),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(Color textColor) {
    if (_isLastSlide) {
      return const SizedBox(height: 56);
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 24, top: 16),
        child: GestureDetector(
          onTap: _onSkip,
          child: Text(
            'Pular',
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyBody,
              fontSize: 16,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(Color textColor) {
    return Column(
      children: [
        OnboardingDots(
          count: _slides.length,
          currentIndex: _currentIndex,
          activeColor: textColor,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _onNext,
          child: Text(
            _isLastSlide ? 'Começar →' : 'Próximo →',
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyBody,
              fontSize: 18,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/onboarding/presentation/pages/onboarding_page_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/pages/onboarding_page.dart test/features/onboarding/presentation/pages/onboarding_page_test.dart
git commit -m "feat: add OnboardingPage with gradient transitions and tests"
```

---

### Task 8: LoginPage

**Files:**
- Create: `lib/features/auth/presentation/pages/login_page.dart`
- Test: `test/features/auth/presentation/pages/login_page_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/auth/presentation/pages/login_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage', () {
    testWidgets('should display logo image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should display email field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
    });

    testWidgets('should display password field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    });

    testWidgets('should display "Entrar" button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('should display "Criar conta" link', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text('Criar conta'), findsOneWidget);
    });

    testWidgets('password field should obscure text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      final passwordField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Senha'),
      );
      expect(passwordField.obscureText, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/auth/presentation/pages/login_page_test.dart
```

Expected: FAIL — file does not exist.

- [ ] **Step 3: Write implementation**

```dart
// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 64),
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
              const SizedBox(height: 48),
              TextField(
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  labelStyle: TextStyle(color: AppColors.textPrimary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.highlight, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  labelStyle: TextStyle(color: AppColors.textPrimary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.highlight, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.highlight,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: TextStyle(
                      fontFamily: AppTheme.fontFamilyBody,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Entrar'),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Criar conta',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamilyBody,
                    fontSize: 16,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/auth/presentation/pages/login_page_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/pages/login_page.dart test/features/auth/presentation/pages/login_page_test.dart
git commit -m "feat: add LoginPage with tests"
```

---

### Task 9: Integrar rotas com páginas reais

**Files:**
- Modify: `lib/routes/app_router.dart`

- [ ] **Step 1: Update router to use real pages**

```dart
// lib/routes/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/features/auth/presentation/pages/login_page.dart';
import 'package:kz_servicos_app/features/onboarding/presentation/pages/onboarding_page.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );
}
```

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: ALL PASS.

- [ ] **Step 3: Run analyze**

```bash
flutter analyze
```

Expected: sem erros.

- [ ] **Step 4: Commit**

```bash
git add lib/routes/app_router.dart
git commit -m "feat: wire up real pages in GoRouter"
```

---

### Task 10: Verificação final

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

Expected: ALL PASS.

- [ ] **Step 2: Run analyze**

```bash
flutter analyze
```

Expected: sem erros.

- [ ] **Step 3: Manual verification**

```bash
flutter run -d chrome
```

Verificar visualmente:
- Slide 1: fundo amarelo, texto branco, "Pular" visível
- Slide 2: fundo azul, texto branco
- Slide 3: fundo cinza claro, texto escuro, sem "Pular", "Começar →"
- Transição de cor fluida entre slides
- Tela de login com logo, campos e botão

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete onboarding and login screens"
```
