import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../state/app_state.dart';
import '../../../state/ui_controllers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../../widgets/language_sheet.dart';
import '../accounts/account_list_screen.dart';
import '../auth/personal_data_screen.dart';
import '../auth/welcome_screen.dart';
import '../home/switch_account_sheet.dart';
import '../measure/select_device_screen.dart';
import '../notification/notification_screen.dart';
import 'terms_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showAppDialog<bool>(
      context,
      builder: (ctx) {
        final p = ctx.palette;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, size: 40, color: p.danger),
              const SizedBox(height: 12),
              Text('Keluar dari akun?', style: AppText.h2.c(p.textPrimary)),
              const SizedBox(height: 6),
              Text('Data tetap tersimpan di perangkat ini.', style: AppText.body.c(p.textSecondary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: AppButton(label: 'Batal', variant: AppButtonVariant.secondary, onPressed: () => Navigator.pop(ctx, false))),
                  const SizedBox(width: 10),
                  Expanded(child: AppButton(label: 'Keluar', variant: AppButtonVariant.danger, onPressed: () => Navigator.pop(ctx, true))),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (ok != true || !context.mounted) return;
    context.read<DeviceController>().disconnect();
    context.read<ShellController>().go(0);
    await context.read<AppState>().logout();
    if (context.mounted) goRoot(context, const WelcomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.watch<AppState>();
    final user = app.user;
    void soon(String f) => showSnack(context, '$f akan tersedia di versi berikutnya');

    final items = <_MenuItem>[
      _MenuItem(Icons.group_outlined, 'Anggota Keluarga', onTap: () => showSwitchAccountSheet(context, title: 'Anggota Keluarga')),
      _MenuItem(Icons.admin_panel_settings_outlined, 'Hak Akses Relasi', onTap: () => soon('Hak akses relasi')),
      _MenuItem(Icons.notifications_none_rounded, 'Notifikasi', onTap: () => push(context, const NotificationScreen())),
      _MenuItem(Icons.devices_other_outlined, 'Perangkat & Inventori', onTap: () => push(context, const SelectDeviceScreen())),
      _MenuItem(Icons.swap_horiz_rounded, 'Ganti Akun', badge: 'API', onTap: () => push(context, const AccountListScreen())),
      _MenuItem(Icons.verified_outlined, 'Garansi', onTap: () => soon('Klaim garansi')),
      _MenuItem(Icons.play_circle_outline_rounded, 'Video Tutorial', onTap: () => soon('Video tutorial')),
      _MenuItem(Icons.translate_rounded, 'Bahasa', value: 'Indonesia', onTap: () => showLanguageSheet(context)),
      _MenuItem(
        Icons.dark_mode_outlined,
        'Mode Gelap',
        trailing: AppSwitch(value: app.themeMode == ThemeMode.dark, onChanged: app.setDarkMode),
        onTap: () => app.setDarkMode(app.themeMode != ThemeMode.dark),
      ),
      _MenuItem(Icons.description_outlined, 'Syarat & Ketentuan', onTap: () => showTermsSheet(context)),
      _MenuItem(Icons.logout_rounded, 'Keluar Akun', danger: true, onTap: () => _logout(context)),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Text('Pengaturan', style: AppText.h1.c(p.textPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  InitialsAvatar(
                    initials: app.profiles.isEmpty ? '?' : app.profiles.first.initials,
                    color: p.primary100,
                    textColor: p.primary,
                    size: 56,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '-', style: AppText.h3.c(p.textPrimary)),
                        Text(
                          [user?.gender ?? '', if (user?.age != null) '${user!.age} tahun'].join(' · '),
                          style: AppText.caption.c(p.textSecondary),
                        ),
                        Text(user?.email ?? '', style: AppText.caption.c(p.textTertiary)),
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(99),
                          onTap: () => push(context, const PersonalDataScreen()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: p.primary)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Ubah Profil', style: AppText.labelSm.c(p.primary)),
                                const SizedBox(width: 4),
                                Icon(Icons.edit_outlined, size: 12, color: p.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final item in items) _MenuRow(item: item),
            const SizedBox(height: 16),
            Text('Versi ${AppConfig.appVersion}', style: AppText.caption.c(p.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, {required this.onTap, this.value, this.badge, this.trailing, this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? value;
  final String? badge;
  final Widget? trailing;
  final bool danger;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = item.danger ? p.danger : p.textPrimary;
    return InkWell(
      onTap: item.onTap,
      child: Container(
        height: 52,
        decoration: item.danger ? null : bottomDivider(context),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(item.label, style: AppText.body.c(color))),
            if (item.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(99)),
                child: Text(item.badge!, style: AppText.labelSm.c(p.textOnPrimary)),
              ),
            if (item.value != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(item.value!, style: AppText.bodySm.c(p.textTertiary)),
              ),
            if (item.trailing != null)
              item.trailing!
            else if (!item.danger)
              Icon(Icons.chevron_right_rounded, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}
