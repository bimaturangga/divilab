import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../state/ui_controllers.dart';
import '../../widgets/brand.dart';
import '../assistant/assistant_screen.dart';
import '../home/home_screen.dart';
import '../measure/add_measurement_sheet.dart';
import '../product/product_screen.dart';
import '../report/report_screen.dart';
import '../settings/settings_screen.dart';

/// Kerangka utama: bottom navigation + tombol + (tambah pengukuran)
/// + tombol bulat Tanya Asisten di Beranda & Laporan.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _tabs = [
    ('Beranda', Icons.home_outlined, Icons.home_rounded),
    ('Laporan', Icons.assignment_outlined, Icons.assignment_rounded),
    ('Produk', Icons.shopping_bag_outlined, Icons.shopping_bag_rounded),
    ('Pengaturan', Icons.settings_outlined, Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shell = context.watch<ShellController>();
    final index = shell.index;
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: index,
            children: const [HomeScreen(), ReportScreen(), ProductScreen(), SettingsScreen()],
          ),
          if (index <= 1)
            Positioned(
              right: 16,
              bottom: 16,
              child: AssistantFab(onTap: () => push(context, const AssistantScreen())),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _RoundFab(
        heroTag: 'add-measurement',
        icon: Icons.add_rounded,
        tooltip: 'Tambah pengukuran',
        onTap: () => showAddMeasurementSheet(context),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: p.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [BoxShadow(color: Color(0x14101828), blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i == 2) const SizedBox(width: 72),
                  Expanded(
                    child: InkWell(
                      onTap: () => shell.go(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            i == index ? _tabs[i].$3 : _tabs[i].$2,
                            color: i == index ? p.primary : p.textTertiary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tabs[i].$1,
                            style: (i == index ? AppText.labelSm : AppText.caption)
                                .c(i == index ? p.primary : p.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundFab extends StatelessWidget {
  const _RoundFab({required this.icon, required this.onTap, required this.heroTag, this.tooltip, this.iconSize = 30});
  final IconData icon;
  final VoidCallback onTap;
  final Object heroTag;
  final String? tooltip;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: p.bgCanvas, width: 3),
        boxShadow: [BoxShadow(color: p.primary.withAlpha(90), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onTap,
        tooltip: tooltip,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: p.primary,
        foregroundColor: p.textOnPrimary,
        shape: const CircleBorder(),
        child: Icon(icon, size: iconSize),
      ),
    );
  }
}

/// Tombol bulat Tanya Asisten (ikon saja, menonjol seperti tombol +).
class AssistantFab extends StatelessWidget {
  const AssistantFab({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _RoundFab(
        heroTag: 'assistant',
        icon: Icons.smart_toy_outlined,
        iconSize: 26,
        tooltip: 'Tanya Asisten',
        onTap: onTap,
      );
}
