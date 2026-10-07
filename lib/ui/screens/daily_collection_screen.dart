import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class _Row {
  _Row(this.vehicle, this.existing, String Function(Object) digits)
      : ctl = TextEditingController(
            text: existing != null && existing.kind == IncomeKind.joma ? digits(existing.amount.round()) : ''),
        off = existing?.kind == IncomeKind.off;

  final Vehicle vehicle;
  final Income? existing;
  final TextEditingController ctl;
  bool off;

  double get target => existing != null && existing!.kind == IncomeKind.joma ? existing!.target : vehicle.dailyTarget;
  double? get amount => parseAmount(ctl.text);
  bool get done => off || amount != null;
}

/// One screen to record every vehicle's hand-over for a day.
class DailyCollectionScreen extends StatefulWidget {
  const DailyCollectionScreen({super.key, this.date});
  final DateTime? date;

  @override
  State<DailyCollectionScreen> createState() => _DailyCollectionScreenState();
}

class _DailyCollectionScreenState extends State<DailyCollectionScreen> {
  late DateTime _date = DateUtils.dateOnly(widget.date ?? DateTime.now());
  List<_Row>? _rows;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final r in _rows ?? <_Row>[]) {
      r.ctl.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    final existing = await app.repo.dailyEntries(_date);
    final vehicles = app.vehicles.where((v) => v.isActive || existing.containsKey(v.id)).toList();
    if (!mounted) return;
    setState(() {
      for (final r in _rows ?? <_Row>[]) {
        r.ctl.dispose();
      }
      final f = Fmt.read(context);
      _rows = [for (final v in vehicles) _Row(v, existing[v.id], f.digits)];
    });
  }

  void _shiftDay(int delta) {
    final next = _date.add(Duration(days: delta));
    if (next.isAfter(DateUtils.dateOnly(DateTime.now()))) return;
    setState(() => _date = next);
    _load();
  }

  void _markAllFull() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (final r in _rows!) {
        if (!r.done) {
          r.off = false;
          r.ctl.text = Fmt.read(context).digits(r.target.round());
        }
      }
    });
  }

  Future<void> _save() async {
    final rows = _rows;
    if (rows == null || _saving) return;
    final app = context.read<AppState>();
    final s = context.s;
    final entries = <Income>[];
    final remove = <int>[];
    for (final r in rows) {
      final driverId = r.existing?.driverId ?? r.vehicle.driverId;
      if (r.off) {
        entries.add(Income(id: r.existing?.id, date: _date, vehicleId: r.vehicle.id!, driverId: driverId, kind: IncomeKind.off, amount: 0));
      } else if (r.amount != null) {
        entries.add(Income(
          id: r.existing?.id,
          date: _date,
          vehicleId: r.vehicle.id!,
          driverId: driverId,
          kind: IncomeKind.joma,
          target: r.target,
          amount: r.amount!,
          note: r.existing?.note,
        ));
      } else if (r.existing != null) {
        remove.add(r.existing!.id!);
      }
    }
    setState(() => _saving = true);
    try {
      await app.mutate((repo) => repo.saveDailyBatch(entries, remove));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      toast(context, s.saved);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, s.somethingWrong(e), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final rows = _rows;
    final collected = rows?.fold<double>(0, (a, r) => a + (r.off ? 0 : (r.amount ?? 0))) ?? 0;
    final target = rows?.fold<double>(0, (a, r) => a + (r.off ? 0 : r.target)) ?? 0;
    final doneCount = rows?.where((r) => r.done).length ?? 0;
    final isToday = DateUtils.isSameDay(_date, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(s.dailyCollection),
        actions: [
          if (rows != null && rows.any((r) => !r.done))
            TextButton.icon(onPressed: _markAllFull, icon: const Icon(Icons.done_all_rounded, size: 20), label: Text(s.markFull)),
          const SizedBox(width: 8),
        ],
      ),
      body: rows == null
          ? const Center(child: CircularProgressIndicator())
          : Contained(
              maxWidth: 720,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
                    decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(kRadius + 4)),
                    child: Column(children: [
                      Row(children: [
                        IconButton(onPressed: () => _shiftDay(-1), icon: Icon(Icons.chevron_left_rounded, color: p.onHero)),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final d = await pickDate(context, _date, last: DateTime.now());
                              if (d != null) {
                                setState(() => _date = d);
                                _load();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(children: [
                                Text(f.relativeDay(_date, s), style: TextStyle(color: p.onHero, fontWeight: FontWeight.w700, fontSize: 16)),
                                Text(f.date(_date), style: TextStyle(color: p.onHero.withValues(alpha: 0.6), fontSize: 12)),
                              ]),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isToday ? null : () => _shiftDay(1),
                          icon: Icon(Icons.chevron_right_rounded, color: isToday ? p.onHero.withValues(alpha: 0.25) : p.onHero),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text.rich(TextSpan(children: [
                                TextSpan(text: f.money(collected), style: TextStyle(color: p.accent, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1)),
                                TextSpan(text: '  / ${f.money(target)}', style: TextStyle(color: p.onHero.withValues(alpha: 0.55), fontSize: 16, fontWeight: FontWeight.w600)),
                              ])),
                            ),
                          ),
                          Text(s.collectedCount(doneCount, rows.length), style: TextStyle(color: p.onHero.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SegmentBar(
                          track: p.onHero.withValues(alpha: 0.12),
                          parts: [
                            for (final r in rows)
                              (r.off ? 1.0 : (r.target <= 0 ? (r.amount != null ? 1.0 : 0.0) : (r.amount ?? 0) / r.target), r.off ? p.onHero.withValues(alpha: 0.3) : r.vehicle.type.color),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
                Expanded(
                  child: rows.isEmpty
                      ? EmptyState(icon: Icons.directions_car_filled_rounded, title: s.noActiveVehicles)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: rows.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => Entrance(index: i, child: _rowCard(rows[i])),
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        onPressed: _saving || rows.isEmpty ? null : _save,
                        child: _saving
                            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onAccent))
                            : Text('${s.saveCollection} · ${f.money(collected)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _rowCard(_Row r) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final app = context.watch<AppState>();
    final driver = app.driver(r.existing?.driverId ?? r.vehicle.driverId);
    final amt = r.amount;
    final short = !r.off && amt != null && amt < r.target ? r.target - amt : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: r.done ? (r.off ? p.line : r.vehicle.type.color.withValues(alpha: 0.7)) : p.line, width: r.done ? 1.6 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          TypeBadge(r.vehicle.type, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.vehicle.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
              Text(
                '${driver?.name ?? s.noDriver} · ${s.target} ${f.money(r.target)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.muted, fontSize: 12.5),
              ),
            ]),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: r.done
                ? Icon(r.off ? Icons.do_not_disturb_on_rounded : Icons.check_circle_rounded, key: ValueKey(r.off), color: r.off ? p.muted : p.income)
                : const SizedBox(width: 24),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: r.ctl,
              enabled: !r.off,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯]'))],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                prefixText: '৳ ',
                hintText: r.off ? s.offDay : f.number(r.target),
                fillColor: p.bg,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _miniBtn(s.markFull, !r.off && amt != null && amt >= r.target, p.income, () {
            setState(() {
              r.off = false;
              r.ctl.text = Fmt.read(context).digits(r.target.round());
            });
          }),
          const SizedBox(width: 6),
          _miniBtn(s.markOff, r.off, p.muted, () {
            setState(() {
              r.off = !r.off;
              if (r.off) r.ctl.clear();
            });
          }),
        ]),
        if (short > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 14, color: p.warning),
              const SizedBox(width: 4),
              Text('${s.shortBy(f.money(short))} → ${s.due}', style: TextStyle(color: p.warning, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ]),
          ),
      ]),
    );
  }

  Widget _miniBtn(String label, bool active, Color color, VoidCallback onTap) {
    final p = context.pal;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? color : p.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: active ? Colors.white : p.ink)),
      ),
    );
  }
}
