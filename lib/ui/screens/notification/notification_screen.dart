import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_fmt.dart';
import '../../../data/models/reminder.dart';
import '../../../state/app_state.dart';
import '../../../state/health_store.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import 'reminder_form_screen.dart';
import 'reminder_templates_screen.dart';

/// Notifikasi: tab Pengingat & Pesan.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late int _tab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    if (_tab == 1) WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  void _markRead() => context.read<HealthStore>().markMessagesRead();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.watch<AppState>();
    final store = context.watch<HealthStore>();
    return Scaffold(
      appBar: const AppTopBar(title: 'Notifikasi'),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              heroTag: 'add-reminder',
              onPressed: () => push(context, const ReminderTemplatesScreen()),
              backgroundColor: p.primary,
              foregroundColor: p.textOnPrimary,
              icon: const Icon(Icons.add_rounded),
              label: Text('Tambah Pengingat', style: AppText.button.c(p.textOnPrimary)),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.notifications_none_rounded, size: 20, color: p.textPrimary),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Push Notifikasi', style: AppText.title.c(p.textPrimary))),
                  AppSwitch(value: app.pushEnabled, onChanged: app.setPushEnabled),
                ],
              ),
            ),
          ),
          Container(
            decoration: bottomDivider(context),
            child: Row(
              children: [
                _tabButton('Pengingat', 0, null),
                _tabButton('Pesan', 1, store.unreadCount),
              ],
            ),
          ),
          Expanded(child: _tab == 0 ? _reminders(store) : _messages(store)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int i, int? count) {
    final p = context.palette;
    final on = _tab == i;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _tab = i);
          if (i == 1) _markRead();
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: on ? p.primary : Colors.transparent, width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: (on ? AppText.title : AppText.body).c(on ? p.primary : p.textTertiary)),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(9)),
                  child: Text('$count', style: AppText.labelSm.c(p.textOnPrimary)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _reminders(HealthStore store) {
    final p = context.palette;
    if (store.reminders.isEmpty) {
      return _empty(Icons.alarm_off_rounded, 'Belum ada pengingat', 'Tambahkan pengingat agar pengukuran tetap rutin.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: store.reminders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = store.reminders[i];
        return Dismissible(
          key: ValueKey('reminder-${r.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: p.danger, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          onDismissed: (_) {
            store.deleteReminder(r);
            showSnack(context, 'Pengingat "${r.title}" dihapus');
          },
          child: _ReminderTile(reminder: r),
        );
      },
    );
  }

  Widget _messages(HealthStore store) {
    final p = context.palette;
    if (store.messages.isEmpty) {
      return _empty(Icons.mark_email_read_outlined, 'Belum ada pesan', 'Pesan muncul saat ada hasil di luar normal atau strip hampir habis.');
    }
    return ListView.builder(
      itemCount: store.messages.length,
      itemBuilder: (_, i) {
        final m = store.messages[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: bottomDivider(context).copyWith(color: m.read ? null : p.primary50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!m.read) ...[
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(m.title, style: AppText.title.c(p.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(DateFmt.dateShort(m.createdAt), style: AppText.caption.c(p.textTertiary)),
                ],
              ),
              const SizedBox(height: 4),
              Text(m.body, style: AppText.bodySm.c(p.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Widget _empty(IconData icon, String title, String body) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: p.textTertiary),
            const SizedBox(height: 12),
            Text(title, style: AppText.h3.c(p.textPrimary)),
            const SizedBox(height: 4),
            Text(body, style: AppText.bodySm.c(p.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder});
  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final store = context.read<HealthStore>();
    return Material(
      color: p.bgSubtle,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => push(context, ReminderFormScreen(existing: reminder)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: p.primary50, shape: BoxShape.circle),
                child: Icon(Icons.alarm_rounded, size: 18, color: p.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.title, style: AppText.title.c(p.textPrimary)),
                    const SizedBox(height: 2),
                    Text(reminder.scheduleLabel, style: AppText.caption.c(p.textSecondary)),
                  ],
                ),
              ),
              AppSwitch(value: reminder.enabled, onChanged: (v) => store.toggleReminder(reminder, v)),
            ],
          ),
        ),
      ),
    );
  }
}
