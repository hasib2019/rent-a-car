import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../services/settings.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/ledger_tile.dart';
import 'daily_collection_screen.dart';
import 'documents_screen.dart';
import 'driver_screens.dart';
import 'maintenance_screen.dart';
import 'parties_screen.dart';
import 'settings_screen.dart';
import 'trip_screens.dart';
import 'vehicle_screens.dart';

class _HomeData {
  _HomeData(this.today, this.month, this.spark, this.stats, this.recent, this.papers, this.trips, this.partsDue, this.serviceDue, this.parties);
  final Map<int, Income> today;
  final Totals month;
  final List<double> spark;
  final Map<int, VehicleStat> stats;
  final List<LedgerEntry> recent;
  final List<Paper> papers;
  final List<TripSummary> trips;
  final List<PartStatus> partsDue;
  final List<ServiceStatus> serviceDue;

  /// Clients who still owe money.
  final List<PartySummary> parties;
}

Future<_HomeData> _loadHome(Repository r) async {
  final now = DateTime.now();
  final month = Period.thisMonth();
  final soFar = Period(month.from, DateUtils.dateOnly(now));
  final res = await Future.wait([
    r.dailyEntries(now),
    r.totals(month),
    r.dailyProfit(soFar),
    r.vehicleStats(month),
    r.ledger(limit: 6),
    r.papers(),
    r.trips(period: month),
    r.partStatuses(),
    r.serviceStatuses(),
    r.parties(),
  ]);
  return _HomeData(
    res[0] as Map<int, Income>,
    res[1] as Totals,
    res[2] as List<double>,
    res[3] as Map<int, VehicleStat>,
    res[4] as List<LedgerEntry>,
    (res[5] as List<Paper>).where((p) => p.daysLeft <= 30).toList(),
    res[6] as List<TripSummary>,
    (res[7] as List<PartStatus>).where((p) => p.needsAttention).toList(),
    (res[8] as List<ServiceStatus>).where((p) => p.needsAttention).toList(),
    (res[9] as List<PartySummary>).where((p) => p.due > 0.5).toList(),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenLedger, required this.onOpenTrips, required this.onOpenParts});
  final VoidCallback onOpenLedger;
  final VoidCallback onOpenTrips;
  final VoidCallback onOpenParts;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final settings = context.watch<Settings>();
    final s = context.s;
    final p = context.pal;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 18),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.greeting(DateTime.now().hour), style: TextStyle(color: p.muted, fontWeight: FontWeight.w600)),
            Text(
              settings.ownerName.isEmpty ? s.appName : settings.ownerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ]),
        ),
        if (!wide)
          RoundIconButton(
            icon: Icons.tune_rounded,
            tooltip: s.settings,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
      ]),
    );

    if (app.vehicles.isEmpty) {
      return SafeArea(
        bottom: false,
        child: Contained(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), children: [header, const _WelcomeCard()]),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Loader<_HomeData>(
        load: _loadHome,
        builder: (context, d) {
          final hero = _TodayHero(data: d);
          final month = _MonthCard(data: d);
          final attention = _Attention(data: d, onOpenParts: onOpenParts);
          final trips = _TripsSection(trips: d.trips, onSeeAll: onOpenTrips);
          final fleet = _FleetStrip(stats: d.stats);
          final recent = _Recent(entries: d.recent, onSeeAll: onOpenLedger);

          return Contained(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                header,
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 6, child: Entrance(child: hero)),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: Entrance(index: 1, child: month)),
                  ])
                else ...[
                  Entrance(child: hero),
                  const SizedBox(height: 14),
                  Entrance(index: 1, child: month),
                  const SizedBox(height: 14),
                  Entrance(index: 2, child: _Shortcuts(data: d, onOpenTrips: onOpenTrips, onOpenParts: onOpenParts)),
                ],
                Entrance(index: 2, child: attention),
                Entrance(index: 3, child: trips),
                Entrance(index: 4, child: fleet),
                Entrance(index: 5, child: recent),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({required this.data});
  final _HomeData data;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final active = app.activeVehicles;
    var target = 0.0, collected = 0.0;
    var done = 0;
    final parts = <(double, Color)>[];
    for (final v in active) {
      final e = data.today[v.id];
      if (e != null) done++;
      if (e?.kind == IncomeKind.off) {
        parts.add((1, p.onHero.withValues(alpha: 0.3)));
        continue;
      }
      final t = e?.target ?? v.dailyTarget;
      target += t;
      collected += e?.amount ?? 0;
      parts.add((t <= 0 ? (e != null ? 1 : 0) : (e?.amount ?? 0) / t, v.type.color));
    }
    final ratio = target <= 0 ? 0.0 : collected / target;
    final pending = active.length - done;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: LanePainter(p.onHero.withValues(alpha: 0.05)))),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(20)),
                child: Text(s.todaysCollection, style: TextStyle(color: p.onAccent, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
              const Spacer(),
              Text(f.date(DateTime.now()), style: TextStyle(color: p.onHero.withValues(alpha: 0.6), fontSize: 12.5, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 18),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(TextSpan(children: [
                TextSpan(text: f.money(collected), style: TextStyle(color: p.onHero, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.6, height: 1)),
                TextSpan(text: '  / ${f.money(target)}', style: TextStyle(color: p.onHero.withValues(alpha: 0.5), fontSize: 17, fontWeight: FontWeight.w600)),
              ])),
            ),
            const SizedBox(height: 6),
            Text('${f.percent(ratio)} ${s.ofTarget}', style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            SegmentBar(parts: parts, height: 12, track: p.onHero.withValues(alpha: 0.1)),
            const SizedBox(height: 10),
            Wrap(spacing: 12, runSpacing: 6, children: [
              for (final v in active)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: v.type.color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(v.name, style: TextStyle(color: p.onHero.withValues(alpha: 0.7), fontSize: 12)),
                ]),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: Text(
                  pending == 0 ? s.allCollected : '${s.pendingToday}: ${f.digits(pending)}',
                  style: TextStyle(color: p.onHero.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                ),
              ),
              Pressable(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyCollectionScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(16)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(pending == 0 ? s.edit : s.collectNow, style: TextStyle(color: p.onAccent, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: p.onAccent),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.data});
  final _HomeData data;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final t = data.month;
    final profitColor = t.profit >= 0 ? p.income : p.expense;
    return Column(children: [
      Panel(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${s.netProfit} · ${f.month(DateTime.now().month)}', style: TextStyle(color: p.muted, fontWeight: FontWeight.w600)),
            const Spacer(),
            StatusPill('${s.margin} ${f.percent(t.margin)}', profitColor),
          ]),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(f.money(t.profit), style: context.text.displaySmall?.copyWith(color: t.profit >= 0 ? p.ink : p.expense, fontSize: 38)),
          ),
          const SizedBox(height: 10),
          Sparkline(values: data.spark, color: profitColor, height: 56),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: StatBlock(label: s.income, value: f.money(t.income), icon: Icons.south_west_rounded, color: p.income)),
        const SizedBox(width: 12),
        Expanded(child: StatBlock(label: s.expense, value: f.money(t.expense), icon: Icons.north_east_rounded, color: p.expense)),
      ]),
    ]);
  }
}

class _Attention extends StatelessWidget {
  const _Attention({required this.data, required this.onOpenParts});
  final _HomeData data;
  final VoidCallback onOpenParts;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final owing = app.drivers.where((d) => (app.dues[d.id] ?? 0) > 0).toList()
      ..sort((a, b) => (app.dues[b.id] ?? 0).compareTo(app.dues[a.id] ?? 0));
    final parts = data.partsDue;
    final licences = app.drivers.where((d) => d.active && d.licenseDaysLeft != null && d.licenseDaysLeft! <= 30).toList()
      ..sort((a, b) => a.licenseDaysLeft!.compareTo(b.licenseDaysLeft!));
    final partyDue = data.parties.fold<double>(0, (a, x) => a + x.due);

    final cards = <Widget>[
      if (data.parties.isNotEmpty)
        _AttentionCard(
          icon: Icons.groups_rounded,
          color: p.warning,
          title: s.partyDues,
          value: f.money(partyDue),
          lines: [for (final x in data.parties.take(3)) '${x.name} · ${f.money(x.due)}'],
          onTap: () => openParties(context),
        ),
      if (data.serviceDue.isNotEmpty)
        _AttentionCard(
          icon: Icons.event_repeat_rounded,
          color: data.serviceDue.any((x) => x.health == DueHealth.overdue) ? p.expense : p.warning,
          title: s.serviceDue,
          value: f.digits(data.serviceDue.length),
          lines: [for (final st in data.serviceDue.take(3)) '${app.vehicle(st.vehicleId)?.name ?? ''} · ${dueLabel(st, s, f)}'],
          onTap: onOpenParts,
        ),
      if (licences.isNotEmpty)
        _AttentionCard(
          icon: Icons.badge_rounded,
          color: licences.any((d) => d.licenseDaysLeft! < 0) ? p.expense : p.warning,
          title: s.licensesExpiring,
          value: f.digits(licences.length),
          lines: [for (final d in licences.take(3)) '${d.name} · ${s.expiresIn(d.licenseDaysLeft!)}'],
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DriverDetailScreen(driverId: licences.first.id!))),
        ),
      if (owing.isNotEmpty)
        _AttentionCard(
          icon: Icons.account_balance_wallet_rounded,
          color: p.warning,
          title: s.driverDues,
          value: f.money(app.totalDue),
          lines: [for (final d in owing.take(3)) '${d.name} · ${f.money(app.dues[d.id]!)}'],
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DriverDetailScreen(driverId: owing.first.id!))),
        ),
      if (data.papers.isNotEmpty)
        _AttentionCard(
          icon: Icons.event_busy_rounded,
          color: p.expense,
          title: s.paperExpiring,
          value: f.digits(data.papers.length),
          lines: [
            for (final pp in data.papers.take(3)) '${app.vehicle(pp.vehicleId)?.name ?? ''} · ${pp.type.label(s)} · ${s.expiresIn(pp.daysLeft)}',
          ],
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DocumentsScreen())),
        ),
      if (parts.isNotEmpty)
        _AttentionCard(
          icon: Icons.build_circle_rounded,
          color: parts.any((x) => x.health == DueHealth.overdue) ? p.expense : p.warning,
          title: s.partsDueShort,
          value: f.digits(parts.length),
          lines: [
            for (final st in parts.take(3)) '${app.vehicle(st.part.vehicleId)?.name ?? ''} · ${st.part.label(s)} · ${dueLabel(st, s, f)}',
          ],
          onTap: onOpenParts,
        ),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(s.attention),
      LayoutBuilder(builder: (context, c) {
        // Up to three cards per row on wide screens, one per row on phones.
        final cols = c.maxWidth > 900 ? 3 : (c.maxWidth > 560 ? 2 : 1);
        final rows = <Widget>[];
        for (var i = 0; i < cards.length; i += cols) {
          final chunk = cards.sublist(i, (i + cols).clamp(0, cards.length));
          rows.add(IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(child: j < chunk.length ? chunk[j] : const SizedBox.shrink()),
              ],
            ]),
          ));
        }
        return Column(children: [
          for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: 12), rows[i]],
        ]);
      }),
    ]);
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.icon, required this.color, required this.title, required this.value, required this.lines, required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final List<String> lines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Panel(
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconBubble(icon, color, size: 44),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 13))),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
            const SizedBox(height: 6),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// Phone-only entry points to trips and parts (wide layouts have the sidebar).
class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.data, required this.onOpenTrips, required this.onOpenParts});
  final _HomeData data;
  final VoidCallback onOpenTrips;
  final VoidCallback onOpenParts;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final due = data.partsDue.length;
    Widget tile(IconData icon, Color color, String title, String sub, VoidCallback onTap) => Expanded(
          child: Panel(
            onTap: onTap,
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              IconBubble(icon, color, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12)),
                ]),
              ),
            ]),
          ),
        );
    return Row(children: [
      tile(Icons.route_rounded, p.income, s.trips, '${s.tripCount(data.trips.length)} · ${f.monthShort(DateTime.now().month)}', onOpenTrips),
      const SizedBox(width: 12),
      tile(Icons.build_circle_rounded, due > 0 ? p.warning : ExpenseCategory.servicing.color, s.partsShort, due > 0 ? s.partsDueCount(due) : s.allPartsOk, onOpenParts),
    ]);
  }
}

/// This month's trips: totals plus the latest few.
class _TripsSection extends StatelessWidget {
  const _TripsSection({required this.trips, required this.onSeeAll});
  final List<TripSummary> trips;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final app = context.watch<AppState>();
    final fare = trips.fold<double>(0, (a, t) => a + t.trip.earned);
    final cost = trips.fold<double>(0, (a, t) => a + t.cost);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader('${s.trips} · ${s.thisMonth}', action: s.seeAll, onAction: onSeeAll),
      Panel(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: KeyValue(s.trips, f.digits(trips.length))),
            Expanded(child: KeyValue(s.fare, f.money(fare), color: p.income)),
            Expanded(child: KeyValue(s.tripCost, f.money(cost), color: p.expense)),
            Expanded(child: KeyValue(s.profit, f.money(fare - cost), color: fare - cost >= 0 ? p.ink : p.expense, end: true)),
          ]),
          const SizedBox(height: 6),
          Divider(color: p.line),
          if (trips.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Text(s.noTripsBody, style: TextStyle(color: p.muted, fontSize: 13))),
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => openTripForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(s.newTrip),
                ),
              ]),
            )
          else
            for (final t in trips.take(3))
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => openTrip(context, t.trip.id!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    if (app.vehicle(t.trip.vehicleId) case final v?) TypeBadge(v.type, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        RouteText(t.trip, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                        Text('${tripDates(f, t.trip)} · ${app.vehicle(t.trip.vehicleId)?.name ?? ''}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      if (t.trip.status.countsFare)
                        Text(f.money(t.profit), style: TextStyle(fontWeight: FontWeight.w800, color: t.profit >= 0 ? p.income : p.expense))
                      else
                        TripStatusPill(t.trip.status),
                      Text('${s.fare} ${f.money(t.trip.fare)}', style: TextStyle(color: p.muted, fontSize: 11.5)),
                    ]),
                  ]),
                ),
              ),
        ]),
      ),
    ]);
  }
}

class _FleetStrip extends StatelessWidget {
  const _FleetStrip({required this.stats});
  final Map<int, VehicleStat> stats;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final vehicles = app.vehicles;
    final maxProfit = vehicles.map((v) => (stats[v.id]?.profit ?? 0).abs()).fold<double>(1, (a, b) => b > a ? b : a);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader('${s.yourFleet} · ${s.thisMonth}'),
      SizedBox(
        height: 196,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: vehicles.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final v = vehicles[i];
            final st = stats[v.id];
            final profit = st?.profit ?? 0;
            final driver = app.driverOf(v);
            return Pressable(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicleId: v.id!))),
              child: Container(
                width: 210,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: p.line),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [v.type.color.withValues(alpha: p.isDark ? 0.16 : 0.10), p.surface],
                    stops: const [0, 0.6],
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    TypeBadge(v.type, size: 38),
                    const Spacer(),
                    if (!v.isActive) StatusPill(v.status.label(s), p.muted),
                  ]),
                  const SizedBox(height: 10),
                  Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                  Text(driver?.name ?? s.noDriver, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
                  const Spacer(),
                  Text(s.profit, style: TextStyle(color: p.muted, fontSize: 12)),
                  Money(profit, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: profit >= 0 ? p.ink : p.expense)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (profit.abs() / maxProfit).clamp(0, 1),
                      minHeight: 6,
                      color: profit >= 0 ? v.type.color : p.expense,
                      backgroundColor: p.surfaceAlt,
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
      if (vehicles.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(f.monthYear(DateTime.now()), style: TextStyle(color: p.muted, fontSize: 12)),
        ),
    ]);
  }
}

class _Recent extends StatelessWidget {
  const _Recent({required this.entries, required this.onSeeAll});
  final List<LedgerEntry> entries;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(s.recentEntries, action: s.seeAll, onAction: onSeeAll),
      Panel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: entries.isEmpty
            ? EmptyState(icon: Icons.receipt_long_rounded, title: s.noEntries, body: s.noEntriesBody)
            : Column(children: [for (final e in entries) LedgerTile(e, showDate: true)]),
      ),
    ]);
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    return Entrance(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: LanePainter(p.onHero.withValues(alpha: 0.06)))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                for (final t in [VehicleType.cng, VehicleType.car, VehicleType.pickup])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(18)),
                      child: Icon(t.icon, color: Colors.white, size: 28),
                    ),
                  ),
              ]),
              const SizedBox(height: 22),
              Text(s.welcomeTitle, style: context.text.headlineMedium?.copyWith(color: p.onHero, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(s.welcomeBody, style: TextStyle(color: p.onHero.withValues(alpha: 0.7), height: 1.4)),
              const SizedBox(height: 22),
              Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VehicleFormScreen())),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(s.addFirstVehicle),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: p.onHero, side: BorderSide(color: p.onHero.withValues(alpha: 0.25))),
                  onPressed: () async {
                    await context.read<AppState>().loadDemo(bangla: s.bn);
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(s.loadDemo),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
