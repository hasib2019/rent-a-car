import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';

/// Paired income / expense bars per month with a profit dot.
class MonthlyBars extends StatelessWidget {
  const MonthlyBars({super.key, required this.points, this.height = 220});
  final List<MonthPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final f = context.fmt;
    final s = context.s;
    final maxY = points.fold<double>(0, (a, m) => math.max(a, math.max(m.income, m.expense)));
    final step = _niceStep(maxY <= 0 ? 1000 : maxY * 1.1 / 4);
    final top = step * 4;

    return Column(children: [
      SizedBox(
        height: height,
        child: BarChart(
          BarChartData(
            maxY: top,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: step,
              getDrawingHorizontalLine: (_) => FlLine(color: p.line, strokeWidth: 1, dashArray: [4, 4]),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  interval: step,
                  getTitlesWidget: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(v == 0 ? '' : f.compact(v), style: TextStyle(color: p.muted, fontSize: 10.5)),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= points.length) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(f.monthShort(points[i].month.month), style: TextStyle(color: p.muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => p.hero,
                tooltipBorderRadius: BorderRadius.circular(12),
                getTooltipItem: (group, _, rod, rodIndex) {
                  final m = points[group.x];
                  return BarTooltipItem(
                    '${f.monthYear(m.month)}\n',
                    TextStyle(color: p.onHero, fontWeight: FontWeight.w700, fontFamily: kFont, fontSize: 12),
                    children: [
                      TextSpan(text: '${s.income}: ${f.money(m.income)}\n', style: TextStyle(color: p.income, fontWeight: FontWeight.w600)),
                      TextSpan(text: '${s.expense}: ${f.money(m.expense)}\n', style: TextStyle(color: p.expense, fontWeight: FontWeight.w600)),
                      TextSpan(text: '${s.profit}: ${f.money(m.profit)}', style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
                    ],
                  );
                },
              ),
            ),
            barGroups: [
              for (var i = 0; i < points.length; i++)
                BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(toY: points[i].income, color: p.income, width: 12, borderRadius: BorderRadius.circular(5)),
                    BarChartRodData(toY: points[i].expense, color: p.expense.withValues(alpha: 0.8), width: 12, borderRadius: BorderRadius.circular(5)),
                  ],
                ),
            ],
          ),
          duration: const Duration(milliseconds: 500),
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _dot(p.income, s.income, p),
        const SizedBox(width: 18),
        _dot(p.expense, s.expense, p),
      ]),
    ]);
  }

  /// Rounds a raw axis step up to 1, 2, 2.5 or 5 × 10ⁿ.
  static double _niceStep(double raw) {
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (m * mag >= raw) return m * mag;
    }
    return 10 * mag;
  }

  Widget _dot(Color c, String label, Palette p) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: p.muted, fontSize: 12, fontWeight: FontWeight.w600)),
      ]);
}

/// Donut of expense categories with a legend.
class CategoryDonut extends StatefulWidget {
  const CategoryDonut({super.key, required this.data});
  final Map<ExpenseCategory, double> data;

  @override
  State<CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<CategoryDonut> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final f = context.fmt;
    final s = context.s;
    final total = widget.data.values.fold<double>(0, (a, b) => a + b);
    final entries = widget.data.entries.toList();
    final focus = _touched != null && _touched! < entries.length ? entries[_touched!] : null;

    final donut = SizedBox(
      width: 170,
      height: 170,
      child: Stack(alignment: Alignment.center, children: [
        PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 54,
            startDegreeOffset: -90,
            pieTouchData: PieTouchData(touchCallback: (event, res) {
              setState(() => _touched = res?.touchedSection?.touchedSectionIndex);
            }),
            sections: [
              for (var i = 0; i < entries.length; i++)
                PieChartSectionData(
                  value: entries[i].value,
                  color: entries[i].key.color,
                  radius: _touched == i ? 30 : 24,
                  showTitle: false,
                ),
            ],
          ),
          duration: const Duration(milliseconds: 300),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(focus == null ? s.total : focus.key.label(s), style: TextStyle(color: p.muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
          Text(f.compact(focus?.value ?? total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
      ]),
    );

    final legend = Column(children: [
      for (var i = 0; i < entries.length; i++)
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _touched = _touched == i ? null : i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: entries[i].key.color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Expanded(child: Text(entries[i].key.label(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: _touched == i ? FontWeight.w700 : FontWeight.w500, fontSize: 13.5))),
              Text(f.percent(total == 0 ? 0 : entries[i].value / total), style: TextStyle(color: p.muted, fontSize: 12.5)),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Text(f.money(entries[i].value), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
            ]),
          ),
        ),
    ]);

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 460) {
        return Column(children: [donut, const SizedBox(height: 16), legend]);
      }
      return Row(children: [donut, const SizedBox(width: 24), Expanded(child: legend)]);
    });
  }
}
