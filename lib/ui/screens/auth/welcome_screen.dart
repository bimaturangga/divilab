import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../widgets/app_button.dart';
import '../../widgets/brand.dart';
import '../settings/terms_sheet.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: h * 0.56,
            child: Image.asset('assets/images/welcome.png', fit: BoxFit.cover, alignment: Alignment.topCenter),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: p.bgCanvas,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DiviLogo(width: 150),
                    const SizedBox(height: 16),
                    Text(
                      'Langkah Kecil untuk\nHidup Lebih Sehat.',
                      style: AppText.h2.c(p.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    AppButton(label: 'Daftar akun', onPressed: () => push(context, const RegisterScreen())),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Saya sudah punya akun',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => push(context, const LoginScreen()),
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        style: AppText.caption.c(p.textSecondary),
                        children: [
                          const TextSpan(text: 'Dengan melanjutkan, Anda setuju dengan '),
                          TextSpan(
                            text: 'Syarat dan Ketentuan',
                            style: AppText.labelSm.c(p.primary),
                            recognizer: TapGestureRecognizer()..onTap = () => showTermsSheet(context),
                          ),
                          const TextSpan(text: ' yang ada di aplikasi DiViLab.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
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
}
