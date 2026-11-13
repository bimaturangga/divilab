import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../state/app_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import 'step_header.dart';
import 'verify_email_screen.dart';

/// Registrasi langkah 1: email & password.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_email, _password, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _filled => _email.text.isNotEmpty && _password.text.isNotEmpty && _confirm.text.isNotEmpty;

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _emailError = Validators.email(_email.text);
      _passwordError = Validators.password(_password.text);
      _confirmError = Validators.confirmPassword(_confirm.text, _password.text);
    });
    if (_emailError != null || _passwordError != null || _confirmError != null) return;
    setState(() => _checking = true);
    final exists = await context.read<AppState>().auth.emailExists(_email.text);
    if (!mounted) return;
    setState(() => _checking = false);
    if (exists) {
      setState(() => _emailError = 'Email sudah terdaftar, silakan masuk');
      return;
    }
    push(context, VerifyEmailScreen(draft: RegistrationDraft(email: _email.text.trim(), password: _password.text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StepHeader(step: 1, title: 'Buat Akun', subtitle: 'Daftar untuk memulai'),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          AppTextField(
                            label: 'Email',
                            hint: 'Masukkan email',
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            errorText: _emailError,
                          ),
                          const SizedBox(height: 18),
                          AppTextField(
                            label: 'Password',
                            hint: 'Masukkan password',
                            controller: _password,
                            password: true,
                            textInputAction: TextInputAction.next,
                            errorText: _passwordError,
                            helper: PasswordRuleChips(rules: Validators.passwordRules(_password.text)),
                          ),
                          const SizedBox(height: 18),
                          AppTextField(
                            label: 'Konfirmasi password',
                            hint: 'Ulangi password',
                            controller: _confirm,
                            password: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _next(),
                            errorText: _confirmError,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: AppButton(label: 'Lanjut', loading: _checking, onPressed: _filled ? _next : null),
            ),
          ],
        ),
      ),
    );
  }
}
