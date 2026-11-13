import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../state/app_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/brand.dart';
import '../../widgets/language_sheet.dart';
import 'register_screen.dart';
import 'sync_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _emailError = Validators.email(_email.text);
      _passwordError = _password.text.isEmpty ? 'Password wajib diisi' : null;
    });
    if (_emailError != null || _passwordError != null) return;
    setState(() => _loading = true);
    try {
      await context.read<AppState>().login(_email.text, _password.text);
      if (!mounted) return;
      goRoot(context, const SyncScreen());
    } on AuthException catch (e) {
      setState(() => _passwordError = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _useDemo() {
    _email.text = AppConfig.demoEmail;
    _password.text = AppConfig.demoPassword;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
  }

  void _forgotPassword() {
    final ctrl = TextEditingController(text: _email.text);
    showAppSheet<void>(
      context,
      builder: (ctx) {
        final p = ctx.palette;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHeader(title: 'Lupa Password'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Masukkan email akun Anda. Kami akan mengirim tautan untuk mengatur ulang password.',
                        style: AppText.body.c(p.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(label: 'Email', controller: ctrl, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'Kirim Tautan',
                        onPressed: () async {
                          final exists = await context.read<AppState>().auth.emailExists(ctrl.text);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          showSnack(
                            context,
                            exists
                                ? 'Tautan reset password dikirim ke ${ctrl.text.trim()} (simulasi)'
                                : 'Email belum terdaftar',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: p.textPrimary),
                    ),
                  const Spacer(),
                  const LanguageChip(),
                ],
              ),
              const SizedBox(height: 24),
              const Center(child: DiviLogo(width: 140)),
              const SizedBox(height: 28),
              Text('Masuk ke Akun', style: AppText.h1.c(p.textPrimary)),
              const SizedBox(height: 4),
              Text('Pantau kesehatan Anda dan keluarga dalam satu aplikasi.', style: AppText.body.c(p.textSecondary)),
              const SizedBox(height: 20),
              AutofillGroup(
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Email',
                      hint: 'Masukkan email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      suffixIcon: Icons.mail_outline_rounded,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      hint: 'Masukkan password',
                      controller: _password,
                      password: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      errorText: _passwordError,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: Text('Lupa Password?', style: AppText.title.c(p.primary)),
                ),
              ),
              const SizedBox(height: 8),
              AppButton(label: 'Masuk', loading: _loading, onPressed: _submit),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _useDemo,
                  icon: Icon(Icons.bolt_rounded, size: 18, color: p.textSecondary),
                  label: Text('Gunakan akun demo', style: AppText.label.c(p.textSecondary)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: AppText.body.c(p.textSecondary),
                    children: [
                      const TextSpan(text: 'Belum punya akun? '),
                      TextSpan(
                        text: 'Registrasi',
                        style: AppText.title.c(p.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
