import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/ledger_tile.dart';

enum _Filter { all, income, expense }

/// Month-by-month combined ledger with type and vehicle filters.
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  _Filter _filter = _Filter.all;
  int? _vehicleId;

  bool get _isCurrentMonth {
    final n = DateTime.now();
    return _month.year == n.year && _month.month == n.month;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final app = context.watch<AppState>();

    return SafeArea(
      bottom: false,
      child: Contained(
        maxWidth: 820,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(children: [
              Expanded(child: Text(s.ledger, style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
              IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left_rounded)),
              Text(f.monthYear(_month), style: const TextStyle(fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: _isCurrentMonth ? null : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PillToggle<_Filter>(
              values: _Filter.values,
              selected: _filter,
              label: (v) => switch (v) {
                _Filter.all => s.filterAll,
                _Filter.income => s.filterIncome,
                _Filter.expense => s.filterExpense,
              },
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          if (app.vehicles.length > 1)
            SizedBox(
              height: 58,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                children: [
                  ChoiceTag(label: s.all, selected: _vehicleId == null, onTap: () => setState(() => _vehicleId = null)),
                  for (final v in app.vehicles) ...[
                    const SizedBox(width: 8),
                    ChoiceTag(label: v.name, icon: v.type.icon, color: v.type.color, selected: _vehicleId == v.id, onTap: () => setState(() => _vehicleId = v.id)),
                  ],
                ],
              ),
            ),
          Expanded(
            child: Loader<List<LedgerEntry>>(
              deps: [_month, _filter, _vehicleId],
              load: (r) => r.ledger(
                period: Period.month(_month),
                vehicleId: _vehicleId,
                incomeOnly: switch (_filter) {
                  _Filter.all => null,
                  _Filter.income => true,
                  _Filter.expense => false,
                },
              ),
              builder: (context, entries) {
                final income = entries.where((e) => e.isIncome).fold<double>(0, (a, e) => a + e.amount);
                final expense = entries.where((e) => !e.isIncome).fold<double>(0, (a, e) => a + e.amount);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(kRadius), border: Border.all(color: p.line)),
                      child: Row(children: [
                        Expanded(child: _sum(context, s.income, income, p.income)),
                        Container(width: 1, height: 34, color: p.line),
                        Expanded(child: _sum(context, s.expense, expense, p.expense)),
                        Container(width: 1, height: 34, color: p.line),
                        Expanded(child: _sum(context, s.profit, income - expense, p.ink)),
                      ]),
                    ),
                    if (entries.isEmpty)
                      EmptyState(icon: Icons.receipt_long_rounded, title: s.noEntries, body: s.noEntriesBody)
                    else
                      ...groupedLedger(entries, showVehicle: _vehicleId == null),
                  ],
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sum(BuildContext context, String label, double v, Color c) => Column(children: [
        Text(label, style: TextStyle(color: context.pal.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(context.fmt.money(v), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c))),
      ]);
}
