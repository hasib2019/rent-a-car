import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/l10n_personal.dart';
import '../../core/theme.dart';
import '../../data/forecast.dart';
import '../../data/fuel_report.dart';
import '../../data/models.dart';
import '../../data/ownership.dart';
import '../../data/repository.dart';
import '../../services/analytics.dart';
import '../../services/settings.dart';
import '../../state/app_state.dart';
import '../routes.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/fuel_charts.dart';
import '../widgets/ledger_tile.dart';
import 'documents_screen.dart';
import 'driver_screens.dart';
import 'entry_screen.dart';
import 'forecast_screen.dart';
import 'fuel_screens.dart';
import 'maintenance_screen.dart';
import 'mode_screen.dart';
import 'office_report_screen.dart';
import 'ownership_widgets.dart';
import 'service_screens.dart';
import 'settings_screen.dart';
import 'vehicle_screens.dart';

/// The car the personal screens are showing: the one picked last, else the
/// first car in use. Pass `listen: false` outside build.
Vehicle? selectedCar(BuildContext context, {bool listen = true}) {
  final app = Provider.of<AppState>(context, listen: listen);
  final id = Provider.of<Settings>(context, listen: listen).personalCarId;
  return app.vehicle(id) ?? app.activeVehicles.firstOrNull ?? app.vehicles.firstOrNull;
}

/// "Car A · Car B · +" chips that pick the car every personal screen shows.
class CarSwitcher extends StatelessWidget {
  const CarSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final settings = context.read<Settings>();
    final car = selectedCar(context);
    return SizedBox(
      height: 46,
      child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: [
        for (final v in app.vehicles) ...[
          ChoiceTag(label: v.name, icon: v.type.icon, color: v.type.color, selected: v.id == car?.id, onTap: () => settings.setPersonalCarId(v.id)),
          const SizedBox(width: 8),
        ],
        ChoiceTag(label: context.s.addCar, icon: Icons.add_rounded, selected: false, onTap: () => openNewVehicle(context)),
      ]),
    );
  }
}

/// First-run card: add your car, or look around with sample data.
class PersonalWelcome extends StatelessWidget {
  const PersonalWelcome({super.key});

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
                for (final (icon, color) in [
                  (VehicleType.car.icon, VehicleType.car.color),
                  (Icons.local_gas_station_rounded, ExpenseCategory.fuel.color),
                  (Icons.build_circle_rounded, ExpenseCategory.servicing.color),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                  ),
              ]),
              const SizedBox(height: 22),
              Text(s.personalWelcomeTitle, style: context.text.headlineMedium?.copyWith(color: p.onHero, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(s.personalWelcomeBody, style: TextStyle(color: p.onHero.withValues(alpha: 0.7), height: 1.4)),
              const SizedBox(height: 22),
              Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent),
                  onPressed: () => openNewVehicle(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(s.addCar),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: p.onHero, side: BorderSide(color: p.onHero.withValues(alpha: 0.25))),
                  onPressed: () async {
                    // Show the demo's main car, not a car id left from earlier books.
                    await context.read<Settings>().setPersonalCarId(null);
                    if (context.mounted) await context.read<AppState>().loadDemo(bangla: s.bn);
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

// ── Dashboard ─────────────────────────────────────────────────────────────

class _CarData {
  _CarData({
    required this.fuel,
    required this.month,
    required this.lastMonth,
    required this.year,
    required this.allTime,
    required this.measured,
    required this.distance,
    required this.since,
    required this.monthly,
    required this.categories,
    required this.papers,
    required this.parts,
    required this.visits,
    required this.service,
    required this.recent,
    required this.odometer,
    required this.forecast,
    required this.measuredFrom,
    required this.salaries,
    required this.officeMonth,
  });

  final List<FuelReport> fuel;
  final Totals month;
  final Totals lastMonth;
  final Totals year;
  final Totals allTime;

  /// Everything spent while the odometer was being logged, and the km covered.
  final Totals measured;
  final double? distance;

  /// First day with a cost on record.
  final DateTime? since;
  final List<MonthPoint> monthly;
  final Map<ExpenseCategory, double> categories;
  final List<Paper> papers;
  final List<PartStatus> parts;
  final List<VisitSummary> visits;
  final ServiceStatus? service;
  final List<LedgerEntry> recent;
  final double? odometer;
  final CostForecast forecast;

  /// First odometer reading in the fuel log (start of [measured]).
  final DateTime measuredFrom;
  final List<SalaryAccount> salaries;

  /// This month's costs marked for office work.
  final double officeMonth;

  FuelReport? get mainFuel => fuel.firstOrNull;
}

Future<_CarData> _loadCar(Repository r, Vehicle car) async {
  final id = car.id!;
  final today = DateUtils.dateOnly(DateTime.now());
  final fills = await r.fuelFills(vehicleId: id);
  final odoFills = fills.where((e) => e.odometer != null).toList();
  final measuredFrom = odoFills.isEmpty ? today : odoFills.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
  final odos = odoFills.map((e) => e.odometer!);
  final res = await Future.wait([
    r.totals(Period.thisMonth(), vehicleId: id),
    r.totals(Period.lastMonth(), vehicleId: id),
    r.totals(Period.thisYear(), vehicleId: id),
    r.totals(Period.allTime(), vehicleId: id),
    r.totals(Period(measuredFrom, today), vehicleId: id),
    r.monthly(months: 6, vehicleId: id),
    r.expenseByCategory(Period.thisYear(), vehicleId: id),
    r.papers(vehicleId: id),
    r.partStatuses(vehicleId: id),
    r.visits(vehicleId: id, limit: 4),
    r.serviceStatuses(vehicleId: id),
    r.ledger(vehicleId: id, limit: 6),
    r.odometers(),
    r.ledger(vehicleId: id, incomeOnly: false),
    r.costForecast(id),
    r.drivers(),
    r.officeExpenses(Period.thisMonth(), vehicleId: id),
  ]);
  final salaried = (res[15] as List<Driver>).where((d) => d.active && d.monthlySalary > 0).toList();
  final salaries = [for (final d in salaried) SalaryAccount.build(d, await r.driverPayments(d.id!))];
  final all = res[13] as List<LedgerEntry>;
  return _CarData(
    fuel: FuelReport.byFuel(fills, fallback: defaultFuel(car)),
    month: res[0] as Totals,
    lastMonth: res[1] as Totals,
    year: res[2] as Totals,
    allTime: res[3] as Totals,
    measured: res[4] as Totals,
    distance: odoFills.length < 2 ? null : odos.reduce(math.max) - odos.reduce(math.min),
    since: all.isEmpty ? null : all.last.date,
    monthly: res[5] as List<MonthPoint>,
    categories: res[6] as Map<ExpenseCategory, double>,
    papers: res[7] as List<Paper>,
    parts: res[8] as List<PartStatus>,
    visits: res[9] as List<VisitSummary>,
    service: (res[10] as List<ServiceStatus>).firstOrNull,
    recent: res[11] as List<LedgerEntry>,
    odometer: (res[12] as Map<int, double>)[id],
    forecast: res[14] as CostForecast,
    measuredFrom: measuredFrom,
    salaries: salaries,
    officeMonth: (res[16] as List<Expense>).fold<double>(0, (a, e) => a + e.amount),
  );
}

/// The owner's own car: what it costs, how it runs, what's due.
class PersonalHomeScreen extends StatelessWidget {
  const PersonalHomeScreen({super.key, required this.onOpenFuel, required this.onOpenParts, required this.onOpenLedger});
  final VoidCallback onOpenFuel;
  final VoidCallback onOpenParts;
  final VoidCallback onOpenLedger;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    final s = context.s;
    final p = context.pal;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final car = selectedCar(context);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 18),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.greeting(DateTime.now().hour), style: TextStyle(color: p.muted, fontWeight: FontWeight.w600)),
            Text(
              settings.ownerName.isEmpty ? s.myCar : settings.ownerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ]),
        ),
        const ModeSwitchButton(),
        if (!wide) ...[
          const SizedBox(width: 8),
          RoundIconButton(icon: Icons.tune_rounded, tooltip: s.settings, onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const SettingsScreen()))),
        ],
      ]),
    );

    if (car == null) {
      return SafeArea(
        bottom: false,
        child: Contained(child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), children: [header, const PersonalWelcome()])),
      );
    }
    return SafeArea(
      bottom: false,
      child: _CarDashboard(car: car, header: header, onOpenFuel: onOpenFuel, onOpenParts: onOpenParts, onOpenLedger: onOpenLedger),
    );
  }
}

/// One car opened from the car list (wide layouts), with the same dashboard.
class PersonalCarScreen extends StatelessWidget {
  const PersonalCarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final car = selectedCar(context);
    if (car == null) return const Scaffold();
    void push(Widget page) => Navigator.of(context).push(AppRoute(builder: (_) => page));
    return Scaffold(
      appBar: AppBar(
        title: Text(car.name),
        actions: [
          IconButton(tooltip: s.edit, icon: const Icon(Icons.edit_rounded), onPressed: () => push(VehicleFormScreen(vehicle: car))),
          const SizedBox(width: 8),
        ],
      ),
      body: _CarDashboard(car: car, onOpenFuel: () => push(const FuelLogScreen()), onOpenParts: () => push(const MaintenanceScreen())),
    );
  }
}

class _CarDashboard extends StatelessWidget {
  const _CarDashboard({required this.car, required this.onOpenFuel, required this.onOpenParts, this.onOpenLedger, this.header});
  final Vehicle car;
  final VoidCallback onOpenFuel;
  final VoidCallback onOpenParts;
  final VoidCallback? onOpenLedger;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final p = context.pal;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Loader<_CarData>(
      deps: [car.id],
      load: (r) => _loadCar(r, car),
      builder: (context, d) {
        final hero = _CarHero(car: car, data: d);
        final actions = _QuickActions(car: car);
        final attention = _CarAttention(car: car, data: d, onOpenParts: onOpenParts);
        final fuel = d.mainFuel == null || d.mainFuel!.isEmpty ? _FirstFuel(car: car) : FuelHero(report: d.mainFuel!, onTap: onOpenFuel);
        final running = _RunningCost(data: d);
        final savings = FuelSavings.of(d.fuel);
        final forecast = ForecastCard(forecast: d.forecast, vehicle: car);
        final budget = BudgetCard(car: car, spent: d.month.expense);
        final value = CarValueCard(
          car: car,
          distance: d.distance,
          measuredDays: DateUtils.dateOnly(DateTime.now()).difference(d.measuredFrom).inDays,
          runningPerKm: d.distance == null || d.distance! <= 0 ? null : d.measured.expense / d.distance!,
        );
        final salary = SalaryCard(accounts: d.salaries, vehicleId: car.id!);
        final office = OfficeClaimCard(vehicleId: car.id!, thisMonth: d.officeMonth);
        final trend = Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.spendTrend, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            MonthBars(points: [for (final m in d.monthly) (m.month, m.expense)], color: p.expense, label: context.fmt.money),
          ]),
        );
        final donut = Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.whereMoneyGoes} · ${context.fmt.digits(DateTime.now().year)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (d.categories.isEmpty) Text(s.noCostYet, style: TextStyle(color: p.muted)) else CategoryDonut(data: d.categories),
          ]),
        );
        final service = VehicleServiceBookCard(vehicleId: car.id!, visits: d.visits, next: d.service);
        final parts = VehiclePartsCard(vehicleId: car.id!, statuses: d.parts);
        final papers = VehiclePapersCard(vehicleId: car.id!, papers: d.papers);
        final info = VehicleInfoCard(vehicle: car, odometer: d.odometer);
        final recent = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(s.recentEntries, action: onOpenLedger == null ? null : s.seeAll, onAction: onOpenLedger),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: d.recent.isEmpty
                ? EmptyState(icon: Icons.receipt_long_rounded, title: s.noCostYet)
                : Column(children: [for (final e in d.recent) LedgerTile(e, showDate: true)]),
          ),
        ]);
        const gap = SizedBox(height: 14);

        return Contained(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              ?header,
              if (app.vehicles.length > 1) ...[const CarSwitcher(), gap],
              if (wide) ...[
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 6, child: Column(children: [Entrance(child: hero), gap, actions, gap, budget])),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: Entrance(index: 1, child: fuel)),
                ]),
                attention,
                gap,
                if (savings != null) ...[SavingsCard(savings: savings, vehicle: car), gap],
                running,
                gap,
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(children: [forecast, gap, trend, gap, service, gap, parts])),
                  const SizedBox(width: 16),
                  Expanded(child: Column(children: [salary, gap, office, gap, value, gap, donut, gap, papers, gap, info])),
                ]),
              ] else ...[
                Entrance(child: hero),
                gap,
                Entrance(index: 1, child: actions),
                gap,
                Entrance(index: 2, child: budget),
                Entrance(index: 2, child: attention),
                gap,
                Entrance(index: 2, child: fuel),
                gap,
                if (savings != null) ...[SavingsCard(savings: savings, vehicle: car), gap],
                Entrance(index: 3, child: running),
                gap,
                value,
                gap,
                salary,
                gap,
                office,
                gap,
                forecast,
                gap,
                trend,
                gap,
                donut,
                gap,
                service,
                gap,
                parts,
                gap,
                papers,
                gap,
                info,
              ],
              recent,
            ],
          ),
        );
      },
    );
  }
}

/// The car in its own colours: plate, odometer and this month's spend.
class _CarHero extends StatelessWidget {
  const _CarHero({required this.car, required this.data});
  final Vehicle car;
  final _CarData data;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final spent = data.month.expense;
    final before = data.lastMonth.expense;
    final change = before <= 0 ? null : (spent - before) / before;
    final color = car.type.color;

    return Pressable(
      onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => VehicleFormScreen(vehicle: car))),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, Color.lerp(color, Colors.black, 0.5)!]),
        ),
        child: Stack(children: [
          Positioned(right: -30, bottom: -40, child: Icon(car.type.icon, size: 200, color: Colors.white.withValues(alpha: 0.12))),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _chip(car.type.label(s), Colors.white.withValues(alpha: 0.2)),
                if (car.fuel != null) ...[const SizedBox(width: 8), _chip(car.fuel!.label(s), Colors.black.withValues(alpha: 0.2))],
                const Spacer(),
                if (data.odometer != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.speed_rounded, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text('${f.number(data.odometer!)} ${s.km}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
              ]),
              const SizedBox(height: 14),
              Text(car.model?.isNotEmpty == true ? car.model! : car.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
              const SizedBox(height: 10),
              NumberPlate(regNo: car.regNo, scale: 1.15),
              const SizedBox(height: 18),
              Text(s.spentThisMonth, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(f.money(spent), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1.1)),
                  ),
                ),
                if (change != null) ...[
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _chip('${change > 0 ? '▲' : '▼'} ${f.percent(change.abs())} ${s.vsLastMonth}', Colors.black.withValues(alpha: 0.22)),
                  ),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String t, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.car});
  final Vehicle car;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    Widget btn(IconData icon, Color color, String label, VoidCallback onTap) => Expanded(
          child: Panel(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(children: [
              IconBubble(icon, color, size: 40),
              const SizedBox(height: 8),
              Text('+ $label', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        );
    return Row(children: [
      btn(Icons.local_gas_station_rounded, ExpenseCategory.fuel.color, s.fuel, () => openFuelForm(context, vehicleId: car.id)),
      const SizedBox(width: 8),
      btn(Icons.garage_rounded, ExpenseCategory.servicing.color, s.serviceShort, () => openVisitForm(context, vehicleId: car.id)),
      const SizedBox(width: 8),
      btn(PartType.engineOil.icon, PartType.engineOil.color, s.partsShort, () => openPartForm(context, vehicleId: car.id)),
      const SizedBox(width: 8),
      btn(Icons.receipt_long_rounded, ExpenseCategory.repair.color, s.costShort, () => openEntry(context, EntryMode.expense, vehicleId: car.id)),
    ]);
  }
}

/// Papers, service, parts and fuel warnings for this car.
class _CarAttention extends StatelessWidget {
  const _CarAttention({required this.car, required this.data, required this.onOpenParts});
  final Vehicle car;
  final _CarData data;
  final VoidCallback onOpenParts;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final papers = data.papers.where((x) => x.daysLeft <= 30).toList();
    final parts = data.parts.where((x) => x.needsAttention).toList();
    final service = data.service?.needsAttention == true ? data.service : null;
    final fuel = data.mainFuel;
    final pump = fuel?.stations().where((x) => x.suspect).firstOrNull;

    final cards = <Widget>[
      if (pump != null)
        _card(context, Icons.ev_station_rounded, p.expense, s.pumpSuspectTitle, f.percent(pump.shortfall), [s.pumpSuspectBody(pump.name, f.percent(pump.shortfall))], null),
      if (fuel != null && fuel.mileageAlert)
        _card(context, Icons.trending_down_rounded, p.expense, s.mileageDropTitle, f.percent(fuel.mileageDrop!), [s.mileageDropBody(f.percent(fuel.mileageDrop!))], null),
      if (service != null)
        _card(context, Icons.event_repeat_rounded, service.health == DueHealth.overdue ? p.expense : p.warning, s.serviceDue, '', [dueLabel(service, s, f)], onOpenParts),
      if (papers.isNotEmpty)
        _card(context, Icons.event_busy_rounded, p.expense, s.paperExpiring, f.digits(papers.length), [for (final x in papers.take(3)) '${x.type.label(s)} · ${s.expiresIn(x.daysLeft)}'],
            () => Navigator.of(context).push(AppRoute(builder: (_) => const DocumentsScreen()))),
      if (parts.isNotEmpty)
        _card(context, Icons.build_circle_rounded, parts.any((x) => x.health == DueHealth.overdue) ? p.expense : p.warning, s.partsDueShort, f.digits(parts.length),
            [for (final x in parts.take(3)) '${x.part.label(s)} · ${dueLabel(x, s, f)}'], onOpenParts),
      if (fuel != null && fuel.overdueLog())
        _card(context, Icons.local_gas_station_rounded, p.warning, s.fuelReminderTitle, '', [s.fuelReminderBody(fuel.daysSinceLastFill()!)],
            () => openFuelForm(context, vehicleId: car.id)),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(s.attention),
      for (var i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(height: 12), cards[i]],
    ]);
  }

  Widget _card(BuildContext context, IconData icon, Color color, String title, String value, List<String> lines, VoidCallback? onTap) {
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
                child: Text(l, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.3)),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _FirstFuel extends StatelessWidget {
  const _FirstFuel({required this.car});
  final Vehicle car;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    return Panel(
      onTap: () => openFuelForm(context, vehicleId: car.id),
      child: Row(children: [
        IconBubble(Icons.local_gas_station_rounded, ExpenseCategory.fuel.color, size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.noFuelTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
            const SizedBox(height: 4),
            Text(s.noFuelBody, style: TextStyle(color: p.muted, fontSize: 13, height: 1.35)),
          ]),
        ),
        const SizedBox(width: 8),
        Icon(Icons.add_circle_rounded, color: p.accent, size: 34),
      ]),
    );
  }
}

/// What owning the car costs: in total, per day and per km.
class _RunningCost extends StatelessWidget {
  const _RunningCost({required this.data});
  final _CarData data;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final total = data.allTime.expense;
    final days = data.since == null ? 0 : DateUtils.dateOnly(DateTime.now()).difference(data.since!).inDays + 1;
    final perKm = data.distance == null || data.distance! <= 0 ? null : data.measured.expense / data.distance!;
    final fuelKm = data.mainFuel?.costPerKm;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(s.runningCost),
      GridView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: wide ? 4 : 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 112),
        children: [
          StatBlock(label: s.totalOwnership, value: f.money(total), icon: Icons.account_balance_wallet_rounded, color: p.expense, sub: data.since == null ? null : f.date(data.since!)),
          StatBlock(
            label: s.perDayCost,
            value: days == 0 ? '—' : f.money((total / days).roundToDouble()),
            icon: Icons.calendar_today_rounded,
            sub: '${s.thisYear}: ${f.money(data.year.expense)}',
          ),
          StatBlock(
            label: s.allCostPerKm,
            value: perKm == null ? '—' : '৳${f.number(perKm, decimals: 2)}',
            icon: Icons.route_rounded,
            sub: data.distance == null ? null : '${f.number(data.distance!)} ${s.km}',
          ),
          StatBlock(label: s.fuelPerKm, value: fuelKm == null ? '—' : '৳${f.number(fuelKm, decimals: 2)}', icon: Icons.local_gas_station_rounded, color: ExpenseCategory.fuel.color),
        ],
      ),
    ]);
  }
}

// ── Quick add ─────────────────────────────────────────────────────────────

/// Pays the (first) salaried driver, or adds one when there is none yet.
Future<void> _payDriver(BuildContext context, Vehicle? car) async {
  final app = context.read<AppState>();
  final driver = app.drivers.where((d) => d.active && d.monthlySalary > 0).firstOrNull;
  if (driver == null || car == null) {
    await openNewDriver(context);
    return;
  }
  await showSalarySheet(context, driver: driver, vehicleId: car.id!, suggest: driver.monthlySalary);
}

Future<void> _editBudget(BuildContext context, Vehicle? car) async {
  if (car == null) return;
  final s = S.read(context);
  final v = await askAmount(context, title: s.budget, helper: s.budgetHint, initial: car.monthlyBudget, removeLabel: s.removeBudget);
  if (v == null || !context.mounted) return;
  await context.read<AppState>().mutate((r) => r.saveVehicle(Vehicle.fromMap({...car.toMap(), 'monthly_budget': v <= 0 ? null : v})));
}

/// The + sheet in personal mode: fuel first, then the other things a car costs.
Future<void> showPersonalQuickAdd(BuildContext context) {
  Analytics.instance.screen('quick_add_personal');
  final car = selectedCar(context, listen: false);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final s = ctx.s;
      final p = ctx.pal;
      void go(VoidCallback f) {
        Navigator.pop(ctx);
        f();
      }

      Widget option(IconData icon, Color color, String title, String sub, VoidCallback onTap) => Panel(
            onTap: () => go(onTap),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconBubble(icon, color, size: 44),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(sub, maxLines: 2, style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.25)),
            ]),
          );

      return SafeArea(
        child: Contained(
          maxWidth: 560,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 14), child: Text(s.quickAdd, style: ctx.text.headlineSmall)),
              Pressable(
                onTap: () => go(() => openFuelForm(context, vehicleId: car?.id)),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(kRadius)),
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: p.onAccent, borderRadius: BorderRadius.circular(16)),
                      child: Icon(Icons.local_gas_station_rounded, color: p.accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.addFuel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: p.onAccent)),
                        Text(s.addFuelSub, style: TextStyle(color: p.onAccent.withValues(alpha: 0.7), fontSize: 13)),
                      ]),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: p.onAccent),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  option(Icons.garage_rounded, ExpenseCategory.servicing.color, s.visitQuick, s.visitQuickSub, () => openVisitForm(context, vehicleId: car?.id)),
                  option(PartType.engineOil.icon, PartType.engineOil.color, s.partFitted, s.partFittedSub, () => openPartForm(context, vehicleId: car?.id)),
                  option(Icons.receipt_long_rounded, ExpenseCategory.repair.color, s.otherCostPersonal, s.otherCostPersonalSub,
                      () => openEntry(context, EntryMode.expense, vehicleId: car?.id)),
                  option(Icons.event_note_rounded, ExpenseCategory.papers.color, s.papers, s.paperExpirySub, () => showPaperSheet(context, vehicleId: car?.id)),
                  option(Icons.badge_rounded, ExpenseCategory.salary.color, s.salaryDriverQuick, s.salaryDriverQuickSub, () => _payDriver(context, car)),
                  option(Icons.account_balance_wallet_rounded, p.info, s.budget, s.setBudgetSub, () => _editBudget(context, car)),
                ],
              ),
            ]),
          ),
        ),
      );
    },
  );
}
