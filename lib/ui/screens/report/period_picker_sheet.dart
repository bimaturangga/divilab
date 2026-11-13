import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_fmt.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';

/// Sheet "Pilih Periode" dengan kalender rentang tanggal.
Future<DateTimeRange?> showPeriodPicker(BuildContext context, {DateTimeRange? initial}) {
  return showAppSheet<DateTimeRange>(context, builder: (_) => _PeriodPicker(initial: initial));
}

class _PeriodPicker extends StatefulWidget {
  const _PeriodPicker({this.initial});
  final DateTimeRange? initial;

  @override
  State<_PeriodPicker> createState() => _PeriodPickerState();
}

class _PeriodPickerState extends State<_PeriodPicker> {
  late DateTime _month;
  DateTime? _start;
  DateTime? _end;
  int? _quick = 1;

  DateTime get _today => DateFmt.startOfDay(DateTime.now());

  @override
  void initState() {
    super.initState();
    final init = widget.initial ?? DateTimeRange(start: _today.subtract(const Duration(days: 6)), end: _today);
    _start = DateFmt.startOfDay(init.start);
    _end = DateFmt.startOfDay(init.end);
    _month = DateTime(_end!.year, _end!.month);
  }

  void _applyQuick(int i) {
    const days = [1, 7, 30, 90];
    setState(() {
      _quick = i;
      _end = _today;
      _start = _today.subtract(Duration(days: days[i] - 1));
      _month = DateTime(_today.year, _today.month);
    });
  }

  void _tap(DateTime d) {
    if (d.isAfter(_today)) return;
    setState(() {
      _quick = null;
      if (_start == null || _end != null) {
        _start = d;
        _end = null;
      } else if (d.isBefore(_start!)) {
        _start = d;
      } else {
        _end = d;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final cells = <DateTime?>[
      for (var i = 0; i < offset; i++) null,
      for (var d = 1; d <= daysInMonth; d++) DateTime(_month.year, _month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final end = _end ?? _start;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader(title: 'Pilih Periode'),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < 4; i++)
                  ChoiceChip(
                    label: Text(const ['Hari ini', '7 hari', '30 hari', '3 bulan'][i]),
                    selected: _quick == i,
                    onSelected: (_) => _applyQuick(i),
                    showCheckmark: false,
                    labelStyle: AppText.label.c(_quick == i ? p.primary : p.textSecondary),
                    selectedColor: p.primary50,
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: _quick == i ? p.primary : p.borderStrong),
                    shape: const StadiumBorder(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                  icon: Icon(Icons.chevron_left_rounded, color: p.textSecondary),
                ),
                Expanded(child: Text(DateFmt.monthYear(_month), style: AppText.title.c(p.textPrimary), textAlign: TextAlign.center)),
                IconButton(
                  onPressed: DateTime(_month.year, _month.month + 1).isAfter(_today)
                      ? null
                      : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                  icon: Icon(Icons.chevron_right_rounded, color: p.textSecondary),
                ),
              ],
            ),
            Row(
              children: [
                for (final d in DateFmt.daysShort)
                  Expanded(child: Center(child: Text(d, style: AppText.caption.c(p.textTertiary)))),
              ],
            ),
            const SizedBox(height: 6),
            for (var r = 0; r < cells.length ~/ 7; r++)
              Row(
                children: [
                  for (var c = 0; c < 7; c++) Expanded(child: _cell(cells[r * 7 + c], end)),
                ],
              ),
            const SizedBox(height: 10),
            if (_start != null)
              Text(
                '${DateFmt.dateShort(_start!)} – ${DateFmt.dateShort(end!)} · ${end.difference(_start!).inDays + 1} hari',
                style: AppText.label.c(p.textSecondary),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Terapkan',
              onPressed: _start == null
                  ? null
                  : () => Navigator.pop(
                        context,
                        DateTimeRange(start: _start!, end: DateFmt.endOfDay(end!)),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(DateTime? d, DateTime? end) {
    final p = context.palette;
    if (d == null) return const SizedBox(height: 40);
    final start = _start;
    final isStart = start != null && d == start;
    final isEnd = end != null && d == end;
    final inRange = start != null && end != null && !d.isBefore(start) && !d.isAfter(end);
    final future = d.isAfter(_today);
    final edge = isStart || isEnd;
    return GestureDetector(
      onTap: () => _tap(d),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: inRange ? p.primary50 : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isStart ? const Radius.circular(20) : Radius.zero,
            right: isEnd ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: edge ? p.primary : Colors.transparent, shape: BoxShape.circle),
          child: Text(
            '${d.day}',
            style: (edge ? AppText.title : AppText.body).c(
              edge ? p.textOnPrimary : (future ? p.textTertiary : p.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
