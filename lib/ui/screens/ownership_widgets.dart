import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/l10n_personal.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/ownership.dart';
import '../../state/app_state.dart';
import '../routes.dart';
import '../widgets/common.dart';
import 'driver_screens.dart';
import 'vehicle_screens.dart';

/// Number prompt; returns the amount, 0 when [removeLabel] was chosen, or null.
Future<double?> askAmount(BuildContext context, {required String title, String? helper, double? initial, String? removeLabel}) {
  final ctl = TextEditingController(text: initial == null || initial <= 0 ? '' : initial.round().toString());
  final s = S.read(context);
  return showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: TextField(
        controller: ctl,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(prefixText: '৳ ', helperText: helper, helperMaxLines: 3),
        onSubmitted: (v) => Navigator.pop(ctx, parseAmount(v)),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        if (removeLabel != null && initial != null && initial > 0) TextButton(onPressed: () => Navigator.pop(ctx, 0.0), child: Text(removeLabel)),
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
        FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => Navigator.pop(ctx, parseAmount(ctl.text)), child: Text(s.save)),
      ],
    ),
  );
}

Future<void> _saveCar(BuildContext context, Vehicle car, Map<String, Object?> changes) =>
    context.read<AppState>().mutate((r) => r.saveVehicle(Vehicle.fromMap({...car.toMap(), ...changes})));

// ── Budget ────────────────────────────────────────────────────────────────

/// This month against the budget, or a prompt to set one.
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.car, required this.spent});
  final Vehicle car;
  final double spent;

  Future<void> _edit(BuildContext context) async {
    final s = S.read(context);
    final v = await askAmount(context, title: s.budget, helper: s.budgetHint, initial: car.monthlyBudget, removeLabel: s.removeBudget);
    if (v == null || !context.mounted) return;
    await _saveCar(context, car, {'monthly_budget': v <= 0 ? null : v});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final budget = car.monthlyBudget;
    if (budget == null || budget <= 0) {
      return Panel(
        onTap: () => _edit(context),
        child: Row(children: [
          IconBubble(Icons.account_balance_wallet_rounded, p.info, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.setBudget, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(s.setBudgetSub, style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.3)),
            ]),
          ),
          Icon(Icons.add_circle_rounded, color: p.accent, size: 30),
        ]),
      );
    }
    final b = BudgetStatus(budget: budget, spent: spent);
    final color = switch (b.level) {
      BudgetLevel.ok => p.income,
      BudgetLevel.watch => p.warning,
      BudgetLevel.over => p.expense,
    };
    return Panel(
      onTap: () => _edit(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${s.budget} · ${f.month(b.today.month)}', style: TextStyle(color: p.muted, fontWeight: FontWeight.w600))),
          StatusPill(
            switch (b.level) {
              BudgetLevel.ok => s.budgetOnTrack,
              BudgetLevel.watch => s.budgetWatch,
              BudgetLevel.over => s.budgetOver(f.money(-b.left)),
            },
            color,
          ),
        ]),
        const SizedBox(height: 10),
        Text(s.budgetUsed(f.money(spent), f.money(budget)), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, c) {
          final projected = (b.projected / budget).clamp(0.0, 1.0);
          return Stack(children: [
            Container(height: 12, decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(6))),
            // Where this pace ends the month, shown faintly behind what is spent.
            Container(height: 12, width: c.maxWidth * projected, decoration: BoxDecoration(color: color.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6))),
            Container(height: 12, width: c.maxWidth * b.used.clamp(0.0, 1.0), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
          ]);
        }),
        const SizedBox(height: 10),
        Text(
          [
            if (b.left > 0) s.budgetLeft(f.money(b.left), b.daysLeft),
            if (b.left > 0) s.budgetPerDay(f.money(b.perDayLeft.roundToDouble())),
            if (b.today.day >= 7) s.budgetProjected(f.money(b.projected.roundToDouble())),
          ].join(' · '),
          style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.35),
        ),
      ]),
    );
  }
}

// ── Value ─────────────────────────────────────────────────────────────────

/// What the car has lost since it was bought, and the cost per km with it.
class CarValueCard extends StatelessWidget {
  const CarValueCard({super.key, required this.car, this.runningPerKm, this.measuredDays, this.distance});
  final Vehicle car;

  /// Running costs per km over the logged stretch, and that stretch.
  final double? runningPerKm;
  final int? measuredDays;
  final double? distance;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final v = CarValue.of(car);
    if (v == null) {
      return Panel(
        onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => VehicleFormScreen(vehicle: car))),
        child: Row(children: [
          IconBubble(Icons.trending_down_rounded, p.muted, size: 44),
          const SizedBox(width: 14),
          Expanded(child: Text(s.needPurchase, style: TextStyle(color: p.muted, fontSize: 13, height: 1.35))),
          const Icon(Icons.chevron_right_rounded),
        ]),
      );
    }
    final truePerKm = runningPerKm == null || distance == null || distance! <= 0 || measuredDays == null
        ? null
        : runningPerKm! + v.perDay * measuredDays! / distance!;

    return Panel(
      onTap: () async {
        final s = S.read(context);
        final value = await askAmount(context, title: s.setMarketValue, helper: s.marketValueHelp, initial: car.marketValue, removeLabel: s.estimatedTag);
        if (value == null || !context.mounted) return;
        await _saveCar(context, car, {'market_value': value <= 0 ? null : value});
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconBubble(Icons.trending_down_rounded, p.warning, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Text(s.carValue, style: const TextStyle(fontWeight: FontWeight.w700))),
          const Icon(Icons.edit_rounded, size: 18),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: KeyValue(s.boughtAt, f.money(v.price))),
          Expanded(child: KeyValue(v.estimated ? '${s.worthNow} (${s.estimatedTag})' : s.worthNow, f.money(v.now.roundToDouble()), color: p.income)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: v.lostShare.clamp(0, 1), minHeight: 8, color: p.warning, backgroundColor: p.surfaceAlt),
        ),
        const SizedBox(height: 8),
        Text('${s.lostSince(f.money(v.lost.roundToDouble()), f.percent(v.lostShare))} · ${s.lostPerMonth(f.money(v.perMonth.roundToDouble()))}',
            style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.35)),
        if (truePerKm != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(child: Text(s.trueCostPerKm, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Text('৳${f.number(truePerKm, decimals: 2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: p.expense)),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ── Driver salary ─────────────────────────────────────────────────────────

/// Salaried drivers on the personal dashboard, or a prompt to add one.
class SalaryCard extends StatelessWidget {
  const SalaryCard({super.key, required this.accounts, required this.vehicleId});
  final List<SalaryAccount> accounts;
  final int vehicleId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    if (accounts.isEmpty) {
      return Panel(
        onTap: () => openNewDriver(context),
        child: Row(children: [
          IconBubble(Icons.badge_rounded, ExpenseCategory.salary.color, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.addSalariedDriver, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(s.addSalariedDriverSub, style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.3)),
            ]),
          ),
          Icon(Icons.add_circle_rounded, color: p.accent, size: 30),
        ]),
      );
    }
    return Column(children: [
      for (var i = 0; i < accounts.length; i++) ...[if (i > 0) const SizedBox(height: 12), _SalaryTile(account: accounts[i], vehicleId: vehicleId)],
    ]);
  }
}

class _SalaryTile extends StatelessWidget {
  const _SalaryTile({required this.account, required this.vehicleId});
  final SalaryAccount account;
  final int vehicleId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final a = account;
    final d = a.driver;
    final color = a.owed ? p.warning : (a.advance ? p.info : p.income);
    return Panel(
      onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => DriverSalaryScreen(driverId: d.id!, vehicleId: vehicleId))),
      child: Row(children: [
        Avatar(name: d.name, initials: d.initials, size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.myDriver} · ${d.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              a.owed ? s.salaryOwed(f.money(a.balance)) : (a.advance ? s.salaryAdvance(f.money(-a.balance)) : s.salaryClear),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
            ),
            Text('${s.monthlySalary} ${f.money(d.monthlySalary)} · ${s.nextPayDay(f.date(a.nextPayDay))}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 42), padding: const EdgeInsets.symmetric(horizontal: 14)),
          onPressed: () => showSalarySheet(context, driver: d, vehicleId: vehicleId, suggest: a.owed ? a.balance : d.monthlySalary),
          child: Text(s.paySalary),
        ),
      ]),
    );
  }
}

enum _PayKind { salary, advance, bonus }

/// Records (or edits) a salary payment, advance or bonus.
Future<void> showSalarySheet(BuildContext context, {required Driver driver, required int vehicleId, double? suggest, Expense? payment}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SalarySheet(driver: driver, vehicleId: vehicleId, suggest: suggest, payment: payment),
  );
}

class _SalarySheet extends StatefulWidget {
  const _SalarySheet({required this.driver, required this.vehicleId, this.suggest, this.payment});
  final Driver driver;
  final int vehicleId;
  final double? suggest;
  final Expense? payment;

  @override
  State<_SalarySheet> createState() => _SalarySheetState();
}

class _SalarySheetState extends State<_SalarySheet> {
  late final _amount = TextEditingController(text: (widget.payment?.amount ?? widget.suggest)?.round().toString() ?? '');
  late DateTime _date = widget.payment?.date ?? DateUtils.dateOnly(DateTime.now());
  late PayMethod _method = widget.payment?.payMethod ?? PayMethod.cash;
  late _PayKind _kind = switch (widget.payment) {
    null => _PayKind.salary,
    final e when e.category == ExpenseCategory.bonus => _PayKind.bonus,
    final e when e.note == _noteFor(_PayKind.advance, true) || e.note == _noteFor(_PayKind.advance, false) => _PayKind.advance,
    _ => _PayKind.salary,
  };

  static String _noteFor(_PayKind k, bool bn) => switch (k) {
        _PayKind.salary => bn ? 'বেতন' : 'Salary',
        _PayKind.advance => bn ? 'অগ্রিম' : 'Advance',
        _PayKind.bonus => bn ? 'বোনাস' : 'Bonus',
      };

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseAmount(_amount.text);
    if (amount == null || amount <= 0) return;
    final s = S.read(context);
    final nav = Navigator.of(context);
    await context.read<AppState>().mutate((r) => r.saveExpense(Expense(
          id: widget.payment?.id,
          date: _date,
          vehicleId: widget.payment?.vehicleId ?? widget.vehicleId,
          category: _kind == _PayKind.bonus ? ExpenseCategory.bonus : ExpenseCategory.salary,
          amount: amount,
          note: '${_noteFor(_kind, s.bn)} · ${widget.driver.name}',
          payMethod: _method,
          driverId: widget.driver.id,
        )));
    HapticFeedback.mediumImpact();
    nav.pop();
  }

  Future<void> _delete() async {
    final s = S.read(context);
    if (!await confirm(context, title: s.deleteEntry, body: s.confirmDeleteBody)) return;
    if (!mounted) return;
    final nav = Navigator.of(context);
    await context.read<AppState>().mutate((r) => r.deleteExpense(widget.payment!.id!));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Contained(
          maxWidth: 560,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.salaryPayment} · ${widget.driver.name}', style: context.text.titleLarge),
              const SizedBox(height: 16),
              PillToggle<_PayKind>(
                values: _PayKind.values,
                selected: _kind,
                label: (k) => switch (k) {
                  _PayKind.salary => s.kindSalary,
                  _PayKind.advance => s.kindAdvance,
                  _PayKind.bonus => s.kindBonus,
                },
                onChanged: (k) => setState(() => _kind = k),
              ),
              if (_kind == _PayKind.bonus)
                Padding(padding: const EdgeInsets.only(top: 8, left: 4), child: Text(s.bonusNote, style: TextStyle(color: p.muted, fontSize: 12.5))),
              const SizedBox(height: 16),
              TextField(
                controller: _amount,
                autofocus: widget.payment == null,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                decoration: InputDecoration(labelText: s.amount, prefixText: '৳ '),
              ),
              const SizedBox(height: 12),
              DateFormField(label: s.date, value: _date, onPick: (d) => setState(() => _date = d)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in PayMethod.values.where((m) => m != PayMethod.cheque && m != PayMethod.card))
                  ChoiceTag(label: m.label(s), icon: m.icon, selected: _method == m, onTap: () => setState(() => _method = m)),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                if (widget.payment != null) ...[
                  OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: p.expense), onPressed: _delete, child: const Icon(Icons.delete_outline_rounded)),
                  const SizedBox(width: 10),
                ],
                Expanded(child: FilledButton(onPressed: _save, child: Text(s.save))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Month by month: salary due, what was paid, advances and bonuses.
class DriverSalaryScreen extends StatelessWidget {
  const DriverSalaryScreen({super.key, required this.driverId, required this.vehicleId});
  final int driverId;
  final int vehicleId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final d = app.driver(driverId);
    if (d == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: Text(d.name),
        actions: [
          if (d.phone?.isNotEmpty ?? false) IconButton(icon: const Icon(Icons.call_rounded), onPressed: () => launchUrl(Uri(scheme: 'tel', path: d.phone))),
          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => Navigator.of(context).push(AppRoute(builder: (_) => DriverFormScreen(driver: d)))),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSalarySheet(context, driver: d, vehicleId: vehicleId, suggest: d.monthlySalary),
        icon: const Icon(Icons.payments_rounded),
        label: Text(s.paySalary),
      ),
      body: Loader<(SalaryAccount, List<Expense>)>(
        deps: [driverId],
        load: (r) async {
          final pays = await r.driverPayments(driverId);
          return (SalaryAccount.build(d, pays), pays);
        },
        builder: (context, data) {
          final (a, pays) = data;
          final color = a.owed ? p.warning : (a.advance ? p.info : p.accent);
          return Contained(
            maxWidth: 760,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 100), children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.salaryStatement, style: TextStyle(color: p.onHero.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    a.owed ? s.salaryOwed(f.money(a.balance)) : (a.advance ? s.salaryAdvance(f.money(-a.balance)) : s.salaryClear),
                    style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _heroKv(context, s.monthlySalary, f.money(d.monthlySalary))),
                    Expanded(child: _heroKv(context, s.totalPaid, f.money(a.paid))),
                    Expanded(child: _heroKv(context, s.totalBonus, f.money(a.bonus))),
                  ]),
                  const SizedBox(height: 10),
                  Text(s.nextPayDay(f.date(a.nextPayDay)), style: TextStyle(color: p.onHero.withValues(alpha: 0.6), fontSize: 12.5)),
                ]),
              ),
              SectionHeader(s.salaryStatement),
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(children: [
                  for (final m in a.months.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(identical(m, a.current) ? '${_span(f, m)} · ${s.runningMonth}' : _span(f, m), style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '${s.monthSalaryLine(f.money(m.paid), f.money(m.salary))}${m.bonus > 0 ? ' · ${s.kindBonus} ${f.money(m.bonus)}' : ''}',
                              style: TextStyle(color: p.muted, fontSize: 12.5),
                            ),
                          ]),
                        ),
                        if (!identical(m, a.current))
                          Icon(m.paid >= m.salary ? Icons.check_circle_rounded : Icons.schedule_rounded, color: m.paid >= m.salary ? p.income : p.warning, size: 20),
                      ]),
                    ),
                ]),
              ),
              if (pays.isNotEmpty) ...[
                SectionHeader(s.history),
                Panel(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Column(children: [
                    for (final e in pays.reversed)
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => showSalarySheet(context, driver: d, vehicleId: vehicleId, payment: e),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Row(children: [
                            IconBubble(e.category.icon, e.category.color, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(f.money(e.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                                Text([f.date(e.date), if (e.note != null) e.note!.split(' · ').first, if (e.payMethod != null) e.payMethod!.label(s)].join(' · '),
                                    style: TextStyle(color: p.muted, fontSize: 12.5)),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }

  /// "October 2026" when he joined on the 1st, else "24 Sep – 23 Oct".
  static String _span(Fmt f, SalaryMonth m) {
    if (m.from.day == 1) return f.monthYear(m.from);
    final last = m.to.subtract(const Duration(days: 1));
    return '${f.digits(m.from.day)} ${f.monthShort(m.from.month)} – ${f.digits(last.day)} ${f.monthShort(last.month)}';
  }

  Widget _heroKv(BuildContext context, String k, String v) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.onHero.withValues(alpha: 0.6), fontSize: 11.5)),
      Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.onHero, fontWeight: FontWeight.w800, fontSize: 15)),
    ]);
  }
}
