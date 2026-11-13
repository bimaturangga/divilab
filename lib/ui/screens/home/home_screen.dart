import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/health.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_fmt.dart';
import '../../../data/models/catalog.dart';
import '../../../data/models/measurement.dart';
import '../../../state/app_state.dart';
import '../../../state/health_store.dart';
import '../../../state/ui_controllers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../measure/connect_device_screen.dart';
import '../measure/measurement_screen.dart';
import '../notification/notification_screen.dart';
import 'measurement_detail_screen.dart';
import 'switch_account_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pager = PageController();
  int _devicePage = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.watch<AppState>();
    final store = context.watch<HealthStore>();
    final devices = context.watch<DeviceController>();
    final profile = app.activeProfile;
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: store.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Stack(
              children: [
                // Header biru dengan dekorasi lingkaran.
                Container(
                  height: 236 + top,
                  color: p.bgHeader,
                  child: Stack(
                    children: [
                      Positioned(right: -60, top: -60, child: _circle(220)),
                      Positioned(left: -80, top: 120 + top, child: _circle(200)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    SizedBox(height: top + 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => showSwitchAccountSheet(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: Text(profile?.initials ?? '?', style: AppText.title.c(p.primary)),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                profile?.name ?? '-',
                                                style: AppText.title.c(Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(profile?.relation ?? '', style: AppText.caption.c(Colors.white)),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(99),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(color: p.success, shape: BoxShape.circle),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text('Online', style: AppText.labelSm.c(p.success)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          CircleIconButton(
                            icon: Icons.alarm_rounded,
                            size: 38,
                            background: Colors.white.withAlpha(46),
                            color: Colors.white,
                            tooltip: 'Pengingat',
                            onTap: () => push(context, const NotificationScreen()),
                          ),
                          const SizedBox(width: 8),
                          CircleIconButton(
                            icon: Icons.notifications_none_rounded,
                            size: 38,
                            background: Colors.white.withAlpha(46),
                            color: Colors.white,
                            badge: store.unreadCount > 0,
                            tooltip: 'Notifikasi',
                            onTap: () => push(context, const NotificationScreen(initialTab: 1)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _StatsCard(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: p.bgCanvas,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 172,
                            child: PageView(
                              controller: _pager,
                              onPageChanged: (i) => setState(() => _devicePage = i),
                              children: [
                                for (final d in devices.devices.take(2)) _DeviceCard(device: d),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < 2; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: i == _devicePage ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == _devicePage ? p.primary : p.borderStrong,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                            ],
                          ),
                          if (!devices.isConnected(devices.devices[_devicePage > 1 ? 1 : _devicePage])) ...[
                            const SizedBox(height: 12),
                            NoteBox(
                              text: 'Nyalakan perangkat ${devices.devices[_devicePage > 1 ? 1 : _devicePage].name} '
                                  'dan aktifkan Bluetooth sebelum mengukur.',
                            ),
                          ],
                          const SizedBox(height: 16),
                          SectionHeader(
                            title: 'Hasil pengukuran terakhir',
                            action: 'Lihat semua',
                            onAction: () => context.read<ShellController>().go(1),
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.98,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            children: [
                              for (final t in MeasurementType.values) _MetricCard(type: t, m: store.latest(t)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const _HelpCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circle(double d) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(color: Colors.white.withAlpha(18), shape: BoxShape.circle),
      );
}

class _StatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final count = context.watch<HealthStore>().measurements.length;
    final items = [
      (Icons.star_rounded, p.warning, 'Poin', '${count * 10}'),
      (Icons.confirmation_number_outlined, p.primary, 'Voucher', '1'),
      (Icons.verified_outlined, p.info, 'Member', 'Blue'),
    ];
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x140D1A33), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(width: 1, height: 32, color: p.borderDefault),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].$1, size: 14, color: items[i].$2),
                      const SizedBox(width: 4),
                      Text(items[i].$3, style: AppText.caption.c(p.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(items[i].$4, style: AppText.h3.c(i == 2 ? p.primary : p.textPrimary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});
  final DeviceInfo device;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ctrl = context.watch<DeviceController>();
    final connected = ctrl.isConnected(device);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Image.asset(device.asset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: AppText.h3.c(p.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Kode: ${device.code}', style: AppText.caption.c(p.textTertiary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: connected ? p.success : p.danger, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          connected ? 'Alat sudah terhubung' : 'Alat belum terhubung',
                          style: AppText.caption.c(connected ? p.success : p.danger),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Ukur Sekarang',
            height: 40,
            onPressed: () => push(
              context,
              connected ? MeasurementScreen(device: device) : ConnectDeviceScreen(device: device),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.type, required this.m});
  final MeasurementType type;
  final Measurement? m;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = m;
    return Material(
      color: p.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.borderDefault),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: data == null ? null : () => push(context, MeasurementDetailScreen(measurement: data)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MetricIcon(type: type, size: 28),
                  const SizedBox(width: 8),
                  Expanded(child: Text(type.label, style: AppText.label.c(p.textPrimary), overflow: TextOverflow.ellipsis)),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(data?.displayValue ?? '--', style: AppText.h1.c(p.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(type.unit, style: AppText.caption.c(p.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              StatusBadge(status: data?.status),
              const SizedBox(height: 6),
              Text(
                data == null ? 'Belum ada pengukuran' : DateFmt.dateTime(data.measuredAt),
                style: AppText.caption.c(p.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  static const csNumber = '+62 811-0000-1234';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: p.borderDefault)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.headset_mic_outlined, color: p.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Butuh bantuan?', style: AppText.title.c(p.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      'Tim kami siap membantu kendala perangkat maupun aplikasi Anda.',
                      style: AppText.caption.c(p.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Chat CS via WhatsApp',
            icon: Icons.chat_outlined,
            variant: AppButtonVariant.success,
            height: 40,
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: csNumber));
              showSnack(context, 'Nomor WhatsApp CS ($csNumber) disalin');
            },
          ),
        ],
      ),
    );
  }
}
