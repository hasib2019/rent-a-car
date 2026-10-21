import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/l10n_personal.dart';
import '../../core/theme.dart';
import '../../data/forecast.dart';
import '../../data/models.dart';
import '../routes.dart';
import '../widgets/common.dart';
import '../widgets/fuel_charts.dart';

String forecastLabel(S s, ForecastItem i) => switch (i.kind) {
      ForecastKind.paper => '${i.paper!.label(s)} ${s.renewal}',
      ForecastKind.service => s.serviceForecast,
      ForecastKind.part => i.part!.label(s),
      ForecastKind.fuel => s.fuelForecast,
      ForecastKind.regular => s.regularForecast,
    };

(IconData, Color) _look(ForecastItem i) => switch (i.kind) {
      ForecastKind.paper => (Icons.event_note_rounded, ExpenseCategory.papers.color),
      ForecastKind.service => (Icons.garage_rounded, ExpenseCategory.servicing.color),
      ForecastKind.part => (i.part!.icon, i.part!.color),
      ForecastKind.fuel => (Icons.local_gas_station_rounded, ExpenseCategory.fuel.color),
      ForecastKind.regular => (Icons.receipt_long_rounded, ExpenseCategory.parking.color),
    };

/// Dashboard card: the year ahead in one number, a bar per month and the next big costs.
class ForecastCard extends StatelessWidget {
  const ForecastCard({super.key, required this.forecast, required this.vehicle});
  final CostForecast forecast;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final fc = forecast;
    final heavy = fc.heaviest;
    final next = fc.oneOffs.take(3).toList();

    return Panel(
      onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => ForecastScreen(forecast: fc, vehicle: vehicle))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconBubble(Icons.query_stats_rounded, p.info, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.forecastTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(s.forecastSub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded),
        ]),
        const SizedBox(height: 14),
        if (fc.total <= 0)
          Text(s.forecastEmpty, style: TextStyle(color: p.muted, height: 1.4))
        else ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(f.money(fc.total.roundToDouble()), style: context.text.displaySmall?.copyWith(fontSize: 34, color: p.ink)),
          ),
          Text(s.avgPerMonth(f.money(fc.perMonth.roundToDouble())), style: TextStyle(color: p.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          MonthBars(points: [for (final m in fc.months) (m.month, m.total)], color: p.info, label: f.money, height: 130),
          if (heavy != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: p.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(Icons.lightbulb_rounded, size: 18, color: p.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.heaviestMonth(f.monthYear(heavy.month), f.money(heavy.oneOffTotal.roundToDouble())),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.3)),
                ),
              ]),
            ),
          ],
          if (next.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(s.comingUp, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 13)),
            for (final i in next) ForecastTile(item: i),
          ],
        ],
      ]),
    );
  }
}

class ForecastTile extends StatelessWidget {
  const ForecastTile({super.key, required this.item});
  final ForecastItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final (icon, color) = _look(item);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        IconBubble(icon, color, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(forecastLabel(s, item), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              item.overdue ? s.overdueNow : (item.oneOff ? f.date(item.date) : f.monthYear(item.date)),
              style: TextStyle(color: item.overdue ? p.expense : p.muted, fontSize: 12.5, fontWeight: item.overdue ? FontWeight.w700 : FontWeight.w400),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Text(
          item.amount == null ? s.costUnknown : f.money(item.amount!.roundToDouble()),
          style: TextStyle(fontWeight: FontWeight.w800, color: item.amount == null ? p.muted : p.ink, fontSize: item.amount == null ? 12.5 : 14.5),
        ),
      ]),
    );
  }
}

/// Month by month: what to expect and roughly what it costs.
class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key, required this.forecast, required this.vehicle});
  final CostForecast forecast;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final fc = forecast;
    return Scaffold(
      appBar: AppBar(title: Text(s.forecastTitle)),
      body: Contained(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(vehicle.name, style: TextStyle(color: p.onHero.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(f.money(fc.total.roundToDouble()), style: TextStyle(color: p.onHero, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.4)),
                ),
                Text(s.avgPerMonth(f.money(fc.perMonth.roundToDouble())), style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
                if (fc.kmPerDay != null) ...[
                  const SizedBox(height: 6),
                  Text(s.kmPerDayText(f.number(fc.kmPerDay!)), style: TextStyle(color: p.onHero.withValues(alpha: 0.6), fontSize: 12.5)),
                ],
              ]),
            ),
            if (fc.unknown > 0) ...[
              const SizedBox(height: 12),
              Panel(
                color: p.warning.withValues(alpha: 0.08),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: p.warning),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.unknownHint(fc.unknown), style: const TextStyle(fontSize: 13.5, height: 1.35))),
                ]),
              ),
            ],
            for (final m in fc.months)
              if (m.items.isNotEmpty) ...[
                SectionHeader('${f.monthYear(m.month)} · ${f.money(m.total.roundToDouble())}'),
                Panel(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(children: [
                    for (final i in [...m.items.where((i) => i.oneOff), ...m.items.where((i) => !i.oneOff)]) ForecastTile(item: i),
                  ]),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
