import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../state/ui_controllers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import 'connect_device_screen.dart';
import 'device_guide_sheet.dart';
import 'measurement_screen.dart';

class SelectDeviceScreen extends StatelessWidget {
  const SelectDeviceScreen({super.key});

  Future<void> _addDevice(BuildContext context) async {
    final ctrl = TextEditingController();
    final code = await showAppSheet<String>(
      context,
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(title: 'Tambah Perangkat Baru'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Kode Produksi',
                      hint: 'Contoh: DVIBGCU26011900Z2',
                      controller: ctrl,
                      helper: Text(
                        'Kode tertera pada stiker di bagian belakang perangkat atau kemasan.',
                        style: AppText.caption.c(ctx.palette.textTertiary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Tambahkan',
                      onPressed: () {
                        if (ctrl.text.trim().length < 6) return;
                        Navigator.pop(ctx, ctrl.text);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (code != null && context.mounted) {
      context.read<DeviceController>().addDevice(code);
      showSnack(context, 'Perangkat ditambahkan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ctrl = context.watch<DeviceController>();
    return Scaffold(
      appBar: AppTopBar(
        title: 'Pilih Perangkat',
        actions: [CircleIconButton(icon: Icons.menu_book_outlined, tooltip: 'Panduan', onTap: () => showDeviceGuide(context))],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: ctrl.devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final d = ctrl.devices[i];
                final on = ctrl.isConnected(d);
                return Material(
                  color: p.bgSubtle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: on ? p.primary : p.borderDefault, width: on ? 1.5 : 1),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => push<void>(context, on ? MeasurementScreen(device: d) : ConnectDeviceScreen(device: d)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: Image.asset(d.asset, fit: BoxFit.contain),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.name, style: AppText.title.c(p.textPrimary)),
                                const SizedBox(height: 3),
                                Text('Kode: ${d.code}', style: AppText.caption.c(p.textTertiary)),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: on ? p.success : p.danger, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(on ? 'Terhubung' : 'Alat belum terhubung', style: AppText.caption.c(on ? p.success : p.danger)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: p.textSecondary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  AppButton(label: 'Tambah perangkat baru', onPressed: () => _addDevice(context)),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Kembali ke halaman utama',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
