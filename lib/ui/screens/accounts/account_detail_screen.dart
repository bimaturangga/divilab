import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/health.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/remote_user.dart';
import '../../../data/services/dummyjson_service.dart';
import '../../../state/app_state.dart';
import '../../../state/ui_controllers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/common.dart';
import 'remote_avatar.dart';

/// Detail Akun — GET dummyjson.com/users/{id}, lalu "Gunakan Akun Ini"
/// menyimpan akun sebagai profil di SQLite dan menjadikannya aktif.
class AccountDetailScreen extends StatefulWidget {
  const AccountDetailScreen({super.key, required this.user});
  final RemoteUser user;

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late RemoteUser _user = widget.user;
  bool _refreshing = true;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final fresh = await context.read<DummyJsonService>().fetchUser(widget.user.id);
      if (mounted) setState(() => _user = fresh);
    } on ApiException {
      // Tetap tampilkan data dari daftar bila detail gagal dimuat.
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _use() async {
    setState(() => _switching = true);
    final app = context.read<AppState>();
    final shell = context.read<ShellController>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final profile = await app.useRemoteAccount(_user);
    if (!mounted) return;
    shell.go(0);
    nav.popUntil((r) => r.isFirst);
    messenger.showSnackBar(SnackBar(content: Text('Sekarang memakai akun ${profile.name}')));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final u = _user;
    final bmi = u.bmi;
    final isActive = context.watch<AppState>().activeProfile?.remoteId == u.id;
    return Scaffold(
      appBar: AppTopBar(
        title: 'Detail Akun',
        actions: [
          if (_refreshing) const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Center(child: RemoteAvatar(user: u, size: 84)),
                const SizedBox(height: 10),
                Center(child: Text(u.fullName, style: AppText.h1.c(p.textPrimary))),
                Center(child: Text('@${u.username} · ID #${u.id} · dummyjson.com', style: AppText.bodySm.c(p.textSecondary))),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    _tag(u.genderLabel, p.danger, p.danger50),
                    _tag('${u.age} tahun', p.primary, p.primary50),
                    _tag('Gol. darah ${u.bloodGroup}', p.purple, p.purple50),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _stat('${fmtNum(u.height, decimals: 0)} cm', 'Tinggi'),
                    const SizedBox(width: 10),
                    _stat('${fmtNum(u.weight, decimals: 0)} kg', 'Berat'),
                    const SizedBox(width: 10),
                    _stat(bmi == null ? '-' : fmtNum(bmi), 'BMI'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: p.borderDefault)),
                  child: Column(
                    children: [
                      _info(Icons.mail_outline_rounded, 'Email', u.email),
                      _info(Icons.phone_outlined, 'Telepon', u.phone),
                      _info(Icons.cake_outlined, 'Tanggal lahir', u.birthDate),
                      _info(Icons.location_on_outlined, 'Alamat', u.address),
                      _info(Icons.work_outline_rounded, 'Pekerjaan', '${u.companyTitle} · ${u.companyName}', last: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: AppButton(
                label: isActive ? 'Akun Sedang Dipakai' : 'Gunakan Akun Ini',
                loading: _switching,
                onPressed: isActive ? null : _use,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String l, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Text(l, style: AppText.labelSm.c(fg)),
      );

  Widget _stat(String v, String label) {
    final p = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(v, style: AppText.title.c(p.textPrimary)),
            Text(label, style: AppText.caption.c(p.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String k, String v, {bool last = false}) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: last ? null : bottomDivider(context),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: p.primary50, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: p.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k, style: AppText.caption.c(p.textTertiary)),
                Text(v.isEmpty ? '-' : v, style: AppText.label.c(p.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
