import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';

/// GitHub-style calendar of a driver's daily collection: full, partial,
/// nothing or off. Columns are weeks, rows are weekdays (Sat → Fri, the
/// Bangladeshi work week).
class CollectionHeatmap extends StatelessWidget {
  const CollectionHeatmap({super.key, required this.days, required this.from, required this.to});
  final Map<DateTime, DayRecord> days;
  final DateTime from;
  final DateTime to;

  static int _row(DateTime d) => (d.weekday + 1) % 7; // Sat=0 … Fri=6

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.s;
    final byKey = {for (final e in days.entries) dbDate(e.key): e.value};
    final start = from.subtract(Duration(days: _row(from)));
    final weeks = (to.difference(start).inDays ~/ 7) + 1;

    Color colorFor(DateTime d) {
      if (d.isBefore(from) || d.isAfter(to)) return Colors.transparent;
      final r = byKey[dbDate(d)];
      if (r == null) return p.surfaceAlt;
      if (r.off && r.target == 0) return p.muted.withValues(alpha: 0.35);
      if (r.target <= 0 || r.amount >= r.target) return p.income;
      if (r.amount > 0) return p.warning;
      return p.expense;
    }

    return LayoutBuilder(builder: (context, c) {
      const gap = 4.0;
      final cell = ((c.maxWidth - (weeks - 1) * gap) / weeks).clamp(8.0, 34.0);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var w = 0; w < weeks; w++) ...[
              if (w > 0) const SizedBox(width: gap),
              Column(children: [
                for (var r = 0; r < 7; r++) ...[
                  if (r > 0) const SizedBox(height: gap),
                  Builder(builder: (_) {
                    final d = start.add(Duration(days: w * 7 + r));
                    final rec = byKey[dbDate(d)];
                    final tip = '${context.fmt.dayMonth(d)}${rec == null ? '' : ' · ${context.fmt.money(rec.amount)}'}';
                    return Tooltip(
                      message: tip,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300 + w * 20),
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(color: colorFor(d), borderRadius: BorderRadius.circular(cell * 0.3)),
                      ),
                    );
                  }),
                ],
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 14, runSpacing: 6, children: [
          _legend(context, p.income, s.legendFull),
          _legend(context, p.warning, s.legendPartial),
          _legend(context, p.expense, s.legendNone),
          _legend(context, p.muted.withValues(alpha: 0.35), s.legendOff),
        ]),
      ]);
    });
  }

  Widget _legend(BuildContext context, Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: context.pal.muted, fontWeight: FontWeight.w600)),
      ]);
}
