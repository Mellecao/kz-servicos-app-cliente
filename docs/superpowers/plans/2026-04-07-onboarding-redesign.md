# Onboarding Premium Redesign + Login Liquid Glass — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign completo do onboarding com mesh gradient aurora, partículas parallax, Lottie animations, e tela de login com efeito liquid glass estilo Apple WWDC 2025.

**Architecture:** Widgets visuais compartilhados em `core/widgets/` (MeshGradient, DustParticles, LiquidGlassCard). Onboarding e Login reescritos usando esses building blocks. Lottie para ícones animados. CustomPainter para gradientes e partículas.

**Tech Stack:** Flutter, Dart, lottie package, CustomPainter, BackdropFilter, GoRouter

---

## File Structure

| File | Responsibility |
|------|----------------|
| `lib/core/constants/app_colors.dart` | Adicionar cores do mesh gradient por slide |
| `lib/core/widgets/mesh_gradient_background.dart` | CustomPainter para gradiente mesh aurora animado |
| `lib/core/widgets/dust_particles.dart` | CustomPainter para partículas flutuantes com parallax |
| `lib/core/widgets/liquid_glass_card.dart` | Widget liquid glass reutilizável (blur + tint + shine) |
| `lib/features/onboarding/presentation/pages/onboarding_page.dart` | REESCREVER — integrar mesh, partículas, Lottie |
| `lib/features/onboarding/presentation/widgets/onboarding_slide.dart` | REESCREVER — adicionar Lottie + fade-in |
| `lib/features/onboarding/presentation/widgets/onboarding_dots.dart` | Manter (sem mudanças) |
| `lib/features/auth/presentation/pages/login_page.dart` | REESCREVER — liquid glass card + mesh background |
| `pubspec.yaml` | Adicionar lottie dependency + assets/animations/ |
| `assets/animations/smartphone_tap.json` | Lottie animation slide 1 |
| `assets/animations/shield_check.json` | Lottie animation slide 2 |
| `assets/animations/calendar_clock.json` | Lottie animation slide 3 |
| `test/core/widgets/mesh_gradient_background_test.dart` | Testes do mesh gradient |
| `test/core/widgets/dust_particles_test.dart` | Testes das partículas |
| `test/core/widgets/liquid_glass_card_test.dart` | Testes do liquid glass |
| `test/features/onboarding/presentation/pages/onboarding_page_test.dart` | Atualizar testes |
| `test/features/onboarding/presentation/widgets/onboarding_slide_test.dart` | Atualizar testes |
| `test/features/auth/presentation/pages/login_page_test.dart` | Atualizar testes |

---

### Task 0: Adicionar dependências e assets Lottie

**Files:**
- Modify: `pubspec.yaml`
- Create: `assets/animations/smartphone_tap.json`
- Create: `assets/animations/shield_check.json`
- Create: `assets/animations/calendar_clock.json`

- [ ] **Step 1: Adicionar lottie ao pubspec.yaml**

Add `lottie: ^3.3.1` to dependencies and `assets/animations/` to assets in `pubspec.yaml`.

After the line `go_router: ^15.1.2` add:
```yaml
  lottie: ^3.3.1
```

In the assets section, after `- assets/images/` add:
```yaml
    - assets/animations/
```

- [ ] **Step 2: Download Lottie JSON files**

Create `assets/animations/` directory and download free Lottie animations from LottieFiles:

For each animation file, find a suitable free Lottie from lottiefiles.com and download the JSON. If downloads are not possible, create minimal placeholder Lottie JSON files that display a simple icon animation.

Placeholder approach — create minimal valid Lottie JSON files:

`assets/animations/smartphone_tap.json` — a simple animated smartphone icon
`assets/animations/shield_check.json` — a simple animated shield with checkmark
`assets/animations/calendar_clock.json` — a simple animated calendar

- [ ] **Step 3: Run flutter pub get**

```bash
flutter pub get
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: add lottie dependency and animation assets"
```

---

### Task 1: Expandir AppColors com cores de mesh gradient

**Files:**
- Modify: `lib/core/constants/app_colors.dart`
- Modify: `test/core/constants/app_colors_test.dart`

- [ ] **Step 1: Write failing tests**

Add to `test/core/constants/app_colors_test.dart`:

```dart
test('meshSlide1 should have 4 colors', () {
  expect(AppColors.meshSlide1.length, 4);
});

test('meshSlide2 should have 4 colors', () {
  expect(AppColors.meshSlide2.length, 4);
});

test('meshSlide3 should have 4 colors', () {
  expect(AppColors.meshSlide3.length, 4);
});
```

- [ ] **Step 2: Run tests to verify failure**

```bash
flutter test test/core/constants/app_colors_test.dart
```

- [ ] **Step 3: Add mesh gradient colors**

Add to `lib/core/constants/app_colors.dart`:

```dart
// Mesh gradient colors per slide
static const List<Color> meshSlide1 = [
  Color(0xFFFEBF22),
  Color(0xFFFF9500),
  Color(0xFFFFD700),
  Color(0xFFFFA000),
];

static const List<Color> meshSlide2 = [
  Color(0xFF2261FE),
  Color(0xFF1A47C2),
  Color(0xFF4A7DFF),
  Color(0xFF0D3B9E),
];

static const List<Color> meshSlide3 = [
  Color(0xFFF1F0F0),
  Color(0xFFE0DFDF),
  Color(0xFFD5D4D4),
  Color(0xFFEAEAEA),
];
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/constants/app_colors_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/app_colors.dart test/core/constants/app_colors_test.dart
git commit -m "feat: add mesh gradient color palettes to AppColors"
```

---

### Task 2: MeshGradientBackground widget

**Files:**
- Create: `lib/core/widgets/mesh_gradient_background.dart`
- Create: `test/core/widgets/mesh_gradient_background_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/widgets/mesh_gradient_background_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/widgets/mesh_gradient_background.dart';

void main() {
  group('MeshGradientBackground', () {
    testWidgets('should render CustomPaint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeshGradientBackground(
              colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should accept colors parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeshGradientBackground(
              colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final widget = tester.widget<MeshGradientBackground>(
        find.byType(MeshGradientBackground),
      );
      expect(widget.colors.length, 4);
    });

    testWidgets('should fill available space', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: MeshGradientBackground(
                colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final renderBox = tester.renderObject<RenderBox>(
        find.byType(MeshGradientBackground),
      );
      expect(renderBox.size.width, 400);
      expect(renderBox.size.height, 800);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/widgets/mesh_gradient_background_test.dart
```

- [ ] **Step 3: Write implementation**

Create `lib/core/widgets/mesh_gradient_background.dart`:

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class MeshGradientBackground extends StatefulWidget {
  const MeshGradientBackground({
    required this.colors,
    super.key,
  });

  final List<Color> colors;

  @override
  State<MeshGradientBackground> createState() =>
      _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MeshGradientPainter(
            colors: widget.colors,
            animationValue: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  _MeshGradientPainter({
    required this.colors,
    required this.animationValue,
  });

  final List<Color> colors;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    final positions = _calculatePositions(size);

    for (var i = 0; i < colors.length && i < positions.length; i++) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[i].withValues(alpha: 0.8),
            colors[i].withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: positions[i],
            radius: size.width * 0.7,
          ),
        );
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  List<Offset> _calculatePositions(Size size) {
    final t = animationValue * 2 * math.pi;
    return [
      Offset(
        size.width * (0.3 + 0.15 * math.cos(t)),
        size.height * (0.2 + 0.1 * math.sin(t * 1.3)),
      ),
      Offset(
        size.width * (0.7 + 0.1 * math.sin(t * 0.8)),
        size.height * (0.3 + 0.15 * math.cos(t * 1.1)),
      ),
      Offset(
        size.width * (0.4 + 0.2 * math.sin(t * 0.6)),
        size.height * (0.7 + 0.1 * math.cos(t * 0.9)),
      ),
      Offset(
        size.width * (0.8 + 0.1 * math.cos(t * 1.2)),
        size.height * (0.8 + 0.1 * math.sin(t * 0.7)),
      ),
    ];
  }

  @override
  bool shouldRepaint(_MeshGradientPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue ||
      colors != oldDelegate.colors;
}
```

**Note:** Use `AnimatedBuilder` (not `AnimatedContainer`). The mesh gradient uses 4 radial gradients at animated positions that orbit slowly creating the Aurora effect.

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/widgets/mesh_gradient_background_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/mesh_gradient_background.dart test/core/widgets/mesh_gradient_background_test.dart
git commit -m "feat: add MeshGradientBackground with animated aurora effect"
```

---

### Task 3: DustParticles widget

**Files:**
- Create: `lib/core/widgets/dust_particles.dart`
- Create: `test/core/widgets/dust_particles_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/widgets/dust_particles_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/widgets/dust_particles.dart';

void main() {
  group('DustParticles', () {
    testWidgets('should render CustomPaint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DustParticles(
              color: Colors.white,
              scrollOffset: 0,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should accept color and scrollOffset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DustParticles(
              color: Colors.red,
              scrollOffset: 0.5,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final widget = tester.widget<DustParticles>(
        find.byType(DustParticles),
      );
      expect(widget.color, Colors.red);
      expect(widget.scrollOffset, 0.5);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/widgets/dust_particles_test.dart
```

- [ ] **Step 3: Write implementation**

Create `lib/core/widgets/dust_particles.dart`:

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class DustParticles extends StatefulWidget {
  const DustParticles({
    required this.color,
    required this.scrollOffset,
    this.particleCount = 25,
    super.key,
  });

  final Color color;
  final double scrollOffset;
  final int particleCount;

  @override
  State<DustParticles> createState() => _DustParticlesState();
}

class _DustParticlesState extends State<DustParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    final random = math.Random(42);
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 2 + random.nextDouble() * 3,
        speed: 0.2 + random.nextDouble() * 0.6,
        opacity: 0.2 + random.nextDouble() * 0.4,
        phase: random.nextDouble() * 2 * math.pi,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _DustPainter(
            particles: _particles,
            color: widget.color,
            animationValue: _controller.value,
            scrollOffset: widget.scrollOffset,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double phase;
}

class _DustPainter extends CustomPainter {
  _DustPainter({
    required this.particles,
    required this.color,
    required this.animationValue,
    required this.scrollOffset,
  });

  final List<_Particle> particles;
  final Color color;
  final double animationValue;
  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final t = animationValue * 2 * math.pi;
      final parallaxX = scrollOffset * 30 * particle.speed;

      final x = ((particle.x * size.width +
                  math.sin(t * particle.speed + particle.phase) * 20 -
                  parallaxX) %
              size.width +
          size.width) %
          size.width;

      final y = ((particle.y * size.height +
                  math.cos(t * particle.speed * 0.7 + particle.phase) * 15) %
              size.height +
          size.height) %
          size.height;

      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_DustPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue ||
      scrollOffset != oldDelegate.scrollOffset ||
      color != oldDelegate.color;
}
```

**Key:** The `scrollOffset` drives parallax — particles shift opposite to swipe direction by `scrollOffset * 30 * particle.speed`. Faster particles move more.

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/widgets/dust_particles_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/dust_particles.dart test/core/widgets/dust_particles_test.dart
git commit -m "feat: add DustParticles with parallax scroll effect"
```

---

### Task 4: LiquidGlassCard widget

**Files:**
- Create: `lib/core/widgets/liquid_glass_card.dart`
- Create: `test/core/widgets/liquid_glass_card_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/widgets/liquid_glass_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/widgets/liquid_glass_card.dart';

void main() {
  group('LiquidGlassCard', () {
    testWidgets('should render child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                LiquidGlassCard(
                  child: Text('Glass Content'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Glass Content'), findsOneWidget);
    });

    testWidgets('should contain BackdropFilter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                LiquidGlassCard(
                  child: Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('should apply border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                LiquidGlassCard(
                  borderRadius: 32,
                  child: Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );

      final widget = tester.widget<LiquidGlassCard>(
        find.byType(LiquidGlassCard),
      );
      expect(widget.borderRadius, 32);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/widgets/liquid_glass_card_test.dart
```

- [ ] **Step 3: Write implementation**

Create `lib/core/widgets/liquid_glass_card.dart`:

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    required this.child,
    this.borderRadius = 24,
    this.blurSigma = 12,
    this.tintOpacity = 0.15,
    this.padding = const EdgeInsets.all(32),
    super.key,
  });

  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final double tintOpacity;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.white.withValues(alpha: tintOpacity),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.2),
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(1, 1),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
```

**Liquid glass effect layers:**
1. `BackdropFilter` blur — distorts what's behind (mesh gradient bleeds through)
2. Tint — subtle white overlay
3. Gradient — top-left brighter, bottom-right darker (simulates light refraction)
4. Border — semi-transparent white border (shine edge)
5. BoxShadow — depth + subtle inner highlight

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/widgets/liquid_glass_card_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/liquid_glass_card.dart test/core/widgets/liquid_glass_card_test.dart
git commit -m "feat: add LiquidGlassCard with backdrop blur and glass effect"
```

---

### Task 5: Reescrever OnboardingSlide com Lottie + fade-in

**Files:**
- Modify: `lib/features/onboarding/presentation/widgets/onboarding_slide.dart`
- Modify: `test/features/onboarding/presentation/widgets/onboarding_slide_test.dart`

- [ ] **Step 1: Update tests**

Rewrite `test/features/onboarding/presentation/widgets/onboarding_slide_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/onboarding/presentation/widgets/onboarding_slide.dart';

void main() {
  group('OnboardingSlide', () {
    testWidgets('should display title and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingSlide(
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              textColor: Colors.white,
              lottieAsset: 'assets/animations/smartphone_tap.json',
              isActive: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('should use correct text color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingSlide(
              title: 'Title',
              subtitle: 'Subtitle',
              textColor: Colors.red,
              lottieAsset: 'assets/animations/smartphone_tap.json',
              isActive: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleWidget = tester.widget<Text>(find.text('Title'));
      expect(titleWidget.style?.color, Colors.red);
    });

    testWidgets('should have lottieAsset parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingSlide(
              title: 'Title',
              subtitle: 'Subtitle',
              textColor: Colors.white,
              lottieAsset: 'assets/animations/shield_check.json',
              isActive: false,
            ),
          ),
        ),
      );
      await tester.pump();

      final widget = tester.widget<OnboardingSlide>(
        find.byType(OnboardingSlide),
      );
      expect(widget.lottieAsset, 'assets/animations/shield_check.json');
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/features/onboarding/presentation/widgets/onboarding_slide_test.dart
```

- [ ] **Step 3: Rewrite implementation**

Replace `lib/features/onboarding/presentation/widgets/onboarding_slide.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.lottieAsset,
    required this.isActive,
    super.key,
  });

  final String title;
  final String subtitle;
  final Color textColor;
  final String lottieAsset;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isActive ? 1.0 : 0.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 180,
              width: 180,
              child: Lottie.asset(
                lottieAsset,
                animate: isActive,
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.animation,
                    size: 100,
                    color: textColor.withValues(alpha: 0.5),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
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
                color: textColor.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Key changes:** Added `lottieAsset` param, `isActive` for fade-in, Lottie widget with error fallback icon, `AnimatedOpacity` for fade effect.

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/onboarding/presentation/widgets/onboarding_slide_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/widgets/onboarding_slide.dart test/features/onboarding/presentation/widgets/onboarding_slide_test.dart
git commit -m "feat: redesign OnboardingSlide with Lottie and fade-in"
```

---

### Task 6: Reescrever OnboardingPage com mesh gradient + partículas

**Files:**
- Modify: `lib/features/onboarding/presentation/pages/onboarding_page.dart`
- Modify: `test/features/onboarding/presentation/pages/onboarding_page_test.dart`

- [ ] **Step 1: Update tests**

Rewrite `test/features/onboarding/presentation/pages/onboarding_page_test.dart`:

```dart
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

    testWidgets('should contain MeshGradientBackground', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Verify CustomPaint is rendered (mesh gradient uses CustomPaint)
      expect(find.byType(CustomPaint), findsWidgets);
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

      await tester.tap(find.textContaining('Próximo'));
      await tester.pumpAndSettle();

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

- [ ] **Step 2: Rewrite OnboardingPage**

Replace `lib/features/onboarding/presentation/pages/onboarding_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/core/widgets/dust_particles.dart';
import 'package:kz_servicos_app/core/widgets/mesh_gradient_background.dart';
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
      meshColors: AppColors.meshSlide1,
      textColor: AppColors.white,
      lottieAsset: 'assets/animations/smartphone_tap.json',
    ),
    (
      title: 'Segurança e Confiabilidade',
      subtitle:
          'Continuamos moderando e monitorando 24h. Nossos afiliados passam por uma etapa rigorosa de aprovação.',
      meshColors: AppColors.meshSlide2,
      textColor: AppColors.white,
      lottieAsset: 'assets/animations/shield_check.json',
    ),
    (
      title: 'Agilidade para agendamento',
      subtitle:
          'Agendar viagens ficou rápido e prático. Conte com acompanhamento em tempo real do seu agendamento.',
      meshColors: AppColors.meshSlide3,
      textColor: AppColors.textPrimary,
      lottieAsset: 'assets/animations/calendar_clock.json',
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

  List<Color> _interpolateMeshColors() {
    final lowerIndex = _currentPage.floor().clamp(0, _slides.length - 1);
    final upperIndex = _currentPage.ceil().clamp(0, _slides.length - 1);
    final t = _currentPage - _currentPage.floor();

    final lowerColors = _slides[lowerIndex].meshColors;
    final upperColors = _slides[upperIndex].meshColors;

    return List.generate(
      lowerColors.length,
      (i) => Color.lerp(lowerColors[i], upperColors[i], t) ?? lowerColors[i],
    );
  }

  Color _interpolateTextColor() {
    final lowerIndex = _currentPage.floor().clamp(0, _slides.length - 1);
    final upperIndex = _currentPage.ceil().clamp(0, _slides.length - 1);
    final t = _currentPage - _currentPage.floor();

    return Color.lerp(
          _slides[lowerIndex].textColor,
          _slides[upperIndex].textColor,
          t,
        ) ??
        _slides[lowerIndex].textColor;
  }

  Color _interpolateParticleColor() {
    final lowerIndex = _currentPage.floor().clamp(0, _slides.length - 1);
    final upperIndex = _currentPage.ceil().clamp(0, _slides.length - 1);
    final t = _currentPage - _currentPage.floor();

    final lowerColor =
        lowerIndex < 2 ? AppColors.white : AppColors.textPrimary;
    final upperColor =
        upperIndex < 2 ? AppColors.white : AppColors.textPrimary;

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
    final meshColors = _interpolateMeshColors();
    final textColor = _interpolateTextColor();
    final particleColor = _interpolateParticleColor();

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Mesh gradient background
          Positioned.fill(
            child: MeshGradientBackground(colors: meshColors),
          ),
          // Layer 2: Dust particles
          Positioned.fill(
            child: DustParticles(
              color: particleColor,
              scrollOffset: _currentPage,
            ),
          ),
          // Layer 3: Content
          SafeArea(
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
                        lottieAsset: slide.lottieAsset,
                        isActive: _currentIndex == index,
                      );
                    },
                  ),
                ),
                _buildBottomSection(textColor),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
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

- [ ] **Step 3: Run tests**

```bash
flutter test test/features/onboarding/presentation/pages/onboarding_page_test.dart
```

- [ ] **Step 4: Run all tests**

```bash
flutter test
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/pages/onboarding_page.dart test/features/onboarding/presentation/pages/onboarding_page_test.dart
git commit -m "feat: redesign OnboardingPage with mesh gradient and particles"
```

---

### Task 7: Reescrever LoginPage com liquid glass

**Files:**
- Modify: `lib/features/auth/presentation/pages/login_page.dart`
- Modify: `test/features/auth/presentation/pages/login_page_test.dart`

- [ ] **Step 1: Update tests**

Rewrite `test/features/auth/presentation/pages/login_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/widgets/liquid_glass_card.dart';
import 'package:kz_servicos_app/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage', () {
    testWidgets('should display logo image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should display email field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
    });

    testWidgets('should display password field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    });

    testWidgets('should display "Entrar" button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('should display "Criar conta" link', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Criar conta'), findsOneWidget);
    });

    testWidgets('password field should obscure text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final passwordField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Senha'),
      );
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('should contain LiquidGlassCard', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LiquidGlassCard), findsOneWidget);
    });

    testWidgets('should have mesh gradient background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
```

- [ ] **Step 2: Rewrite LoginPage**

Replace `lib/features/auth/presentation/pages/login_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/core/widgets/dust_particles.dart';
import 'package:kz_servicos_app/core/widgets/liquid_glass_card.dart';
import 'package:kz_servicos_app/core/widgets/mesh_gradient_background.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Mesh gradient background
          Positioned.fill(
            child: MeshGradientBackground(colors: AppColors.meshSlide3),
          ),
          // Layer 2: Dust particles
          const Positioned.fill(
            child: DustParticles(
              color: AppColors.textPrimary,
              scrollOffset: 0,
            ),
          ),
          // Layer 3: Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                    ),
                    const SizedBox(height: 40),
                    LiquidGlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTextField(
                            label: 'E-mail',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Senha',
                            obscureText: true,
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
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: AppTheme.fontFamilyBody,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: 0.7),
          fontFamily: AppTheme.fontFamilyBody,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.highlight,
            width: 2,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run tests**

```bash
flutter test test/features/auth/presentation/pages/login_page_test.dart
```

- [ ] **Step 4: Run all tests**

```bash
flutter test
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/pages/login_page.dart test/features/auth/presentation/pages/login_page_test.dart
git commit -m "feat: redesign LoginPage with liquid glass and mesh gradient"
```

---

### Task 8: Verificação final e ajustes

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

Expected: ALL PASS.

- [ ] **Step 2: Run analyze**

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 3: Run app visually**

```bash
flutter run -d edge
```

Verify visually:
- Slide 1: warm mesh gradient (yellows/oranges), white particles, Lottie smartphone, white text
- Slide 2: blue mesh gradient, white particles, Lottie shield, white text
- Slide 3: light gray mesh gradient, dark particles, Lottie calendar, dark text
- Smooth color transitions between slides
- Particles move opposite to swipe direction
- Login: mesh gradient + floating particles + glass card with blur effect + logo + fields + button

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete premium redesign with mesh gradient, particles, and liquid glass"
```
