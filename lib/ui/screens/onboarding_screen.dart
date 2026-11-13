import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/brand.dart';
import '../widgets/language_sheet.dart';
import 'auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    ('Lebih dari Sekedar Hasil',
        'Kesehatan bukan hanya tentang nilai saat ini, tetapi perjalanan menuju masa depan yang lebih baik.'),
    ('Pengingat & Konsistensi Sehat',
        'Mulai dari pengingat tepat waktu hingga sistem streak, bantu diri Anda tetap konsisten dalam pemeriksaan rutin.'),
    ('Koneksi Otomatis & Praktis',
        'Hubungkan perangkat dengan mudah. Terintegrasi otomatis melalui Bluetooth untuk pengalaman tanpa ribet.'),
    ('Terhubung dengan Orang Terdekat',
        'Pantau kesehatan lebih tenang bersama keluarga atau pendamping. Hasil pengukuran dapat dipantau secara real-time.'),
    ('Prediksi Kesehatan dengan AI', 'Teknologi AI membantu memprediksi kondisi kesehatan Anda di masa depan.'),
  ];

  bool get _isLast => _page == _pages.length - 1;

  Future<void> _finish() async {
    await context.read<AppState>().completeOnboarding();
    if (!mounted) return;
    goRoot(context, const WelcomeScreen());
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const LanguageChip(),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Material(
                      color: p.bgMuted,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: _isLast ? null : _finish,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Text('Lewati', style: AppText.label.c(p.textPrimary)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                        clipBehavior: Clip.antiAlias,
                        child: AspectRatio(
                          aspectRatio: 750 / 534,
                          child: Image.asset('assets/images/onboarding_${i + 1}.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Text(_pages[i].$1, style: AppText.h1.c(p.textPrimary), textAlign: TextAlign.center),
                            const SizedBox(height: 10),
                            Text(_pages[i].$2, style: AppText.body.c(p.textSecondary), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var d = 0; d < _pages.length; d++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: d == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: d == _page ? p.primary : p.borderStrong,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: AppButton(label: _isLast ? 'Mulai' : 'Lanjut', onPressed: _next),
            ),
          ],
        ),
      ),
    );
  }
}
