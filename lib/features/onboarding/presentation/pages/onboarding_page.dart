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
    final lowerIndex = _currentPage.floor();
    final upperIndex = _currentPage.ceil();
    final t = _currentPage - lowerIndex;

    final lowerColor =
        _slides[lowerIndex.clamp(0, _slides.length - 1)].textColor;
    final upperColor =
        _slides[upperIndex.clamp(0, _slides.length - 1)].textColor;

    return Color.lerp(lowerColor, upperColor, t) ?? lowerColor;
  }

  Color _interpolateParticleColor() {
    final lowerIndex = _currentPage.floor().clamp(0, _slides.length - 1);
    final upperIndex = _currentPage.ceil().clamp(0, _slides.length - 1);
    final t = _currentPage - _currentPage.floor();

    final lowerColor = lowerIndex < 2 ? AppColors.white : AppColors.textPrimary;
    final upperColor = upperIndex < 2 ? AppColors.white : AppColors.textPrimary;

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
          Positioned.fill(
            child: MeshGradientBackground(colors: meshColors),
          ),
          Positioned.fill(
            child: DustParticles(
              color: particleColor,
              scrollOffset: _currentPage,
            ),
          ),
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
