import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'service_screens.dart';
import 'vehicle_screens.dart';

Future<void> openPartForm(BuildContext context, {Part? part, int? vehicleId}) => Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: part == null,
      builder: (_) => PartFormScreen(part: part, vehicleId: vehicleId),
    ));

/// Parts fitted in a garage visit are edited as part of that visit.
Future<void> openFitting(BuildContext context, Part part) =>
    part.visitId != null ? openVisit(context, part.visitId!) : openPartForm(context, part: part);

/// "12 days left", "350 km overdue"… whichever limit is closer.
String dueLabel(DueStatus st, S s, Fmt f) {
  final d = st.daysLeft, k = st.kmLeft;
  if (d == null && k == null) return s.noSchedule;
  if (st.kmIsCloser) return k! < 0 ? s.partOverdueKm(f.number(-k)) : s.partKmLeft(f.number(k));
  return d! < 0 ? s.partOverdueDays(-d) : s.partDaysLeft(d);
}

Color dueColor(DueHealth h, Palette p) => switch (h) {
      DueHealth.overdue => p.expense,
      DueHealth.soon => p.warning,
      DueHealth.ok => p.income,
      DueHealth.unscheduled => p.muted,
    };

class _MaintData {
  _MaintData(this.categories, this.stats, this.statuses, this.fitted, this.monthly, this.odometers, this.visits, this.services);
  final Map<ExpenseCategory, double> categories;
  final Map<int, VehicleStat> stats;
  final List<PartStatus> statuses;
  final List<Part> fitted;
  final List<(DateTime, double)> monthly;
  final Map<int, double> odometers;
  final List<VisitSummary> visits;
  final List<ServiceStatus> services;
}

/// Monthly upkeep spend, parts due for a change and what is fitted now.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key, this.embedded = false});

  /// True when shown as a tab on wide layouts (no app bar).
  final bool embedded;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  Future<_MaintData> _load(Repository r) async {
    final period = Period.month(_month);
    final res = await Future.wait([
      r.expenseByCategory(period),
      r.vehicleStats(period),
      r.partStatuses(),
      r.parts(period: period),
      r.maintenanceMonthly(months: 6),
      r.odometers(),
      r.visits(period: period),
      r.serviceStatuses(),
    ]);
    final cats = (res[0] as Map<ExpenseCategory, double>)..removeWhere((c, _) => !c.isMaintenance);
    return _MaintData(
      cats,
      res[1] as Map<int, VehicleStat>,
      res[2] as List<PartStatus>,
      res[3] as List<Part>,
      res[4] as List<(DateTime, double)>,
      res[5] as Map<int, double>,
      res[6] as List<VisitSummary>,
      res[7] as List<ServiceStatus>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final app = context.watch<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final content = Column(children: [
      if (widget.embedded)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Row(children: [
            Expanded(child: Text(s.navParts, style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
            if (app.vehicles.isNotEmpty) RoundIconButton(icon: Icons.add_rounded, filled: true, tooltip: s.add, onTap: () => showMaintenanceAdd(context)),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(alignment: Alignment.centerLeft, child: MonthSwitcher(month: _month, onChanged: (m) => setState(() => _month = m))),
      ),
      Expanded(
        child: Loader<_MaintData>(
          deps: [_month],
          load: _load,
          builder: (context, d) {
            final cost = _CostHero(data: d, month: _month);
            final alerts = _DuePanel(statuses: d.statuses, services: d.services);
            final visits = _VisitsPanel(visits: d.visits, month: _month);
            final byVehicle = _ByVehicle(stats: d.stats);
            final fitted = _FittedPanel(parts: d.fitted, month: _month);
            final installed = _InstalledPanels(statuses: d.statuses, odometers: d.odometers);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: wide
                  ? [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Column(children: [
                            cost,
                            const SizedBox(height: 16),
                            visits,
                            const SizedBox(height: 16),
                            byVehicle,
                            const SizedBox(height: 16),
                            fitted,
                          ]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(children: [alerts, const SizedBox(height: 16), installed])),
                      ]),
                    ]
                  : [
                      Entrance(child: cost),
                      const SizedBox(height: 14),
                      Entrance(index: 1, child: alerts),
                      const SizedBox(height: 14),
                      Entrance(index: 2, child: visits),
                      const SizedBox(height: 14),
                      byVehicle,
                      const SizedBox(height: 14),
                      fitted,
                      const SizedBox(height: 14),
                      installed,
                    ],
            );
          },
        ),
      ),
    ]);

    final body = Contained(child: content);
    if (widget.embedded) return SafeArea(bottom: false, child: body);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.navParts),
        actions: [
          if (app.vehicles.isNotEmpty) IconButton(tooltip: s.add, onPressed: () => showMaintenanceAdd(context), icon: const Icon(Icons.add_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: body,
    );
  }
}

class _CostHero extends StatelessWidget {
  const _CostHero({required this.data, required this.month});
  final _MaintData data;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final total = data.categories.values.fold<double>(0, (a, b) => a + b);
    final cats = data.categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxMonth = data.monthly.fold<double>(1, (a, m) => math.max(a, m.$2));

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: LanePainter(p.onHero.withValues(alpha: 0.05)))),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.build_circle_rounded, color: p.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${s.maintenanceCost} · ${f.monthYear(month)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.onHero.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(f.money(total), style: TextStyle(color: p.onHero, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.4)),
            ),
            Text(s.maintenanceHelp, style: TextStyle(color: p.onHero.withValues(alpha: 0.5), fontSize: 12)),
            if (cats.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final e in cats)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: p.onHero.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(e.key.icon, size: 15, color: e.key.color),
                      const SizedBox(width: 6),
                      Text('${e.key.label(s)} ${f.money(e.value)}', style: TextStyle(color: p.onHero, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ]),
            ],
            const SizedBox(height: 18),
            Text(s.last6Months, style: TextStyle(color: p.onHero.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final (m, v) in data.monthly)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text(f.compact(v), maxLines: 1, style: TextStyle(color: p.onHero.withValues(alpha: 0.6), fontSize: 10)),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: v / maxMonth),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (_, t, _) => Container(
                            height: math.max(4, 44 * t),
                            decoration: BoxDecoration(
                              color: m.year == month.year && m.month == month.month ? p.accent : p.onHero.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(f.monthShort(m.month), maxLines: 1, style: TextStyle(color: p.onHero.withValues(alpha: 0.6), fontSize: 11)),
                      ]),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ByVehicle extends StatelessWidget {
  const _ByVehicle({required this.stats});
  final Map<int, VehicleStat> stats;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final rows = [for (final v in app.vehicles) (v, stats[v.id]?.maintenance ?? 0)]..sort((a, b) => b.$2.compareTo(a.$2));
    final maxV = rows.fold<double>(1, (a, r) => math.max(a, r.$2));
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.byVehicle, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (rows.isEmpty) Text(s.noData, style: TextStyle(color: p.muted)),
        for (final (v, amount) in rows)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicleId: v.id!))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                TypeBadge(v.type, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text(f.money(amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: (amount / maxV).clamp(0, 1), minHeight: 6, color: v.type.color, backgroundColor: p.surfaceAlt),
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

class _DuePanel extends StatelessWidget {
  const _DuePanel({required this.statuses, required this.services});
  final List<PartStatus> statuses;
  final List<ServiceStatus> services;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final due = statuses.where((x) => x.needsAttention).toList();
    final serviceDue = services.where((x) => x.needsAttention).toList();
    final count = due.length + serviceDue.length;
    final overdue = due.any((x) => x.health == DueHealth.overdue) || serviceDue.any((x) => x.health == DueHealth.overdue);
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.notifications_active_rounded, color: count == 0 ? p.income : (overdue ? p.expense : p.warning), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(s.partsDue, style: const TextStyle(fontWeight: FontWeight.w700))),
          if (count > 0) StatusPill(f.digits(count), overdue ? p.expense : p.warning),
        ]),
        const SizedBox(height: 6),
        if (statuses.isEmpty && services.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(s.noPartsBody, style: TextStyle(color: p.muted)))
        else if (count == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, color: p.income, size: 20),
              const SizedBox(width: 8),
              Text(s.allPartsOk, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600)),
            ]),
          )
        else ...[
          for (final st in serviceDue) ServiceDueTile(status: st),
          for (final st in due) PartStatusTile(status: st),
        ],
      ]),
    );
  }
}

/// Garage and service-centre visits in the selected month.
class _VisitsPanel extends StatelessWidget {
  const _VisitsPanel({required this.visits, required this.month});
  final List<VisitSummary> visits;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final total = visits.fold<double>(0, (a, v) => a + v.total);
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.garage_rounded, color: ExpenseCategory.servicing.color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('${s.visitsIn} · ${f.month(month.month)}', style: const TextStyle(fontWeight: FontWeight.w700))),
          if (visits.isNotEmpty) Text(f.money(total), style: TextStyle(fontWeight: FontWeight.w800, color: p.expense)),
        ]),
        const SizedBox(height: 6),
        if (visits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(child: Text(s.noVisitsBody, style: TextStyle(color: p.muted, fontSize: 13))),
              if (app.vehicles.isNotEmpty) ...[
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => openVisitForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(s.add),
                ),
              ],
            ]),
          )
        else
          for (final v in visits) VisitTile(summary: v),
      ]),
    );
  }
}

class _FittedPanel extends StatelessWidget {
  const _FittedPanel({required this.parts, required this.month});
  final List<Part> parts;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final total = parts.fold<double>(0, (a, x) => a + x.cost);
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${s.partsFittedIn} · ${f.month(month.month)}', style: const TextStyle(fontWeight: FontWeight.w700))),
          if (parts.isNotEmpty) Text(f.money(total), style: TextStyle(fontWeight: FontWeight.w800, color: p.expense)),
        ]),
        const SizedBox(height: 6),
        if (parts.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(s.noPartsThisMonth, style: TextStyle(color: p.muted))),
        for (final part in parts)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => openFitting(context, part),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: part.type.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    Text(f.digits(part.installedDate.day), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: part.type.color, height: 1.1)),
                    Text(f.monthShort(part.installedDate.month), style: TextStyle(fontSize: 11, color: part.type.color, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(part.label(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      [
                        app.vehicle(part.vehicleId)?.name ?? '',
                        if (part.subLabel != null) part.subLabel!,
                        if (part.qty != 1) '× ${f.number(part.qty, decimals: 1)}',
                        if (part.shop?.isNotEmpty ?? false) part.shop!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.muted, fontSize: 12.5),
                    ),
                  ]),
                ),
                Text(f.money(part.cost), style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// One panel per vehicle with every part currently fitted.
class _InstalledPanels extends StatelessWidget {
  const _InstalledPanels({required this.statuses, required this.odometers});
  final List<PartStatus> statuses;
  final Map<int, double> odometers;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    if (statuses.isEmpty) {
      return Panel(
        child: EmptyState(
          icon: Icons.build_circle_rounded,
          title: s.noParts,
          body: s.noPartsBody,
          action: app.vehicles.isEmpty
              ? null
              : FilledButton.icon(onPressed: () => showMaintenanceAdd(context), icon: const Icon(Icons.add_rounded), label: Text(s.add)),
        ),
      );
    }
    final panels = <Widget>[];
    for (final v in app.vehicles) {
      final mine = statuses.where((x) => x.part.vehicleId == v.id).toList();
      if (mine.isEmpty) continue;
      final km = odometers[v.id];
      panels.add(Panel(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            TypeBadge(v.type, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(s.installedParts, style: TextStyle(color: p.muted, fontSize: 12)),
              ]),
            ),
            if (km != null) StatusPill('${s.odometerNow} ${f.number(km)} ${s.km}', p.info, icon: Icons.speed_rounded),
            IconButton(tooltip: s.add, onPressed: () => showMaintenanceAdd(context, vehicleId: v.id), icon: const Icon(Icons.add_rounded)),
          ]),
          const SizedBox(height: 4),
          for (final st in mine) PartStatusTile(status: st, showVehicle: false),
        ]),
      ));
    }
    return Column(children: [
      for (var i = 0; i < panels.length; i++) ...[if (i > 0) const SizedBox(height: 12), panels[i]],
    ]);
  }
}

class PartStatusTile extends StatelessWidget {
  const PartStatusTile({super.key, required this.status, this.showVehicle = true});
  final PartStatus status;
  final bool showVehicle;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final part = status.part;
    final color = dueColor(status.health, p);
    final sub = [
      if (showVehicle) app.vehicle(part.vehicleId)?.name ?? '',
      '${s.fitted} ${f.dayMonth(part.installedDate)}${part.installedDate.year != DateTime.now().year ? ' ${f.digits(part.installedDate.year)}' : ''}',
      if (part.installedKm != null) '${f.number(part.installedKm!)} ${s.km}',
      if (part.subLabel != null) part.subLabel!,
      if (part.shop?.isNotEmpty ?? false) part.shop!,
    ].join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openFitting(context, part),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          IconBubble(part.type.icon, part.type.color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(part.label(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
            ]),
          ),
          const SizedBox(width: 8),
          StatusPill(dueLabel(status, s, f), color),
        ]),
      ),
    );
  }
}

// ── Form ──────────────────────────────────────────────────────────────────

class PartFormScreen extends StatefulWidget {
  const PartFormScreen({super.key, this.part, this.vehicleId});
  final Part? part;
  final int? vehicleId;

  @override
  State<PartFormScreen> createState() => _PartFormScreenState();
}

class _PartFormScreenState extends State<PartFormScreen> {
  final _form = GlobalKey<FormState>();
  late int? _vehicleId = widget.part?.vehicleId ?? widget.vehicleId;
  late PartType _type = widget.part?.type ?? PartType.engineOil;
  late DateTime _date = widget.part?.installedDate ?? DateUtils.dateOnly(DateTime.now());
  late final _detail = TextEditingController(text: widget.part?.detail);
  late final _km = TextEditingController(text: _num(widget.part?.installedKm));
  late final _cost = TextEditingController(text: _num(widget.part?.cost));
  late final _everyKm = TextEditingController();
  late final _everyMonths = TextEditingController();
  late final _note = TextEditingController(text: widget.part?.note);
  late final _shop = TextEditingController(text: widget.part?.shop);
  late final _qty = TextEditingController(text: widget.part == null || widget.part!.qty == 1 ? '1' : _num(widget.part!.qty));
  late DateTime? _warranty = widget.part?.warrantyUntil;
  Map<int, double> _odometers = {};
  List<String> _shops = [];
  bool _saving = false;

  static String _num(double? v) => v == null || v == 0 ? '' : (v == v.roundToDouble() ? v.round().toString() : v.toString());

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final part = widget.part;
    app.repo.suggestions('parts', 'shop').then((v) {
      if (mounted) setState(() => _shops = v);
    });
    if (part == null) {
      _vehicleId ??= app.activeVehicles.isNotEmpty ? app.activeVehicles.first.id : (app.vehicles.isNotEmpty ? app.vehicles.first.id : null);
      _applyDefaults();
      app.repo.odometers().then((m) {
        if (!mounted) return;
        setState(() {
          _odometers = m;
          if (_km.text.isEmpty && m[_vehicleId] != null) _km.text = _num(m[_vehicleId]);
        });
      });
    } else {
      if (part.nextKm != null && part.installedKm != null) _everyKm.text = _num(part.nextKm! - part.installedKm!);
      if (part.nextDate != null) {
        final months = ((part.nextDate!.year - part.installedDate.year) * 12 + part.nextDate!.month - part.installedDate.month);
        _everyMonths.text = months > 0 ? '$months' : '';
      }
    }
  }

  void _applyDefaults() {
    _everyKm.text = _type.km?.toString() ?? '';
    _everyMonths.text = _type.months?.toString() ?? '';
  }

  @override
  void dispose() {
    for (final c in [_detail, _km, _cost, _everyKm, _everyMonths, _note, _shop, _qty]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime? get _nextDate {
    final m = parseAmount(_everyMonths.text)?.round();
    if (m == null || m <= 0) return null;
    return DateTime(_date.year, _date.month + m, _date.day);
  }

  double? get _nextKm {
    final km = parseAmount(_km.text), every = parseAmount(_everyKm.text);
    if (km == null || every == null || every <= 0) return null;
    return km + every;
  }

  Future<void> _save() async {
    final s = context.s;
    if (_vehicleId == null) {
      toast(context, s.noVehicleYet, icon: Icons.info_outline_rounded);
      return;
    }
    if (!_form.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final app = context.read<AppState>();
    final part = Part(
      id: widget.part?.id,
      vehicleId: _vehicleId!,
      type: _type,
      detail: _detail.text,
      installedDate: _date,
      installedKm: parseAmount(_km.text),
      cost: parseAmount(_cost.text) ?? 0,
      nextDate: _nextDate,
      nextKm: _nextKm,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      visitId: widget.part?.visitId,
      shop: _shop.text.trim().isEmpty ? null : _shop.text.trim(),
      qty: parseAmount(_qty.text) ?? 1,
      warrantyUntil: _warranty,
    );
    try {
      await app.mutate((r) => r.savePart(part));
      if (!mounted) return;
      toast(context, s.saved);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, s.somethingWrong(e), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final s = context.s;
    if (!await confirm(context, title: s.deletePart, body: s.deletePartBody)) return;
    if (!mounted) return;
    final nav = Navigator.of(context);
    await context.read<AppState>().mutate((r) => r.deletePart(widget.part!.id!));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final app = context.watch<AppState>();
    String? numValidator(String? v) => v != null && v.trim().isNotEmpty && parseAmount(v) == null ? s.invalidNumber : null;
    final nextDate = _nextDate, nextKm = _nextKm;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.part == null ? s.addPart : s.editPart),
        actions: [
          if (widget.part != null) IconButton(tooltip: s.delete, onPressed: _delete, icon: Icon(Icons.delete_outline_rounded, color: p.expense)),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _form,
        child: Contained(
          maxWidth: 640,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              _label(s.selectVehicle),
              if (app.vehicles.isEmpty)
                Text(s.noVehicleYet, style: TextStyle(color: p.expense, fontWeight: FontWeight.w600))
              else
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final v in app.vehicles)
                    ChoiceTag(
                      label: v.name,
                      icon: v.type.icon,
                      color: v.type.color,
                      selected: v.id == _vehicleId,
                      onTap: () => setState(() {
                        final wasAuto = _km.text == _num(_odometers[_vehicleId]);
                        _vehicleId = v.id;
                        if (widget.part == null && wasAuto) _km.text = _num(_odometers[v.id]);
                      }),
                    ),
                ]),
              const SizedBox(height: 20),
              _label(s.whichPart),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in PartType.values)
                  ChoiceTag(
                    label: t.label(s),
                    icon: t.icon,
                    color: t.color,
                    selected: t == _type,
                    onTap: () => setState(() {
                      _type = t;
                      _applyDefaults();
                    }),
                  ),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: _detail,
                decoration: InputDecoration(
                  labelText: _type == PartType.other ? s.partName : s.partDetail,
                  hintText: _type == PartType.other ? null : s.partDetailHint,
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                ),
                validator: (v) => _type == PartType.other && (v == null || v.trim().isEmpty) ? s.required : null,
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: DateFormField(label: s.fittedOn, value: _date, onPick: (d) => setState(() => _date = d))),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _km,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: s.kmAtFitting, prefixIcon: const Icon(Icons.speed_rounded)),
                    validator: numValidator,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: _qty,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: s.qty),
                    validator: numValidator,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _cost,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.partCost, prefixText: '৳ ', prefixIcon: const Icon(Icons.sell_outlined)),
                    validator: numValidator,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SuggestField(controller: _shop, suggestions: _shops, label: s.shop, hint: s.shopHint, icon: Icons.storefront_outlined),
              const SizedBox(height: 12),
              WarrantyField(value: _warranty, onChanged: (d) => setState(() => _warranty = d)),
              const SizedBox(height: 20),
              _label(s.nextChange),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: _everyKm,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: s.changeAfterKm, suffixText: s.km, isDense: true),
                    validator: numValidator,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _everyMonths,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: s.changeAfterMonths, suffixText: s.months, isDense: true),
                    validator: numValidator,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _type.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Icon(Icons.notifications_active_rounded, color: _type.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: nextDate == null && nextKm == null
                        ? Text(s.noSchedule, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600))
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.nextChange, style: TextStyle(color: p.muted, fontSize: 12)),
                            Text(
                              [if (nextDate != null) f.date(nextDate), if (nextKm != null) '${f.number(nextKm)} ${s.km}'].join(' ${s.or} '),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            if (nextDate != null && nextKm != null) Text(s.whicheverFirst, style: TextStyle(color: p.muted, fontSize: 12)),
                          ]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              TextFormField(controller: _note, maxLines: 2, decoration: InputDecoration(labelText: s.note, prefixIcon: const Icon(Icons.edit_note_rounded))),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Contained(
          maxWidth: 640,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4)) : Text(s.save),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(t, style: TextStyle(color: context.pal.muted, fontWeight: FontWeight.w600, fontSize: 13)),
      );
}
