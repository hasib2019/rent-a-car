import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../state/app_state.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'driver_screens.dart';
import 'vehicle_screens.dart';

enum _Range { thisMonth, lastMonth, thisYear, allTime, custom }

class _ReportData {
  _ReportData(this.totals, this.stats, this.monthly, this.categories);
  final Totals totals;
  final Map<int, VehicleStat> stats;
  final List<MonthPoint> monthly;
  final Map<ExpenseCategory, double> categories;
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _Range _range = _Range.thisMonth;
  Period? _custom;

  Period get _period => switch (_range) {
        _Range.thisMonth => Period.thisMonth(),
        _Range.lastMonth => Period.lastMonth(),
        _Range.thisYear => Period.thisYear(),
        _Range.allTime => Period.allTime(),
        _Range.custom => _custom ?? Period.thisMonth(),
      };

  Future<_ReportData> _load(Repository r) async {
    final p = _period;
    final res = await Future.wait([r.totals(p), r.vehicleStats(p), r.monthly(months: 6), r.expenseByCategory(p)]);
    return _ReportData(res[0] as Totals, res[1] as Map<int, VehicleStat>, res[2] as List<MonthPoint>, res[3] as Map<ExpenseCategory, double>);
  }

  String _rangeLabel(_Range r) {
    final s = context.s;
    final f = context.fmt;
    return switch (r) {
      _Range.thisMonth => s.thisMonth,
      _Range.lastMonth => s.lastMonth,
      _Range.thisYear => s.thisYear,
      _Range.allTime => s.allTime,
      _Range.custom => _custom == null ? s.custom : '${f.dayMonth(_custom!.from)} – ${f.dayMonth(_custom!.to)}',
    };
  }

  Future<void> _pickCustom() async {
    final res = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _custom == null ? null : DateTimeRange(start: _custom!.from, end: _custom!.to),
    );
    if (res != null) {
      setState(() {
        _custom = Period(res.start, res.end);
        _range = _Range.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final app = context.watch<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return SafeArea(
      bottom: false,
      child: Contained(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(children: [Expanded(child: Text(s.reports, style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)))]),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              children: [
                for (final r in _Range.values) ...[
                  ChoiceTag(
                    label: _rangeLabel(r),
                    icon: r == _Range.custom ? Icons.date_range_rounded : null,
                    selected: _range == r,
                    onTap: () => r == _Range.custom ? _pickCustom() : setState(() => _range = r),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: Loader<_ReportData>(
              load: _load,
              deps: [_range, _custom?.from, _custom?.to],
              builder: (context, d) {
                final summary = _Summary(totals: d.totals, label: _rangeLabel(_range));
                final board = _Leaderboard(stats: d.stats);
                final trend = Panel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${s.monthlyTrend} · ${s.sixMonths}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    MonthlyBars(points: d.monthly),
                  ]),
                );
                final donut = Panel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.expenseBreakdown, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    if (d.categories.isEmpty) Text(s.noData, style: TextStyle(color: p.muted)) else CategoryDonut(data: d.categories),
                  ]),
                );
                final owing = app.drivers.where((x) => (app.dues[x.id] ?? 0) != 0).toList()
                  ..sort((a, b) => (app.dues[b.id] ?? 0).compareTo(app.dues[a.id] ?? 0));
                final dues = Panel(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(s.driverDues, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(f.money(app.totalDue), style: TextStyle(color: p.expense, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 8),
                    if (owing.isEmpty)
                      Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(s.noDue, style: TextStyle(color: p.muted)))
                    else
                      for (final dr in owing)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DriverDetailScreen(driverId: dr.id!))),
                          leading: Avatar(name: dr.name, initials: dr.initials, size: 40),
                          title: Text(dr.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(app.vehicleOfDriver(dr.id!)?.name ?? '', style: TextStyle(color: p.muted, fontSize: 12.5)),
                          trailing: Text(
                            (app.dues[dr.id] ?? 0) > 0 ? f.money(app.dues[dr.id]!) : '+${f.money(-(app.dues[dr.id] ?? 0))}',
                            style: TextStyle(fontWeight: FontWeight.w800, color: (app.dues[dr.id] ?? 0) > 0 ? p.expense : p.income),
                          ),
                        ),
                  ]),
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                  children: wide
                      ? [
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: Column(children: [summary, const SizedBox(height: 16), board])),
                            const SizedBox(width: 16),
                            Expanded(child: Column(children: [trend, const SizedBox(height: 16), donut, const SizedBox(height: 16), dues])),
                          ]),
                        ]
                      : [
                          Entrance(child: summary),
                          const SizedBox(height: 16),
                          Entrance(index: 1, child: board),
                          const SizedBox(height: 16),
                          Entrance(index: 2, child: trend),
                          const SizedBox(height: 16),
                          donut,
                          const SizedBox(height: 16),
                          dues,
                        ],
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.totals, required this.label});
  final Totals totals;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final t = totals;
    final ratio = t.income <= 0 ? 0.0 : (t.expense / t.income).clamp(0.0, 1.0);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: LanePainter(p.onHero.withValues(alpha: 0.05)))),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${t.profit >= 0 ? s.netProfit : s.loss} · $label', style: TextStyle(color: p.onHero.withValues(alpha: 0.65), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(f.money(t.profit), style: TextStyle(color: t.profit >= 0 ? p.accent : p.expense, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.6)),
            ),
            const SizedBox(height: 4),
            Text('${s.margin} ${f.percent(t.margin)}', style: TextStyle(color: p.onHero.withValues(alpha: 0.75), fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: Row(children: [
                  Expanded(flex: ((1 - ratio) * 1000).round().clamp(1, 1000), child: Container(color: p.income)),
                  Expanded(flex: (ratio * 1000).round().clamp(1, 1000), child: Container(color: p.expense)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _kv(s.income, f.money(t.income), p.income, p)),
              Expanded(child: _kv(s.expense, f.money(t.expense), p.expense, p)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _kv(String k, String v, Color c, Palette p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(k, style: TextStyle(color: p.onHero.withValues(alpha: 0.65), fontSize: 12.5)),
        ]),
        Text(v, style: TextStyle(color: p.onHero, fontWeight: FontWeight.w800, fontSize: 17)),
      ]);
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.stats});
  final Map<int, VehicleStat> stats;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final rows = app.vehicles.map((v) => (v, stats[v.id] ?? VehicleStat(vehicleId: v.id!))).toList()
      ..sort((a, b) => b.$2.profit.compareTo(a.$2.profit));
    final maxAbs = rows.fold<double>(1, (a, r) => r.$2.profit.abs() > a ? r.$2.profit.abs() : a);

    return Panel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.emoji_events_rounded, color: p.warning),
          const SizedBox(width: 8),
          Text(s.whoEarnedMost, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        if (rows.isEmpty) Text(s.noData, style: TextStyle(color: p.muted)),
        for (var i = 0; i < rows.length; i++)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicleId: rows[i].$1.id!))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    f.digits(i + 1),
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: i == 0 ? p.warning : p.muted),
                  ),
                ),
                TypeBadge(rows[i].$1.type, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(rows[i].$1.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(f.money(rows[i].$2.profit), style: TextStyle(fontWeight: FontWeight.w800, color: rows[i].$2.profit >= 0 ? p.ink : p.expense)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: (rows[i].$2.profit.abs() / maxAbs).clamp(0, 1)),
                        duration: Duration(milliseconds: 700 + i * 100),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 8,
                          color: rows[i].$2.profit >= 0 ? rows[i].$1.type.color : p.expense,
                          backgroundColor: p.surfaceAlt,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.income} ${f.compact(rows[i].$2.income)} · ${s.fuel} ${f.compact(rows[i].$2.fuel)} · ${s.repairCost} ${f.compact(rows[i].$2.maintenance)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.muted, fontSize: 11.5),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}
