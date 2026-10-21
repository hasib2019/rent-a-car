import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';

/// A value over time — mileage per full tank, price per fill — with the
/// average as a dashed line.
class TrendLine extends StatelessWidget {
  const TrendLine({super.key, required this.points, required this.color, required this.label, this.height = 170, this.decimals = 1});
  final List<(DateTime, double)> points;
  final Color color;

  /// Formats a value for the axis and tooltip.
  final String Function(double v) label;
  final double height;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final f = context.fmt;
    if (points.isEmpty) return SizedBox(height: height);
    final values = points.map((e) => e.$2).toList();
    final lo = values.reduce(math.min), hi = values.reduce(math.max);
    final pad = math.max((hi - lo) * 0.25, hi * 0.05);
    final avg = values.reduce((a, b) => a + b) / values.length;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: math.max(0, lo - pad),
          maxY: hi + pad,
          minX: 0,
          maxX: math.max(1, points.length - 1).toDouble(),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: p.line, strokeWidth: 1, dashArray: [4, 4]),
          ),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(y: avg, color: color.withValues(alpha: 0.5), strokeWidth: 1.4, dashArray: [6, 4]),
          ]),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, meta) => v == meta.min || v == meta.max
                    ? const SizedBox.shrink()
                    : SideTitleWidget(meta: meta, child: Text(f.number(v, decimals: v < 100 ? decimals : 0), style: TextStyle(color: p.muted, fontSize: 10.5))),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: math.max(1, (points.length / 5).ceil()).toDouble(),
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  final every = math.max(1, (points.length / 5).ceil());
                  // fl_chart always labels the last point; skip it unless it falls on the interval.
                  if (i < 0 || i >= points.length || v != i.toDouble() || i % every != 0) return const SizedBox.shrink();
                  final d = points[i].$1;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text('${f.digits(d.day)} ${f.monthShort(d.month)}', style: TextStyle(color: p.muted, fontSize: 10.5, fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => p.hero,
              tooltipBorderRadius: BorderRadius.circular(12),
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '${f.date(points[s.x.round()].$1)}\n',
                    TextStyle(color: p.onHero.withValues(alpha: 0.7), fontFamily: kFont, fontSize: 11.5),
                    children: [TextSpan(text: label(s.y), style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 13))],
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].$2)],
              isCurved: true,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 3,
              dotData: FlDotData(
                show: points.length <= 24,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(radius: 3.5, color: p.surface, strokeWidth: 2.4, strokeColor: color),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)]),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}

/// One bar per month (spend, fuel, km), the current month highlighted.
class MonthBars extends StatelessWidget {
  const MonthBars({super.key, required this.points, required this.color, required this.label, this.height = 170});
  final List<(DateTime, double)> points;
  final Color color;
  final String Function(double v) label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final f = context.fmt;
    final maxY = points.fold<double>(0, (a, e) => math.max(a, e.$2));
    final now = DateTime.now();

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY * 1.15,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(f.monthShort(points[i].$1.month), style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => p.hero,
              tooltipBorderRadius: BorderRadius.circular(12),
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${f.monthYear(points[group.x].$1)}\n',
                TextStyle(color: p.onHero.withValues(alpha: 0.7), fontFamily: kFont, fontSize: 11.5),
                children: [TextSpan(text: label(rod.toY), style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 13))],
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: points[i].$2,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: points[i].$1.year == now.year && points[i].$1.month == now.month ? color : color.withValues(alpha: 0.45),
                ),
              ]),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}
