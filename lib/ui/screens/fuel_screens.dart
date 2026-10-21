import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/l10n_personal.dart';
import '../../core/theme.dart';
import '../../data/fuel_report.dart';
import '../../data/models.dart';
import '../../services/access.dart';
import '../../state/app_state.dart';
import '../routes.dart';
import '../widgets/access_gate.dart';
import '../widgets/common.dart';
import '../widgets/fuel_charts.dart';
import 'personal_screens.dart';
import 'vehicle_screens.dart';

/// The fuel a car is filled with by default: its own, or octane for a hybrid.
FuelType defaultFuel(Vehicle? v) => switch (v?.fuel) {
      null || FuelType.hybrid => FuelType.octane,
      final f => f,
    };

/// km/L or km/m³ for a report's fuel.
String mileageText(S s, Fmt f, double v, FuelType? fuel) => '${f.number(v, decimals: 1)} ${s.mileageUnit((fuel ?? FuelType.octane).unit(s))}';

Future<void> openFuelForm(BuildContext context, {int? vehicleId, Expense? fill}) async {
  if (!await requireFeature(context, Feature.fuelExpense) || !context.mounted) return;
  await Navigator.of(context).push(AppRoute(fullscreenDialog: true, builder: (_) => FuelFormScreen(vehicleId: vehicleId, fill: fill)));
}

// ── Form ──────────────────────────────────────────────────────────────────

enum _Field { qty, price, total }

/// One fill-up: odometer, how much at what price, full tank or not.
class FuelFormScreen extends StatefulWidget {
  const FuelFormScreen({super.key, this.fill, this.vehicleId});
  final Expense? fill;
  final int? vehicleId;

  @override
  State<FuelFormScreen> createState() => _FuelFormScreenState();
}

class _FuelFormScreenState extends State<FuelFormScreen> {
  final _form = GlobalKey<FormState>();
  late int? _vehicleId = widget.fill?.vehicleId ?? widget.vehicleId;
  late DateTime _date = widget.fill?.date ?? DateUtils.dateOnly(DateTime.now());
  late final _odo = TextEditingController(text: _num(widget.fill?.odometer));
  late final _qty = TextEditingController(text: _num(widget.fill?.quantity));
  late final _price = TextEditingController(text: _num(widget.fill?.unitPrice, decimals: 2));
  late final _total = TextEditingController(text: _num(widget.fill?.amount));
  late final _station = TextEditingController(text: widget.fill?.place);
  late final _note = TextEditingController(text: widget.fill?.note);
  late FuelType? _fuel = widget.fill?.fuelType;
  late bool _full = widget.fill?.fullTank ?? true;
  late bool _missed = widget.fill?.missed ?? false;
  late PayMethod _pay = widget.fill?.payMethod ?? PayMethod.cash;
  List<Expense> _fills = [];
  List<String> _stations = [];
  bool _saving = false;

  /// The two amounts typed most recently; the third is worked out from them.
  final List<_Field> _recent = [];

  bool get _editing => widget.fill != null;

  static String _num(double? v, {int decimals = 0}) {
    if (v == null || v == 0) return '';
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(decimals == 0 ? 2 : decimals).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    if (widget.fill == null) {
      _vehicleId ??= selectedCar(context, listen: false)?.id;
    } else {
      // An edited bill keeps its total; quantity and price can be re-derived.
      _recent.addAll([_Field.qty, _Field.total]);
    }
    app.repo.suggestions('expenses', 'place').then((v) {
      if (mounted) setState(() => _stations = v);
    });
    _loadFills();
  }

  Future<void> _loadFills() async {
    final id = _vehicleId;
    if (id == null) return;
    final app = context.read<AppState>();
    final fills = await app.repo.fuelFills(vehicleId: id);
    if (!mounted || id != _vehicleId) return;
    setState(() {
      _fills = fills;
      if (!_editing) {
        _fuel ??= fills.isNotEmpty ? (fills.last.fuelType ?? defaultFuel(app.vehicle(id))) : defaultFuel(app.vehicle(id));
        _prefillPrice();
      }
    });
  }

  /// The last price paid for this fuel, so a usual fill is just litres + odometer.
  void _prefillPrice() {
    if (_price.text.isNotEmpty && _recent.contains(_Field.price)) return;
    final report = _report;
    final last = report?.lastUnitPrice;
    if (last != null) {
      _price.text = _num(last, decimals: 2);
      _recompute();
    }
  }

  FuelReport? get _report {
    final reports = FuelReport.byFuel(_fills, fallback: defaultFuel(context.read<AppState>().vehicle(_vehicleId)));
    for (final r in reports) {
      if (r.fuel == _fuel) return r;
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in [_odo, _qty, _price, _total, _station, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _typed(_Field field) {
    _recent
      ..remove(field)
      ..add(field);
    if (_recent.length > 2) _recent.removeAt(0);
    _recompute();
    setState(() {});
  }

  /// Fills in whichever of quantity / price / total wasn't typed last.
  void _recompute() {
    final q = parseAmount(_qty.text), pr = parseAmount(_price.text), t = parseAmount(_total.text);
    final target = _recent.length < 2
        ? (_total.text.isEmpty || !_recent.contains(_Field.total) ? _Field.total : _Field.qty)
        : _Field.values.firstWhere((f) => !_recent.contains(f));
    switch (target) {
      case _Field.total:
        if (q != null && pr != null) _total.text = _num((q * pr).roundToDouble());
      case _Field.qty:
        if (t != null && pr != null && pr > 0) _qty.text = _num(t / pr, decimals: 2);
      case _Field.price:
        if (t != null && q != null && q > 0) _price.text = _num(t / q, decimals: 2);
    }
  }

  double? get _amount {
    final t = parseAmount(_total.text);
    if (t != null && t > 0) return t;
    final q = parseAmount(_qty.text), pr = parseAmount(_price.text);
    return q != null && pr != null ? q * pr : null;
  }

  Expense? _draft() {
    final amount = _amount;
    if (_vehicleId == null || amount == null || amount <= 0) return null;
    final q = parseAmount(_qty.text);
    final pr = parseAmount(_price.text);
    final station = _station.text.trim();
    final note = _note.text.trim();
    return Expense(
      id: widget.fill?.id,
      date: _date,
      vehicleId: _vehicleId!,
      category: ExpenseCategory.fuel,
      amount: amount.roundToDouble(),
      quantity: q != null && q > 0 ? q : null,
      odometer: parseAmount(_odo.text),
      unitPrice: pr != null && pr > 0 ? pr : (q != null && q > 0 ? amount / q : null),
      fuelType: _fuel,
      fullTank: _full,
      missed: _missed,
      payMethod: _pay,
      place: station.isEmpty ? null : station,
      note: note.isEmpty ? null : note,
    );
  }

  /// Highest reading logged before this fill's date (for a gentle sanity check).
  double? get _previousOdo {
    double? best;
    for (final e in _fills) {
      if (e.id == widget.fill?.id || e.odometer == null || e.date.isAfter(_date)) continue;
      if (best == null || e.odometer! > best) best = e.odometer;
    }
    return best;
  }

  Future<void> _save() async {
    final s = S.read(context);
    if (_vehicleId == null) {
      toast(context, s.noVehicleYet, icon: Icons.info_outline_rounded);
      return;
    }
    if (!_form.currentState!.validate() || _saving) return;
    final e = _draft();
    if (e == null) {
      toast(context, s.enterAmountOrQty, icon: Icons.info_outline_rounded);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AppState>().mutate((r) => r.saveExpense(e));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      toast(context, s.entrySaved);
      Navigator.pop(context);
    } catch (err) {
      if (mounted) toast(context, s.somethingWrong(err), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final s = S.read(context);
    if (!await confirm(context, title: s.deleteEntry, body: s.confirmDeleteBody)) return;
    if (!mounted) return;
    final nav = Navigator.of(context);
    await context.read<AppState>().mutate((r) => r.deleteExpense(widget.fill!.id!));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final app = context.watch<AppState>();
    final unit = (_fuel ?? FuelType.octane).unit(s);
    final prev = _previousOdo;
    final odo = parseAmount(_odo.text);
    final draft = _draft();
    final preview = draft == null ? null : _report?.previewMileage(draft) ?? (_report == null ? FuelReport.build([draft]).fills.first.mileage : null);
    final accent = ExpenseCategory.fuel.color;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        title: Text(_editing ? s.editFuel : s.addFuel),
        actions: [
          if (_editing) IconButton(icon: Icon(Icons.delete_outline_rounded, color: p.expense), onPressed: _delete),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _form,
        child: Contained(
          maxWidth: 640,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            children: [
              if (app.vehicles.length > 1 || _vehicleId == null) ...[
                _label(s.selectVehicle),
                if (app.vehicles.isEmpty)
                  Text(s.noVehicleYet, style: TextStyle(color: p.expense, fontWeight: FontWeight.w600))
                else
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: app.vehicles.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final v = app.vehicles[i];
                        return ChoiceTag(
                          label: v.name,
                          icon: v.type.icon,
                          color: v.type.color,
                          selected: v.id == _vehicleId,
                          onTap: () {
                            setState(() {
                              _vehicleId = v.id;
                              _fills = [];
                              if (!_editing) _fuel = null;
                            });
                            _loadFills();
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 18),
              ],
              _label(s.fuelType),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final fuel in FuelType.pumpFuels)
                  ChoiceTag(
                    label: fuel.label(s),
                    selected: _fuel == fuel,
                    color: accent,
                    onTap: () => setState(() {
                      _fuel = fuel;
                      if (!_editing) _prefillPrice();
                    }),
                  ),
              ]),
              const SizedBox(height: 18),
              FieldPair(
                TextFormField(
                  controller: _odo,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: s.odometerReq,
                    prefixIcon: const Icon(Icons.speed_rounded),
                    helperText: prev == null ? null : s.lastOdo('${f.number(prev)} ${s.km}'),
                    helperStyle: odo != null && prev != null && odo < prev ? TextStyle(color: p.warning, fontWeight: FontWeight.w600) : null,
                    suffixText: s.km,
                  ),
                  validator: (v) => v != null && v.trim().isNotEmpty && parseAmount(v) == null ? s.invalidNumber : null,
                ),
                DateFormField(label: s.date, value: _date, onPick: (d) => setState(() => _date = d)),
              ),
              if (odo != null && prev != null && odo < prev)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(s.odoBelowLast, style: TextStyle(color: p.warning, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 18),
              Panel(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: _amountField(_qty, _Field.qty, unit, Icons.water_drop_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _amountField(_price, _Field.price, '৳/$unit', Icons.sell_outlined)),
                  ]),
                  const SizedBox(height: 10),
                  _amountField(_total, _Field.total, s.totalBill, Icons.payments_outlined, big: true),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.auto_fix_high_rounded, size: 15, color: p.muted),
                    const SizedBox(width: 6),
                    Expanded(child: Text(s.autoCalc, style: TextStyle(color: p.muted, fontSize: 12))),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Column(children: [
                  SwitchListTile(
                    value: _full,
                    onChanged: (v) => setState(() => _full = v),
                    secondary: IconBubble(Icons.local_gas_station_rounded, accent),
                    title: Text(s.fullTank, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(s.fullTankSub, style: const TextStyle(fontSize: 12.5)),
                  ),
                  Divider(height: 1, indent: 72, color: p.line),
                  SwitchListTile(
                    value: _missed,
                    onChanged: (v) => setState(() => _missed = v),
                    secondary: IconBubble(Icons.link_off_rounded, p.warning),
                    title: Text(s.missedFill, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(s.missedFillSub, style: const TextStyle(fontSize: 12.5)),
                  ),
                ]),
              ),
              if (preview != null) ...[
                const SizedBox(height: 12),
                _PreviewCard(mileage: preview, fuel: _fuel, costPerKm: draft == null ? null : _previewCostPerKm(draft)),
              ],
              const SizedBox(height: 18),
              SuggestField(controller: _station, suggestions: _stations, label: s.station, hint: s.stationHint, icon: Icons.ev_station_rounded),
              const SizedBox(height: 18),
              _label(s.paidBy),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in PayMethod.values.where((m) => m != PayMethod.cheque))
                  ChoiceTag(label: m.label(s), icon: m.icon, selected: _pay == m, onTap: () => setState(() => _pay = m)),
              ]),
              const SizedBox(height: 18),
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
              height: 56,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                    : Text(draft == null ? s.save : '${s.save} · ${f.money(draft.amount)}'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double? _previewCostPerKm(Expense draft) {
    final r = _report;
    final report = FuelReport.build([...?r?.fills.map((x) => x.expense).where((x) => x.id == null || x.id != draft.id), draft]);
    for (final x in report.fills) {
      if (identical(x.expense, draft)) return x.costPerKm;
    }
    return null;
  }

  Widget _amountField(TextEditingController c, _Field field, String label, IconData icon, {bool big = false}) => TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => _typed(field),
        style: big ? const TextStyle(fontSize: 20, fontWeight: FontWeight.w800) : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), prefixText: field == _Field.total ? '৳ ' : null, isDense: !big),
        validator: (v) => v != null && v.trim().isNotEmpty && parseAmount(v) == null ? context.s.invalidNumber : null,
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(t, style: TextStyle(color: context.pal.muted, fontWeight: FontWeight.w600, fontSize: 13)),
      );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.mileage, required this.fuel, this.costPerKm});
  final double mileage;
  final FuelType? fuel;
  final double? costPerKm;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(kRadius)),
      child: Row(children: [
        Icon(Icons.speed_rounded, color: p.onAccent, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.previewMileage, style: TextStyle(color: p.onAccent.withValues(alpha: 0.7), fontSize: 12.5, fontWeight: FontWeight.w600)),
            Text(mileageText(s, f, mileage, fuel), style: TextStyle(color: p.onAccent, fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
        ),
        if (costPerKm != null)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(s.previewCostKm, style: TextStyle(color: p.onAccent.withValues(alpha: 0.7), fontSize: 12.5, fontWeight: FontWeight.w600)),
            Text('৳${f.number(costPerKm!, decimals: 2)}', style: TextStyle(color: p.onAccent, fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
      ]),
    );
  }
}

// ── Log ───────────────────────────────────────────────────────────────────

/// Mileage, running cost and every fill-up of one car.
class FuelLogScreen extends StatefulWidget {
  const FuelLogScreen({super.key, this.embedded = false});

  /// True when shown as a tab (no back button).
  final bool embedded;

  @override
  State<FuelLogScreen> createState() => _FuelLogScreenState();
}

class _FuelLogScreenState extends State<FuelLogScreen> {
  FuelType? _fuel;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final app = context.watch<AppState>();
    final car = selectedCar(context);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(children: [
        if (widget.embedded) Expanded(child: Text(s.fuelLog, style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800))) else const Spacer(),
        RoundIconButton(icon: Icons.add_rounded, filled: true, tooltip: s.addFuel, onTap: () => openFuelForm(context, vehicleId: car?.id)),
      ]),
    );

    Widget body;
    if (car == null) {
      body = ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), children: [header, const PersonalWelcome()]);
    } else {
      body = Loader<List<FuelReport>>(
        deps: [car.id],
        load: (r) async => FuelReport.byFuel(await r.fuelFills(vehicleId: car.id), fallback: defaultFuel(car)),
        builder: (context, reports) {
          final report = reports.where((r) => r.fuel == _fuel).firstOrNull ?? reports.firstOrNull;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              header,
              if (app.vehicles.length > 1) ...[const CarSwitcher(), const SizedBox(height: 12)],
              if (FuelSavings.of(reports) case final sv?) ...[SavingsCard(savings: sv, vehicle: car), const SizedBox(height: 12)],
              if (reports.length > 1) ...[
                PillToggle<FuelType?>(
                  values: [for (final r in reports) r.fuel],
                  selected: report?.fuel,
                  label: (f) => (f ?? FuelType.octane).label(s),
                  onChanged: (f) => setState(() => _fuel = f),
                ),
                const SizedBox(height: 12),
              ],
              if (report == null || report.isEmpty)
                Panel(
                  child: EmptyState(
                    icon: Icons.local_gas_station_rounded,
                    title: s.noFuelTitle,
                    body: s.noFuelBody,
                    action: FilledButton.icon(onPressed: () => openFuelForm(context, vehicleId: car.id), icon: const Icon(Icons.add_rounded), label: Text(s.addFuel)),
                  ),
                )
              else
                FuelReportView(report: report, vehicle: car),
            ],
          );
        },
      );
    }

    final content = Contained(maxWidth: 900, child: body);
    if (widget.embedded) return SafeArea(bottom: false, child: content);
    return Scaffold(appBar: AppBar(title: Text(s.fuelLog)), body: content);
  }
}

/// Everything a fuel report shows: hero, alerts, stats, charts, history.
class FuelReportView extends StatelessWidget {
  const FuelReportView({super.key, required this.report, required this.vehicle});
  final FuelReport report;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final r = report;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final unit = (r.fuel ?? FuelType.octane).unit(s);
    final months = r.months();
    final thisMonth = months.last;
    final color = ExpenseCategory.fuel.color;

    final stats = GridView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: wide ? 3 : 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 112),
      children: [
        StatBlock(label: '${s.fuelSpend} · ${s.thisMonth}', value: f.money(thisMonth.cost), icon: Icons.payments_rounded, color: p.expense, sub: '${f.number(thisMonth.quantity, decimals: 1)} $unit'),
        StatBlock(
          label: s.kmDriven,
          value: '${f.number(thisMonth.distance)} ${s.km}',
          icon: Icons.route_rounded,
          sub: r.trackedDistance == null ? null : '${s.allTime}: ${f.number(r.trackedDistance!)} ${s.km}',
        ),
        StatBlock(
          label: s.avgPrice,
          value: r.avgUnitPrice == null ? '—' : '৳${f.number(r.avgUnitPrice!, decimals: 2)}',
          icon: Icons.sell_rounded,
          sub: r.lastUnitPrice == null ? null : '${s.lastPrice}: ৳${f.number(r.lastUnitPrice!, decimals: 2)}/$unit',
        ),
        StatBlock(
          label: s.fillsCount,
          value: f.digits(r.fills.length),
          icon: Icons.local_gas_station_rounded,
          sub: r.avgDaysBetween == null ? null : '${s.everyDays} ${s.dayCount(r.avgDaysBetween!.round())}',
        ),
        StatBlock(label: s.bestMileage, value: r.bestMileage == null ? '—' : mileageText(s, f, r.bestMileage!, r.fuel), icon: Icons.trending_up_rounded, color: p.income),
        StatBlock(label: s.worstMileage, value: r.worstMileage == null ? '—' : mileageText(s, f, r.worstMileage!, r.fuel), icon: Icons.trending_down_rounded, color: p.warning),
      ],
    );

    final mileageChart = r.segments.length < 2
        ? null
        : Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.mileageTrend, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TrendLine(points: [for (final seg in r.segments) (seg.end, seg.mileage)], color: p.income, label: (v) => mileageText(s, f, v, r.fuel)),
            ]),
          );
    final prices = [for (final x in r.fills) if (x.unitPrice != null) (x.date, x.unitPrice!)];
    final priceChart = prices.length < 2
        ? null
        : Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.priceTrend} (৳/$unit)', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TrendLine(points: prices, color: color, decimals: 2, label: (v) => '৳${f.number(v, decimals: 2)}/$unit'),
            ]),
          );
    final monthChart = Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.monthlyFuel, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        MonthBars(points: [for (final m in months) (m.month, m.cost)], color: color, label: f.money),
      ]),
    );

    final history = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader('${s.fillHistory} · ${f.digits(r.fills.length)}'),
      Panel(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(children: [for (final x in r.fills.reversed) FuelFillTile(fill: x, fuel: r.fuel)]),
      ),
    ]);

    final charts = [?mileageChart, ?priceChart, monthChart];
    final pumps = r.segments.length < 2 ? null : StationsCard(report: r);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Entrance(child: FuelHero(report: r)),
      FuelAlerts(report: r, vehicle: vehicle),
      const SizedBox(height: 14),
      Entrance(index: 1, child: stats),
      const SizedBox(height: 14),
      if (pumps != null) ...[pumps, const SizedBox(height: 14)],
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < charts.length; i++) ...[if (i > 0) const SizedBox(width: 14), Expanded(child: charts[i])],
        ])
      else
        for (final c in charts) ...[c, const SizedBox(height: 14)],
      history,
    ]);
  }
}

/// Big average mileage with the last fill and fuel cost per km.
class FuelHero extends StatelessWidget {
  const FuelHero({super.key, required this.report, this.onTap});
  final FuelReport report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final r = report;
    final avg = r.avgMileage;
    final last = r.lastMileage;
    final up = last != null && avg != null && last >= avg;
    // Only point an arrow when the last tank was clearly better or worse.
    final moved = last != null && avg != null && (last - avg).abs() > avg * 0.02;
    final unit = s.mileageUnit((r.fuel ?? FuelType.octane).unit(s));

    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: LanePainter(p.onHero.withValues(alpha: 0.05)))),
        Positioned(right: -24, bottom: -30, child: Icon(Icons.local_gas_station_rounded, size: 170, color: p.onHero.withValues(alpha: 0.05))),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(20)),
                child: Text('${s.avgMileage} · ${(r.fuel ?? FuelType.octane).label(s)}', style: TextStyle(color: p.onAccent, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
              const Spacer(),
              if (r.lastFill != null) Text(f.relativeDay(r.lastFill!, s), style: TextStyle(color: p.onHero.withValues(alpha: 0.6), fontSize: 12.5, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 18),
            if (avg == null)
              Text(s.needTwoFull, style: TextStyle(color: p.onHero, fontSize: 18, fontWeight: FontWeight.w700, height: 1.3))
            else
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: f.number(avg, decimals: 1), style: TextStyle(color: p.onHero, fontSize: 52, fontWeight: FontWeight.w800, letterSpacing: -1.8, height: 1)),
                  TextSpan(text: '  $unit', style: TextStyle(color: p.onHero.withValues(alpha: 0.55), fontSize: 18, fontWeight: FontWeight.w700)),
                ])),
              ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: _heroKv(context, s.lastMileage, last == null ? '—' : f.number(last, decimals: 1),
                    trailing: !moved ? null : Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 16, color: up ? p.accent : p.expense)),
              ),
              Expanded(child: _heroKv(context, s.fuelPerKm, r.costPerKm == null ? '—' : '৳${f.number(r.costPerKm!, decimals: 2)}')),
              Expanded(child: _heroKv(context, s.totalFuel, f.money(r.totalCost))),
            ]),
          ]),
        ),
      ]),
    );
    return onTap == null ? card : Pressable(onTap: onTap!, child: card);
  }

  Widget _heroKv(BuildContext context, String k, String v, {Widget? trailing}) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.onHero.withValues(alpha: 0.6), fontSize: 11.5)),
      const SizedBox(height: 2),
      Row(children: [
        Flexible(child: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.onHero, fontWeight: FontWeight.w800, fontSize: 16))),
        if (trailing != null) ...[const SizedBox(width: 3), trailing],
      ]),
    ]);
  }
}

/// What running on the cheaper fuel saved, and how the conversion is paying back.
class SavingsCard extends StatelessWidget {
  const SavingsCard({super.key, required this.savings, required this.vehicle});
  final FuelSavings savings;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final sv = savings;
    final year = FuelSavings.of([sv.cheap, sv.dear], from: DateTime(DateTime.now().year))?.saved ?? 0;
    final cheapFuel = (sv.cheap.fuel ?? FuelType.cng).label(s);
    final dearFuel = (sv.dear.fuel ?? FuelType.octane).label(s);
    final cost = vehicle.conversionCost;
    final back = cost == null || cost <= 0 ? null : (sv.saved / cost).clamp(0.0, 1.0);
    final by = cost == null ? null : sv.paybackDate(cost);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: p.income, borderRadius: BorderRadius.circular(kRadius)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.savings_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(s.savedThisYear(cheapFuel), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(f.money(year.roundToDouble()), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.2)),
        ),
        const SizedBox(height: 4),
        Text(
          '${s.perKmCompare('$cheapFuel ৳${f.number(sv.cheapPerKm, decimals: 2)} · $dearFuel ৳${f.number(sv.dearPerKm, decimals: 2)}')} · '
          '${s.savingPerMonth(f.money((sv.savedPerDay() * 30).roundToDouble()))}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.35),
        ),
        const SizedBox(height: 4),
        Text(s.savedAllTime(f.money(sv.saved.roundToDouble())), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
        if (back != null) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: back, minHeight: 10, color: Colors.white, backgroundColor: Colors.white.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 8),
          Text(
            back >= 1 ? s.paybackDoneBody : '${s.paybackProgress(f.money(cost!), f.percent(back))}${by == null ? '' : ' · ${s.paybackBy(f.monthYear(by))}'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, height: 1.35),
          ),
        ],
      ]),
    );
  }
}

/// Mileage per pump, worst first, as bars against the car's average.
class StationsCard extends StatelessWidget {
  const StationsCard({super.key, required this.report});
  final FuelReport report;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final stations = report.stations();
    final avg = report.avgMileage;
    final top = stations.isEmpty ? 1.0 : stations.map((x) => x.mileage).reduce((a, b) => a > b ? a : b);

    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconBubble(Icons.ev_station_rounded, ExpenseCategory.fuel.color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.pumpCompare, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(s.pumpCompareSub, style: TextStyle(color: p.muted, fontSize: 12.5)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        if (stations.isEmpty || avg == null)
          Text(s.pumpNeedData, style: TextStyle(color: p.muted, height: 1.4))
        else ...[
          for (final st in stations)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (st.suspect) ...[Icon(Icons.warning_amber_rounded, size: 17, color: p.expense), const SizedBox(width: 6)],
                  Expanded(child: Text(st.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text(mileageText(s, f, st.mileage, report.fuel), style: TextStyle(fontWeight: FontWeight.w800, color: st.suspect ? p.expense : p.ink)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (st.mileage / top).clamp(0, 1),
                    minHeight: 8,
                    color: st.suspect ? p.expense : (st.shortfall <= 0 ? p.income : p.warning),
                    backgroundColor: p.surfaceAlt,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.stretches(st.stretches)} · ${st.shortfall >= 0 ? s.pumpBelow(f.percent(st.shortfall)) : s.pumpAbove(f.percent(-st.shortfall))}',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
              ]),
            ),
          Text(s.pumpOnlyClean, style: TextStyle(color: p.muted, fontSize: 11.5, height: 1.3)),
        ],
      ]),
    );
  }
}

/// Mileage drop and "forgot to log?" warnings.
class FuelAlerts extends StatelessWidget {
  const FuelAlerts({super.key, required this.report, required this.vehicle});
  final FuelReport report;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final suspect = report.stations().where((x) => x.suspect).firstOrNull;
    final cards = <Widget>[
      if (suspect != null)
        _alert(context, Icons.ev_station_rounded, p.expense, s.pumpSuspectTitle, s.pumpSuspectBody(suspect.name, f.percent(suspect.shortfall))),
      if (report.mileageAlert)
        _alert(context, Icons.trending_down_rounded, p.expense, s.mileageDropTitle, s.mileageDropBody(f.percent(report.mileageDrop!))),
      if (report.overdueLog())
        _alert(context, Icons.local_gas_station_rounded, p.warning, s.fuelReminderTitle, s.fuelReminderBody(report.daysSinceLastFill()!),
            onTap: () => openFuelForm(context, vehicleId: vehicle.id)),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(children: [for (final c in cards) ...[const SizedBox(height: 12), c]]);
  }

  Widget _alert(BuildContext context, IconData icon, Color color, String title, String body, {VoidCallback? onTap}) => Panel(
        onTap: onTap,
        color: color.withValues(alpha: 0.08),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconBubble(icon, color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(body, style: const TextStyle(fontSize: 13.5, height: 1.35)),
            ]),
          ),
        ]),
      );
}

/// One row of the fill-up history.
class FuelFillTile extends StatelessWidget {
  const FuelFillTile({super.key, required this.fill, required this.fuel});
  final FuelFill fill;
  final FuelType? fuel;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final e = fill.expense;
    final unit = (e.fuelType ?? fuel ?? FuelType.octane).unit(s);
    final meta = [
      if (e.odometer != null) '${f.number(e.odometer!)} ${s.km}',
      if (e.quantity != null) '${f.number(e.quantity!, decimals: 1)} $unit',
      if (fill.unitPrice != null) '৳${f.number(fill.unitPrice!, decimals: 2)}',
      if (e.place?.isNotEmpty ?? false) e.place!,
    ].join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => openFuelForm(context, fill: e),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: p.surfaceAlt.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text(f.digits(e.date.day), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, height: 1.1)),
              Text(f.monthShort(e.date.month), style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(f.money(e.amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(width: 8),
                if (!e.fullTank) StatusPill(s.partialFill, p.muted),
                if (e.missed) ...[const SizedBox(width: 4), StatusPill(s.missedShort, p.warning)],
              ]),
              if (meta.isNotEmpty) Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
            ]),
          ),
          const SizedBox(width: 8),
          if (fill.mileage != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(f.number(fill.mileage!, decimals: 1), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: p.income)),
              Text(s.mileageUnit(unit), style: TextStyle(color: p.muted, fontSize: 11)),
            ]),
        ]),
      ),
    );
  }
}
