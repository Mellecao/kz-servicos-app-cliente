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

    final lowerColor =
        _slides[lowerIndex.clamp(0, _slides.length - 1)].backgroundColor;
    final upperColor =
        _slides[upperIndex.clamp(0, _slides.length - 1)].backgroundColor;

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
      body: Container(
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
