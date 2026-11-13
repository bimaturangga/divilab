import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import 'personal_data_screen.dart';
import 'step_header.dart';

/// Registrasi langkah 2: verifikasi email dengan OTP.
/// Tidak ada server email pada technical test ini, jadi kode OTP dibuat
/// di perangkat dan ditampilkan sebagai "mode demo".
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.draft});
  final RegistrationDraft draft;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  late String _otp;
  int _secondsLeft = 0;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _error = null));
    _send();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _send() {
    _otp = (100000 + Random.secure().nextInt(900000)).toString();
    _secondsLeft = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _verify() {
    if (_ctrl.text != _otp) {
      setState(() => _error = 'Kode OTP salah. Periksa kembali kode yang dikirim.');
      return;
    }
    push(context, PersonalDataScreen(draft: widget.draft));
  }

  String get _timeLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final code = _ctrl.text;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StepHeader(step: 2, title: 'Verifikasi Email', subtitle: 'Kode OTP'),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: AppText.body.c(p.textSecondary),
                              children: [
                                const TextSpan(text: 'Kami telah mengirim 6 digit kode OTP ke '),
                                TextSpan(text: widget.draft.email, style: AppText.title.c(p.textPrimary)),
                                const TextSpan(text: '. Periksa kotak masuk atau folder spam Anda.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          NoteBox(text: 'Mode demo: kode OTP Anda $_otp', icon: Icons.key_rounded),
                          const SizedBox(height: 20),
                          Text('Kode Verifikasi', style: AppText.label.c(p.textPrimary)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _focus.requestFocus(),
                            child: Stack(
                              children: [
                                Row(
                                  children: [
                                    for (var i = 0; i < 6; i++) ...[
                                      if (i > 0) const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          height: 52,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: i < code.length ? p.bgSurface : p.bgSubtle,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _error != null
                                                  ? p.danger
                                                  : (i == code.length ? p.primary : p.borderDefault),
                                              width: i == code.length ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Text(i < code.length ? code[i] : '', style: AppText.h2.c(p.textPrimary)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                // TextField tak terlihat yang menerima input angka.
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0,
                                    child: TextField(
                                      controller: _ctrl,
                                      focusNode: _focus,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      autofillHints: const [AutofillHints.oneTimeCode],
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: const InputDecoration(counterText: ''),
                                      showCursor: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!, style: AppText.caption.c(p.danger)),
                          ],
                          const SizedBox(height: 16),
                          if (_secondsLeft > 0)
                            Text.rich(
                              TextSpan(
                                style: AppText.bodySm.c(p.textSecondary),
                                children: [
                                  const TextSpan(text: 'Kode dapat dikirim ulang dalam '),
                                  TextSpan(text: _timeLabel, style: AppText.label.c(p.danger)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: p.borderDefault),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text('Tidak menerima kode OTP?', style: AppText.bodySm.c(p.textSecondary))),
                                OutlinedButton(
                                  onPressed: _secondsLeft > 0
                                      ? null
                                      : () {
                                          _ctrl.clear();
                                          setState(_send);
                                        },
                                  style: OutlinedButton.styleFrom(
                                    shape: const StadiumBorder(),
                                    side: BorderSide(color: p.borderDefault),
                                  ),
                                  child: Text(
                                    'Kirim ulang',
                                    style: AppText.label.c(_secondsLeft > 0 ? p.textTertiary : p.primary),
                                  ),
                                ),
                              ],
                            ),
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
              child: AppButton(label: 'Verifikasi', onPressed: code.length == 6 ? _verify : null),
            ),
          ],
        ),
      ),
    );
  }
}
