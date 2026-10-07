import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../state/app_state.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/ledger_tile.dart';
import 'documents_screen.dart';
import 'driver_screens.dart';
import 'entry_screen.dart';

enum FleetTab { vehicles, drivers }

/// Vehicles and drivers, switchable with a pill toggle.
class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  FleetTab _tab = FleetTab.vehicles;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;

    return SafeArea(
      bottom: false,
      child: Contained(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(children: [
              Expanded(child: Text(s.navFleet, style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
              RoundIconButton(
                icon: Icons.add_rounded,
                filled: true,
                tooltip: _tab == FleetTab.vehicles ? s.addVehicle : s.addDriver,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _tab == FleetTab.vehicles ? const VehicleFormScreen() : const DriverFormScreen(),
                )),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PillToggle<FleetTab>(
              values: FleetTab.values,
              selected: _tab,
              label: (t) => t == FleetTab.vehicles
                  ? '${s.vehicles} · ${f.digits(app.vehicles.length)}'
                  : '${s.drivers} · ${f.digits(app.drivers.length)}',
              onChanged: (t) => setState(() => _tab = t),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _tab == FleetTab.vehicles ? const _VehicleList(key: ValueKey('v')) : const DriverList(key: ValueKey('d')),
            ),
          ),
        ]),
      ),
    );
  }
}

class _VehicleList extends StatelessWidget {
  const _VehicleList({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    if (app.vehicles.isEmpty) {
      return EmptyState(
        icon: Icons.directions_car_filled_rounded,
        title: s.noVehicles,
        action: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VehicleFormScreen())),
          icon: const Icon(Icons.add_rounded),
          label: Text(s.addVehicle),
        ),
      );
    }
    return Loader<Map<int, VehicleStat>>(
      load: (r) => r.vehicleStats(Period.thisMonth()),
      builder: (context, stats) => LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
        final items = [for (var i = 0; i < app.vehicles.length; i++) Entrance(index: i, child: VehicleCard(vehicle: app.vehicles[i], stat: stats[app.vehicles[i].id]))];
        if (cols == 1) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => items[i],
          );
        }
        return GridView.count(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.75,
          children: items,
        );
      }),
    );
  }
}

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key, required this.vehicle, this.stat});
  final Vehicle vehicle;
  final VehicleStat? stat;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final v = vehicle;
    final driver = app.driverOf(v);
    final profit = stat?.profit ?? 0;

    return Panel(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicleId: v.id!))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TypeBadge(v.type, size: 50),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))),
                if (!v.isActive) ...[const SizedBox(width: 8), StatusPill(v.status.label(s), v.status == VehicleStatus.garage ? p.warning : p.muted)],
              ]),
              Text([v.type.label(s), if (v.model?.isNotEmpty ?? false) v.model!].join(' · '),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 13)),
              const SizedBox(height: 8),
              NumberPlate(regNo: v.regNo, color: v.type.color),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(child: _kv(context, s.driver, driver?.name ?? s.noDriver)),
            Expanded(child: _kv(context, s.target, '${f.money(v.dailyTarget)}${s.perDay}')),
            Expanded(child: _kv(context, '${s.profit} · ${f.monthShort(DateTime.now().month)}', f.money(profit), color: profit >= 0 ? p.income : p.expense)),
          ]),
        ),
      ]),
    );
  }

  Widget _kv(BuildContext context, String k, String v, {Color? color}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.pal.muted, fontSize: 11.5)),
        Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: color)),
      ]);
}

// ── Detail ────────────────────────────────────────────────────────────────

class _VehicleData {
  _VehicleData(this.lifetime, this.month, this.monthly, this.categories, this.mileage, this.papers, this.history);
  final VehicleStat lifetime;
  final VehicleStat month;
  final List<MonthPoint> monthly;
  final Map<ExpenseCategory, double> categories;
  final double? mileage;
  final List<Paper> papers;
  final List<LedgerEntry> history;
}

Future<_VehicleData> _loadVehicle(Repository r, int id) async {
  final res = await Future.wait([
    r.vehicleStats(Period.allTime()),
    r.vehicleStats(Period.thisMonth()),
    r.monthly(months: 6, vehicleId: id),
    r.expenseByCategory(Period.allTime(), vehicleId: id),
    r.mileage(id),
    r.papers(vehicleId: id),
    r.ledger(vehicleId: id, limit: 40),
  ]);
  return _VehicleData(
    (res[0] as Map<int, VehicleStat>)[id] ?? VehicleStat(vehicleId: id),
    (res[1] as Map<int, VehicleStat>)[id] ?? VehicleStat(vehicleId: id),
    res[2] as List<MonthPoint>,
    res[3] as Map<ExpenseCategory, double>,
    res[4] as double?,
    res[5] as List<Paper>,
    res[6] as List<LedgerEntry>,
  );
}

class VehicleDetailScreen extends StatelessWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});
  final int vehicleId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final v = app.vehicle(vehicleId);
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    if (v == null) return const Scaffold();
    final driver = app.driverOf(v);

    return Scaffold(
      appBar: AppBar(
        title: Text(v.name),
        actions: [
          IconButton(
            tooltip: s.edit,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VehicleFormScreen(vehicle: v))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Loader<_VehicleData>(
        load: (r) => _loadVehicle(r, vehicleId),
        deps: [vehicleId],
        builder: (context, d) {
          final wide = MediaQuery.sizeOf(context).width >= 900;
          final header = Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [v.type.color, Color.lerp(v.type.color, Colors.black, 0.45)!],
              ),
            ),
            child: Stack(children: [
              Positioned(right: -30, bottom: -40, child: Icon(v.type.icon, size: 200, color: Colors.white.withValues(alpha: 0.12))),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(v.type.label(s), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(v.status.label(s), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text(v.model?.isNotEmpty == true ? v.model! : v.name,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                  const SizedBox(height: 12),
                  NumberPlate(regNo: v.regNo, scale: 1.3),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      if (driver != null) Avatar(name: driver.name, initials: driver.initials, size: 38) else const Icon(Icons.person_off_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: driver == null ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DriverDetailScreen(driverId: driver.id!))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.driver, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5)),
                            Text(driver?.name ?? s.noDriver, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                      if (driver?.phone?.isNotEmpty ?? false)
                        IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                          onPressed: () => launchUrl(Uri(scheme: 'tel', path: driver!.phone)),
                          icon: const Icon(Icons.call_rounded, size: 20),
                        ),
                    ]),
                  ),
                ]),
              ),
            ]),
          );

          final actions = Row(children: [
            Expanded(child: _ActionBtn(icon: Icons.local_gas_station_rounded, label: s.fuel, color: ExpenseCategory.fuel.color, onTap: () => openEntry(context, EntryMode.fuel, vehicleId: vehicleId))),
            const SizedBox(width: 10),
            Expanded(child: _ActionBtn(icon: Icons.build_circle_rounded, label: s.expense, color: ExpenseCategory.servicing.color, onTap: () => openEntry(context, EntryMode.expense, vehicleId: vehicleId))),
            const SizedBox(width: 10),
            Expanded(child: _ActionBtn(icon: Icons.route_rounded, label: s.income, color: p.income, onTap: () => openEntry(context, EntryMode.trip, vehicleId: vehicleId))),
          ]);

          final month = d.month;
          final statsGrid = GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 116),
            children: [
              StatBlock(label: '${s.income} · ${s.thisMonth}', value: f.money(month.income), color: p.income, icon: Icons.south_west_rounded),
              StatBlock(label: '${s.expense} · ${s.thisMonth}', value: f.money(month.expense), color: p.expense, icon: Icons.north_east_rounded),
              StatBlock(label: '${s.profit} · ${s.thisMonth}', value: f.money(month.profit), icon: Icons.trending_up_rounded, color: month.profit >= 0 ? p.ink : p.expense),
              StatBlock(
                label: s.avgDaily,
                value: f.money(month.activeDays == 0 ? 0 : month.income / month.activeDays),
                icon: Icons.calendar_view_day_rounded,
                sub: '${f.digits(month.activeDays)} ${s.workingDays}',
              ),
            ],
          );

          final payback = _PaybackCard(vehicle: v, lifetime: d.lifetime);

          final chart = Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.monthlyTrend, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            MonthlyBars(points: d.monthly, height: 200),
          ]));

          final costs = Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('${s.expenseBreakdown} · ${s.allTime}', style: const TextStyle(fontWeight: FontWeight.w700))),
              if (d.mileage != null) StatusPill('${s.mileage} ${f.number(d.mileage!, decimals: 1)} ${s.kmPerUnit}', p.info, icon: Icons.speed_rounded),
            ]),
            const SizedBox(height: 16),
            if (d.categories.isEmpty) Text(s.noData, style: TextStyle(color: p.muted)) else CategoryDonut(data: d.categories),
          ]));

          final papers = _PapersCard(vehicleId: vehicleId, papers: d.papers);

          final history = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHeader(s.history),
            Panel(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: d.history.isEmpty
                  ? EmptyState(icon: Icons.receipt_long_rounded, title: s.noEntries)
                  : Column(children: groupedLedger(d.history, showVehicle: false)),
            ),
          ]);

          return Contained(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: wide
                  ? [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: Column(children: [header, const SizedBox(height: 14), actions, const SizedBox(height: 14), payback])),
                        const SizedBox(width: 16),
                        Expanded(child: Column(children: [statsGrid, const SizedBox(height: 14), chart])),
                      ]),
                      const SizedBox(height: 16),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: costs),
                        const SizedBox(width: 16),
                        Expanded(child: papers),
                      ]),
                      history,
                    ]
                  : [
                      Entrance(child: header),
                      const SizedBox(height: 14),
                      Entrance(index: 1, child: actions),
                      const SizedBox(height: 14),
                      Entrance(index: 2, child: statsGrid),
                      const SizedBox(height: 14),
                      Entrance(index: 3, child: payback),
                      const SizedBox(height: 14),
                      chart,
                      const SizedBox(height: 14),
                      costs,
                      const SizedBox(height: 14),
                      papers,
                      history,
                    ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(children: [
        IconBubble(icon, color, size: 40),
        const SizedBox(height: 8),
        Text('+ $label', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      ]),
    );
  }
}

class _PaybackCard extends StatelessWidget {
  const _PaybackCard({required this.vehicle, required this.lifetime});
  final Vehicle vehicle;
  final VehicleStat lifetime;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    if (vehicle.purchasePrice <= 0) {
      return Panel(
        child: Row(children: [
          IconBubble(Icons.savings_rounded, p.income),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.netProfit} · ${s.allTime}', style: TextStyle(color: p.muted, fontSize: 13)),
              Money(lifetime.profit, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
            ]),
          ),
        ]),
      );
    }
    final ratio = (lifetime.profit / vehicle.purchasePrice).clamp(0.0, 1.0);
    final left = vehicle.purchasePrice - lifetime.profit;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(kRadius)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.savings_rounded, color: p.onAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(s.payback, style: TextStyle(color: p.onAccent, fontWeight: FontWeight.w700))),
          Text(f.percent(ratio), style: TextStyle(color: p.onAccent, fontWeight: FontWeight.w800, fontSize: 22)),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 14, color: p.onAccent, backgroundColor: p.onAccent.withValues(alpha: 0.12)),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.netProfit} · ${s.allTime}', style: TextStyle(color: p.onAccent.withValues(alpha: 0.65), fontSize: 12)),
              Text(f.money(lifetime.profit), style: TextStyle(color: p.onAccent, fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(s.purchasePrice, style: TextStyle(color: p.onAccent.withValues(alpha: 0.65), fontSize: 12)),
            Text(f.money(vehicle.purchasePrice), style: TextStyle(color: p.onAccent, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
        ]),
        const SizedBox(height: 10),
        Text(left <= 0 ? s.paybackDone : s.paybackLeft(f.money(left)), style: TextStyle(color: p.onAccent, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

class _PapersCard extends StatelessWidget {
  const _PapersCard({required this.vehicleId, required this.papers});
  final int vehicleId;
  final List<Paper> papers;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(s.papers, style: const TextStyle(fontWeight: FontWeight.w700))),
          TextButton.icon(
            onPressed: () => showPaperSheet(context, vehicleId: vehicleId),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(s.add),
          ),
        ]),
        if (papers.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(s.noPapers, style: TextStyle(color: context.pal.muted)))
        else
          for (final pp in papers) PaperTile(paper: pp, showVehicle: false),
      ]),
    );
  }
}

// ── Form ──────────────────────────────────────────────────────────────────

class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key, this.vehicle});
  final Vehicle? vehicle;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.vehicle?.name);
  late final _reg = TextEditingController(text: widget.vehicle?.regNo);
  late final _model = TextEditingController(text: widget.vehicle?.model);
  late final _price = TextEditingController(text: _num(widget.vehicle?.purchasePrice));
  late final _target = TextEditingController(text: _num(widget.vehicle?.dailyTarget));
  late final _note = TextEditingController(text: widget.vehicle?.note);
  late VehicleType _type = widget.vehicle?.type ?? VehicleType.cng;
  late VehicleStatus _status = widget.vehicle?.status ?? VehicleStatus.active;
  late int? _driverId = widget.vehicle?.driverId;
  late DateTime? _purchaseDate = widget.vehicle?.purchaseDate;

  static String _num(double? v) => v == null || v == 0 ? '' : v.round().toString();

  @override
  void dispose() {
    for (final c in [_name, _reg, _model, _price, _target, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final app = context.read<AppState>();
    final s = context.s;
    final v = Vehicle(
      id: widget.vehicle?.id,
      name: _name.text,
      type: _type,
      regNo: _reg.text.trim().isEmpty ? null : _reg.text.trim(),
      model: _model.text.trim().isEmpty ? null : _model.text.trim(),
      purchasePrice: parseAmount(_price.text) ?? 0,
      purchaseDate: _purchaseDate,
      dailyTarget: parseAmount(_target.text) ?? 0,
      driverId: _driverId,
      status: _status,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    await app.mutate((r) async {
      // A driver drives one vehicle at a time.
      if (_driverId != null) {
        for (final other in app.vehicles.where((o) => o.driverId == _driverId && o.id != v.id)) {
          await r.saveVehicle(Vehicle.fromMap({...other.toMap(), 'driver_id': null}));
        }
      }
      await r.saveVehicle(v);
    });
    if (!mounted) return;
    toast(context, s.saved);
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final s = context.s;
    if (!await confirm(context, title: s.confirmDelete, body: s.deleteVehicleWarn)) return;
    if (!mounted) return;
    await context.read<AppState>().mutate((r) => r.deleteVehicle(widget.vehicle!.id!));
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle == null ? s.addVehicle : s.editVehicle),
        actions: [
          if (widget.vehicle != null) IconButton(onPressed: _delete, icon: Icon(Icons.delete_outline_rounded, color: p.expense)),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _form,
        child: Contained(
          maxWidth: 640,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _label(s.vehicleType),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: VehicleType.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final t = VehicleType.values[i];
                    final sel = t == _type;
                    return Pressable(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 92,
                        decoration: BoxDecoration(
                          color: sel ? t.color : p.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? t.color : p.line, width: 1.4),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(t.icon, size: 32, color: sel ? Colors.white : t.color),
                          const SizedBox(height: 8),
                          Text(t.label(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: sel ? Colors.white : p.ink)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: s.vehicleName, hintText: s.vehicleNameHint, prefixIcon: const Icon(Icons.badge_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? s.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reg,
                decoration: InputDecoration(labelText: s.regNo, hintText: s.regNoHint, prefixIcon: const Icon(Icons.pin_outlined)),
                onChanged: (_) => setState(() {}),
              ),
              if (_reg.text.trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 10, left: 4), child: Align(alignment: Alignment.centerLeft, child: NumberPlate(regNo: _reg.text, color: _type.color))),
              const SizedBox(height: 12),
              TextFormField(
                controller: _model,
                decoration: InputDecoration(labelText: s.model, hintText: s.modelHint, prefixIcon: const Icon(Icons.directions_car_outlined)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _target,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: s.dailyTarget, helperText: s.dailyTargetHelp, prefixText: '৳ ', prefixIcon: const Icon(Icons.flag_outlined)),
                validator: (v) => v != null && v.trim().isNotEmpty && parseAmount(v) == null ? s.invalidNumber : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.purchasePrice, prefixText: '৳ ', prefixIcon: const Icon(Icons.sell_outlined)),
                    validator: (v) => v != null && v.trim().isNotEmpty && parseAmount(v) == null ? s.invalidNumber : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: s.purchaseDate,
                    value: _purchaseDate,
                    display: _purchaseDate == null ? '' : f.date(_purchaseDate!),
                    onPick: (d) => setState(() => _purchaseDate = d),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              _label(s.assignedDriver),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceTag(label: s.none, selected: _driverId == null, onTap: () => setState(() => _driverId = null)),
                for (final d in app.drivers.where((d) => d.active || d.id == _driverId))
                  ChoiceTag(label: d.name, icon: Icons.person_rounded, selected: _driverId == d.id, onTap: () => setState(() => _driverId = d.id)),
                ChoiceTag(
                  label: s.addDriver,
                  icon: Icons.add_rounded,
                  selected: false,
                  onTap: () async {
                    final id = await Navigator.of(context).push<int>(MaterialPageRoute(builder: (_) => const DriverFormScreen()));
                    if (id != null) setState(() => _driverId = id);
                  },
                ),
              ]),
              const SizedBox(height: 20),
              _label(s.status),
              PillToggle<VehicleStatus>(values: VehicleStatus.values, selected: _status, label: (v) => v.label(s), onChanged: (v) => setState(() => _status = v)),
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
            child: FilledButton(onPressed: _save, child: Text(s.save)),
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

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.display, required this.onPick});
  final String label;
  final DateTime? value;
  final String display;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final d = await pickDate(context, value ?? DateTime.now());
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.event_outlined)),
        isEmpty: display.isEmpty,
        child: Text(display, maxLines: 1),
      ),
    );
  }
}

/// Reusable date field for other forms.
class DateFormField extends StatelessWidget {
  const DateFormField({super.key, required this.label, required this.value, required this.onPick});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) =>
      _DateField(label: label, value: value, display: value == null ? '' : context.fmt.date(value!), onPick: onPick);
}
