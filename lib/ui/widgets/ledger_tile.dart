import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../screens/entry_screen.dart';
import 'common.dart';

/// One income/expense row. Tap opens the editor; long-press offers delete.
class LedgerTile extends StatelessWidget {
  const LedgerTile(this.e, {super.key, this.showVehicle = true, this.showDate = false});
  final LedgerEntry e;
  final bool showVehicle;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final app = context.watch<AppState>();
    final vehicle = app.vehicle(e.vehicleId);
    final driver = app.driver(e.driverId);

    final String title;
    final IconData icon;
    final Color color;
    if (e.isIncome) {
      title = e.incomeKind.label(s);
      icon = e.incomeKind.icon;
      color = p.income;
    } else if (e.partType != null) {
      title = e.partType!.label(s);
      icon = e.partType!.icon;
      color = e.partType!.color;
    } else {
      title = e.expenseCategory.label(s);
      icon = e.expenseCategory.icon;
      color = e.expenseCategory.color;
    }

    final subtitle = <String>[
      if (showDate) f.dayMonth(e.date),
      if (showVehicle && vehicle != null) vehicle.name,
      if (driver != null && e.incomeKind != IncomeKind.trip) driver.name,
      if (e.route != null) e.route!,
      if (e.workshop?.isNotEmpty ?? false) e.workshop!,
      if (e.place?.isNotEmpty ?? false) e.place!,
      if (e.quantity != null) '${f.number(e.quantity!, decimals: 1)} ${s.bn ? 'ইউনিট' : 'units'}',
      // A trip fare's note just repeats the route.
      if (e.note != null && e.note!.isNotEmpty && !(e.isIncome && e.tripId != null)) e.note!,
    ].join(' · ');

    final short = e.isIncome && e.incomeKind == IncomeKind.joma && e.amount < e.target ? e.target - e.amount : 0.0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => openEntryEditor(context, e),
      // Trip and part rows are deleted from their own screens.
      onLongPress: () => e.isLinked ? openEntryEditor(context, e) : deleteLedgerEntry(context, e),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(children: [
          IconBubble(icon, color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              if (subtitle.isNotEmpty)
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${e.isIncome ? '+' : '−'}${f.money(e.amount)}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: e.isIncome ? p.income : p.ink, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            if (short > 0) Text(s.shortBy(f.money(short)), style: TextStyle(color: p.warning, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

Future<void> deleteLedgerEntry(BuildContext context, LedgerEntry e) async {
  final s = context.s;
  final ok = await confirm(context, title: s.deleteEntry, body: s.confirmDeleteBody);
  if (!ok || !context.mounted) return;
  final app = context.read<AppState>();
  await app.mutate((r) => e.isIncome ? r.deleteIncome(e.id) : r.deleteExpense(e.id));
  if (context.mounted) toast(context, s.deleted, icon: Icons.delete_outline_rounded);
}

/// Date header with the day's net amount, used in grouped ledgers.
class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.date, required this.net});
  final DateTime date;
  final double net;

  @override
  Widget build(BuildContext context) {
    final f = context.fmt;
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 18, 6, 4),
      child: Row(children: [
        Text(f.relativeDay(date, context.s), style: TextStyle(fontWeight: FontWeight.w700, color: p.muted, fontSize: 13)),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: p.line)),
        const SizedBox(width: 10),
        Text(f.money(net, sign: true), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: net >= 0 ? p.income : p.expense)),
      ]),
    );
  }
}

/// Groups entries by day and renders headers + tiles.
List<Widget> groupedLedger(List<LedgerEntry> entries, {bool showVehicle = true}) {
  final out = <Widget>[];
  DateTime? current;
  var bucket = <LedgerEntry>[];
  void flush() {
    if (current == null) return;
    final net = bucket.fold<double>(0, (a, e) => a + (e.isIncome ? e.amount : -e.amount));
    out.add(DayHeader(date: current, net: net));
    for (final e in bucket) {
      out.add(LedgerTile(e, showVehicle: showVehicle));
    }
  }

  for (final e in entries) {
    if (current == null || dbDate(current) != dbDate(e.date)) {
      flush();
      current = e.date;
      bucket = [];
    }
    bucket.add(e);
  }
  flush();
  return out;
}
