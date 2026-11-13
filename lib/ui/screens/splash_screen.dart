import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';
import '../../state/app_state.dart';
import '../widgets/brand.dart';
import 'auth/welcome_screen.dart';
import 'onboarding_screen.dart';
import 'shell/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!_loading) {
      setState(() {
        _error = null;
        _loading = true;
      });
    }
    _progress
      ..reset()
      ..forward();
    final app = context.read<AppState>();
    try {
      await Future.wait([
        app.init(),
        Future<void>.delayed(const Duration(milliseconds: 1500))
      ]);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
      return;
    }
    if (!mounted) return;
    final Widget next;
    if (!app.onboardingDone) {
      next = const OnboardingScreen();
    } else if (!app.isLoggedIn) {
      next = const WelcomeScreen();
    } else {
      next = const MainShell();
    }
    goRoot(context, next);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DiviLogo(width: 196),
                const SizedBox(height: 48),
                if (_error == null) ...[
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (_, __) => LinearProgressIndicator(
                          value: _progress.value,
                          minHeight: 4,
                          backgroundColor: p.bgMuted,
                          color: p.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Memuat aplikasi...',
                      style: AppText.caption.c(p.textSecondary)),
                ] else ...[
                  Text('Aplikasi tidak dapat dimuat',
                      style: AppText.h3.c(p.textPrimary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Periksa koneksi atau coba buka kembali aplikasi.',
                    style: AppText.bodySm.c(p.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _start,
                    child: const Text('Coba Lagi'),
                  ),
                ],
                const SizedBox(height: 12),
                Text('Versi ${AppConfig.appVersion}',
                    style: AppText.caption.c(p.textTertiary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
