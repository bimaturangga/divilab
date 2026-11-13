import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/profile.dart';
import '../../../state/app_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/common.dart';
import '../accounts/account_list_screen.dart';

/// Sheet pilih profil (dipakai untuk "Ganti Akun" di Beranda dan "Pilih Pasien").
Future<void> showSwitchAccountSheet(BuildContext context, {String title = 'Ganti Akun'}) {
  return showAppSheet<void>(context, builder: (_) => _ProfilePickerSheet(title: title));
}

class _ProfilePickerSheet extends StatefulWidget {
  const _ProfilePickerSheet({required this.title});
  final String title;

  @override
  State<_ProfilePickerSheet> createState() => _ProfilePickerSheetState();
}

class _ProfilePickerSheetState extends State<_ProfilePickerSheet> {
  int? _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = context.read<AppState>().activeProfile?.id;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.watch<AppState>();
    final list = app.profiles.where((e) => e.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: widget.title, center: true),
            if (app.profiles.length > 6) ...[
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cari nama…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  fillColor: p.bgSubtle,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ProfileTile(
                  profile: list[i],
                  selected: list[i].id == _selected,
                  onTap: () => setState(() => _selected = list[i].id),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Terapkan',
              onPressed: () {
                final chosen = app.profiles.firstWhere((e) => e.id == _selected, orElse: () => app.profiles.first);
                app.switchProfile(chosen);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                final nav = Navigator.of(context);
                nav.pop();
                nav.push(MaterialPageRoute<void>(builder: (_) => const AccountListScreen()));
              },
              icon: Icon(Icons.swap_horiz_rounded, color: p.primary, size: 18),
              label: Text('Lihat semua akun', style: AppText.label.c(p.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile, required this.selected, required this.onTap});
  final Profile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: selected ? p.primary50 : p.bgSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: selected ? BorderSide(color: p.primary) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              InitialsAvatar(initials: profile.initials, color: p.avatarColors[profile.colorIndex % 6]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: AppText.title.c(p.textPrimary)),
                    const SizedBox(height: 2),
                    Text(profile.subtitle, style: AppText.caption.c(selected ? p.primary : p.textSecondary)),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? p.primary : p.borderStrong, width: selected ? 6 : 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
