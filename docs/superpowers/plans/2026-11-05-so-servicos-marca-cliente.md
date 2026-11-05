# Só Serviços — Marca no App Cliente (F2) Implementation Plan

> **For agentic workers:** execução inline na sessão (contrato §3.5: sem perguntas). Steps com checkbox.

**Goal:** Trocar a identidade do App Cliente para "Só Serviços" (laranja `#FF9A52`, logos, ícone, splash) sem quebrar fluxos de viagens/serviços.

**Architecture:** Uma única fonte de cores (`AppColors`) e um único widget de logo (`BrandLogo`) lido de `assets/brand/`. Ícones/splash nativos gerados a partir dos assets copiados (não gerar assets novos). Texto visível "Só Serviços" numa constante única (`AppBrand.name`).

**Tech Stack:** Flutter 3.41 / Dart 3.11, `flutter_launcher_icons` (já em dev_dependencies), `flutter_test`.

**Spec:** `C:\Users\v27me\orca\workspaces\kz-servicos-web-app-fork\tellin\docs\superpowers\specs\2026-11-05-so-servicos-reativacao-design.md` (§3, §4)

## Global Constraints

- Primária `#FF9A52`, escura `#E68B4A`, clara `#FFB27A`, rosa `#E54C65`, texto sobre primária `#1F2430` (nunca branco sobre laranja), degradê `#E54C65 → #FF9A52`, fundo do ícone `#16161D`.
- Substituir `#FEBF22`, `#e5ab1e`, `#FFD700`, `#FFA000` e `amber`/`yellow`, incluindo meshes do onboarding. Manter verde de sucesso e azul secundário.
- Nome visível "Só Serviços". Logo branca em fundo escuro, escura em fundo claro.
- NÃO alterar `applicationId`/bundle id, `firebase_options.dart`, `google-services.json`.
- SEM commit, SEM push. Não reverter alterações pré-existentes (ícones Android, manifest, 33 ficheiros em `lib/`).
- Assets só copiados de `...\tellin\public\brand\`.

## Review Focus

- Texto branco sobre fundo laranja (onboarding slide 1, botões) → deve usar `AppColors.onPrimary`.
- Ícone adaptativo Android: foreground com margem segura, fundo `#16161D`.
- `assets/images/logo.png` aparece apagado na working tree (pré-existente): nada em `lib/` o referencia; não restaurar.
- Splash nativo e splash Flutter com o mesmo fundo escuro (sem "flash" claro).

---

### Task 1: Tokens de cor (TDD)

**Files:** Modify `lib/core/constants/app_colors.dart`, `test/core/constants/app_colors_test.dart`

**Interfaces:** Produces `AppColors.highlight` (=`#FF9A52`), `primaryDark`, `primaryLight`, `pink`, `onPrimary`, `brandGradient: LinearGradient`, `meshSlide1` (família laranja/rosa, 4 cores).

- [ ] Atualizar teste: `highlight == Color(0xFFFF9A52)`, `onPrimary == Color(0xFF1F2430)`, `primaryDark == Color(0xFFE68B4A)`, `primaryLight == Color(0xFFFFB27A)`, `pink == Color(0xFFE54C65)`, `brandGradient.colors == [pink, highlight]`, `meshSlide1` nenhuma cor igual a `FEBF22/FFD700/FFA000`.
- [ ] Rodar `flutter test test/core/constants/app_colors_test.dart` → FAIL.
- [ ] Implementar os tokens em `AppColors` (manter `sheet*` pré-existentes).
- [ ] Rodar o teste → PASS.

### Task 2: Remover amarelo hardcoded e contraste

**Files:** Modify `awaiting_driver_content.dart`, `driver_selection_page.dart`, `active_request_banner.dart`, `driver_card.dart`, `flash_driver_profile_modal.dart`, `login_page.dart`, `onboarding_page.dart`, `app_theme.dart` e demais ocorrências listadas por grep.

- [ ] Substituir hex amarelos por `AppColors.*`; estrelas de avaliação `Colors.amber` → `AppColors.highlight`; banner `amber.shade100` → tom claro derivado de `highlight`.
- [ ] Onboarding slide 1: `textColor` e cor de partículas → `AppColors.onPrimary`. Atualizar `onboarding_page_test.dart` se asserir cores.
- [ ] Botões com `backgroundColor: highlight`: `foregroundColor` → `AppColors.onPrimary`.
- [ ] `app_theme.dart`: `seedColor` já usa `highlight` (herda o novo laranja).
- [ ] Verificar: `grep -rniE "FEBF22|E5AB1E|FFD700|FFA000|Colors\.(amber|yellow)" lib` → vazio.

### Task 3: Assets, `AppBrand`, `BrandLogo`, splash Flutter

**Files:** Create `assets/brand/*` (cópia), `lib/core/constants/app_brand.dart`, `lib/core/widgets/brand_logo.dart`, `test/core/widgets/brand_logo_test.dart`; Modify `pubspec.yaml`, `splash_page.dart`, `login_page.dart`.

**Interfaces:** `AppBrand.name = 'Só Serviços'`, `AppBrand.tagline = 'Serviços de apoio ao domicílio'`; `BrandLogo({required bool onDark, double? width})` → `Image.asset('assets/brand/logo-horizontal-white.png' | '...-dark.png')`.

- [ ] Teste: `BrandLogo(onDark: true)` usa asset `logo-horizontal-white.png`; `onDark: false` usa `logo-horizontal-dark.png`.
- [ ] Copiar assets; registar `assets/brand/` no `pubspec.yaml`.
- [ ] Implementar `BrandLogo`; `SplashPage` → fundo `#16161D` + `BrandLogo(onDark: true)`; logo no login sobre o fundo.

### Task 4: Ícone, splash nativo e nome nas plataformas

**Files:** Modify `pubspec.yaml` (`flutter_launcher_icons`), `android/app/src/main/AndroidManifest.xml`, `res/drawable*/launch_background.xml`, `res/values/colors.xml`, `ios/Runner/Info.plist`, LaunchScreen, `web/index.html`, `web/manifest.json`, `web/icons/*`, `web/favicon.png`.

- [ ] `flutter_launcher_icons`: `image_path: assets/brand/app-icon-1024.png`, adaptativo (foreground 1024, background `#16161D`, monochrome), iOS sem alpha; rodar `dart run flutter_launcher_icons`.
- [ ] Android: `android:label="Só Serviços"`; splash = fundo `#16161D` + logo branca centrada. iOS: `CFBundleDisplayName=Só Serviços`, LaunchScreen escuro.
- [ ] Web: `<title>`, `short_name`, `name`, `theme-color` `#FF9A52`/`#16161D`, favicons de `brand/`.

### Task 5: Nome "Só Serviços" nos textos visíveis

**Files:** Modify textos com "KZ Serviços"/"Serviços"/"Plataforma de Serviços" visíveis (UI, `MaterialApp.title`, notificações locais).

- [ ] Usar `AppBrand.name`; `MaterialApp.title`; ajustar `test/widget_test.dart` se asserir título.
- [ ] Identificadores (`kz_servicos_app`, package, applicationId) NÃO mudam.

### Task 6: Verificação F2

- [ ] `flutter analyze` → sem issues novas além do baseline (24: 1 erro/8 avisos/15 infos).
- [ ] `flutter test` → mesmos resultados do baseline ou melhores.
- [ ] Reportar a `tellin-52` (≤12 linhas).
