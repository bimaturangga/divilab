import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config.dart';
import '../../../core/health.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_fmt.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/services/assistant_service.dart';
import '../../../state/app_state.dart';
import '../../../state/health_store.dart';
import '../../widgets/app_sheet.dart';

/// Tanya Asisten — chatbot kesehatan yang membaca data pengukuran user.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _typing = false;

  static const _suggestions = [
    'Bagaimana gula darah saya minggu ini?',
    'Apa arti kolesterol 200 mg/dL?',
    'Tips menurunkan asam urat secara alami',
    'Cara memasang strip di DiViLab Optima',
  ];

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  MeasurementType? _chartFor(String q) {
    final s = q.toLowerCase();
    if (s.contains('gula')) return MeasurementType.glucose;
    if (s.contains('kolesterol')) return MeasurementType.cholesterol;
    if (s.contains('urat')) return MeasurementType.uricAcid;
    if (s.contains('tekanan') || s.contains('tensi')) return MeasurementType.bloodPressure;
    return null;
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _typing) return;
    _input.clear();
    final app = context.read<AppState>();
    final store = context.read<HealthStore>();
    final service = context.read<AssistantService>();
    setState(() {
      _messages.add(_Msg(ChatMessage(text: text, fromUser: true)));
      _typing = true;
    });
    _scrollToEnd();
    final snapshot = HealthSnapshot(profileName: app.activeProfile?.name ?? 'Anda', measurements: store.measurements);
    final reply = await service.reply(history: _messages.map((m) => m.message).toList(), snapshot: snapshot);
    if (!mounted) return;
    final chart = _chartFor(text);
    setState(() {
      _typing = false;
      _messages.add(_Msg(
        ChatMessage(text: reply, fromUser: false),
        chartType: chart != null && snapshot.ofType(chart).isNotEmpty ? chart : null,
      ));
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = context.watch<AppState>().activeProfile?.name ?? '';
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        shape: Border(bottom: BorderSide(color: p.borderDefault)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: p.textPrimary),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: p.primary,
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asisten DiVi', style: AppText.title.c(p.textPrimary)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: p.success, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                      AppConfig.hasAssistantKey ? 'Online · Didukung AI' : 'Online · Mode offline',
                      style: AppText.caption.c(p.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Hapus percakapan',
            onPressed: _messages.isEmpty ? null : () => setState(_messages.clear),
            icon: Icon(Icons.delete_sweep_outlined, color: p.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _messages.isEmpty ? _welcome(name) : _conversation()),
          Container(
            decoration: BoxDecoration(color: p.bgCanvas, border: Border(top: BorderSide(color: p.borderDefault))),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          style: AppText.body.c(p.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Tulis pertanyaan…',
                            fillColor: p.bgSubtle,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: p.primary),
                            ),
                            suffixIcon: IconButton(
                              tooltip: 'Input suara',
                              onPressed: () => showSnack(context, 'Input suara akan tersedia di versi berikutnya'),
                              icon: const Icon(Icons.mic_none_rounded, size: 20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: _input.text.trim().isEmpty || _typing ? p.bgMuted : p.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _send(),
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: _input.text.trim().isEmpty || _typing ? p.textTertiary : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Asisten AI dapat keliru. Bukan pengganti konsultasi dokter.',
                    style: AppText.caption.c(p.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcome(String name) {
    final p = context.palette;
    final count = context.watch<HealthStore>().measurements.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: p.primary50, shape: BoxShape.circle),
            child: Icon(Icons.smart_toy_outlined, size: 36, color: p.primary),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text('Halo, ${name.split(' ').first}! 👋', style: AppText.h1.c(p.textPrimary))),
        const SizedBox(height: 6),
        Text(
          'Saya Asisten DiVi. Saya bisa menjelaskan hasil pengukuran Anda, memberi tips gaya hidup sehat, '
          'dan membantu menggunakan perangkat DiViLab.',
          style: AppText.body.c(p.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Icon(Icons.insights_rounded, color: p.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Terhubung dengan data Anda', style: AppText.title.c(p.textPrimary)),
                    Text(
                      'Asisten membaca $count hasil pengukuran yang tersimpan di perangkat.',
                      style: AppText.caption.c(p.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Coba tanyakan', style: AppText.label.c(p.textSecondary)),
        const SizedBox(height: 8),
        for (final s in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: p.borderDefault)),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _send(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(s, style: AppText.bodySm.c(p.textPrimary))),
                      Icon(Icons.north_east_rounded, size: 16, color: p.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _conversation() {
    final p = context.palette;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _messages.length + (_typing ? 1 : 0) + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: p.bgMuted, borderRadius: BorderRadius.circular(99)),
              child: Text('Hari ini, ${DateFmt.time(_messages.first.message.time)}', style: AppText.caption.c(p.textSecondary)),
            ),
          );
        }
        final idx = i - 1;
        if (idx >= _messages.length) return _bubble(null, typing: true);
        return _bubble(_messages[idx]);
      },
    );
  }

  Widget _bubble(_Msg? msg, {bool typing = false}) {
    final p = context.palette;
    final me = msg?.message.fromUser ?? false;
    final store = context.read<HealthStore>();
    final maxW = MediaQuery.of(context).size.width * 0.75;
    Widget content;
    if (typing) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in const [255, 160, 80])
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: p.textTertiary.withAlpha(a), shape: BoxShape.circle),
            ),
        ],
      );
    } else {
      final chartType = msg!.chartType;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg.message.text, style: AppText.body.c(me ? Colors.white : p.textPrimary)),
          if (chartType != null) ...[
            const SizedBox(height: 10),
            _miniChart(chartType, store),
          ],
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!me) ...[
            CircleAvatar(radius: 14, backgroundColor: p.primary, child: const Icon(Icons.smart_toy_outlined, size: 16, color: Colors.white)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxW),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: me ? p.primary : p.bgSubtle,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(me ? 18 : 4),
                  bottomRight: Radius.circular(me ? 4 : 18),
                ),
              ),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChart(MeasurementType t, HealthStore store) {
    final p = context.palette;
    final list = store.filter(type: t).take(7).toList().reversed.toList();
    if (list.isEmpty) return const SizedBox.shrink();
    final values = list.map((m) => m.value).toList();
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, size: 14, color: t.color(p)),
              const SizedBox(width: 6),
              Text('${t.label} · ${list.length} pengukuran terakhir', style: AppText.labelSm.c(p.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final m in list) ...[
                  Expanded(
                    child: Container(
                      height: maxV == 0 ? 4.0 : (m.value / maxV * 40).clamp(4.0, 40.0).toDouble(),
                      decoration: BoxDecoration(
                        color: m.status == HealthStatus.normal ? t.color(p) : p.danger,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Min ${fmtNum(minV)}', style: AppText.caption.c(p.textSecondary)),
              Text('Rata² ${fmtNum(avg)}', style: AppText.labelSm.c(p.textPrimary)),
              Text('Maks ${fmtNum(maxV)}', style: AppText.caption.c(p.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Msg {
  _Msg(this.message, {this.chartType});
  final ChatMessage message;
  final MeasurementType? chartType;
}
