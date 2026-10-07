import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'daily_collection_screen.dart';
import 'documents_screen.dart';
import 'maintenance_screen.dart';
import 'parties_screen.dart';
import 'service_screens.dart';
import 'trip_screens.dart';

enum EntryMode { fuel, expense, trip, due, joma }

/// Opens the right editor for a ledger row.
Future<void> openEntryEditor(BuildContext context, LedgerEntry e) async {
  final repo = context.read<AppState>().repo;
  if (e.tripId != null) return openTrip(context, e.tripId!);
  if (e.visitId != null) return openVisit(context, e.visitId!);
  if (e.partId != null) {
    final part = await repo.part(e.partId!);
    if (part == null || !context.mounted) return;
    return openFitting(context, part);
  }
  if (e.isIncome) {
    final i = await repo.income(e.id);
    if (i == null || !context.mounted) return;
    final mode = switch (i.kind) {
      IncomeKind.trip => EntryMode.trip,
      IncomeKind.due => EntryMode.due,
      _ => EntryMode.joma,
    };
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EntryScreen(mode: mode, income: i)));
  } else {
    final x = await repo.expense(e.id);
    if (x == null || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => EntryScreen(mode: x.category == ExpenseCategory.fuel ? EntryMode.fuel : EntryMode.expense, expense: x)));
  }
}

Future<void> openEntry(BuildContext context, EntryMode mode, {int? vehicleId, int? driverId}) {
  return Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => EntryScreen(mode: mode, vehicleId: vehicleId, driverId: driverId),
  ));
}

/// Bottom sheet with every kind of entry an owner records.
Future<void> showQuickAdd(BuildContext context) {
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
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                child: Text(s.quickAdd, style: ctx.text.headlineSmall),
              ),
              Pressable(
                onTap: () => go(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyCollectionScreen()))),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(kRadius)),
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: p.onAccent, borderRadius: BorderRadius.circular(16)),
                      child: Icon(Icons.payments_rounded, color: p.accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.dailyCollection, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: p.onAccent)),
                        Text(s.dailyCollectionSub, style: TextStyle(color: p.onAccent.withValues(alpha: 0.7), fontSize: 13)),
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
                childAspectRatio: 1.45,
                children: [
                  option(Icons.route_rounded, p.income, s.newTrip, s.newTripSub, () => openTripForm(context)),
                  option(Icons.garage_rounded, ExpenseCategory.servicing.color, s.visitQuick, s.visitQuickSub, () => openVisitForm(context)),
                  option(Icons.local_gas_station_rounded, ExpenseCategory.fuel.color, s.fuel, s.fuelSub, () => openEntry(context, EntryMode.fuel)),
                  option(PartType.engineOil.icon, PartType.engineOil.color, s.partFitted, s.partFittedSub, () => openPartForm(context)),
                  option(Icons.groups_rounded, p.info, s.partyCollectQuick, s.partyCollectQuickSub, () => openParties(context)),
                  option(Icons.savings_rounded, p.warning, s.duePayment, s.duePaymentSub, () => openEntry(context, EntryMode.due)),
                  option(Icons.receipt_long_rounded, ExpenseCategory.repair.color, s.otherCost, s.otherCostSub, () => openEntry(context, EntryMode.expense)),
                  option(Icons.event_note_rounded, ExpenseCategory.papers.color, s.papers, s.paperExpirySub, () => showPaperSheet(context)),
                ],
              ),
            ]),
          ),
        ),
      );
    },
  );
}

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key, required this.mode, this.income, this.expense, this.vehicleId, this.driverId});
  final EntryMode mode;
  final Income? income;
  final Expense? expense;
  final int? vehicleId;
  final int? driverId;

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _focus = FocusNode();
  final _note = TextEditingController();
  final _qty = TextEditingController();
  final _odo = TextEditingController();
  String _raw = '';
  int? _vehicleId;
  int? _driverId;
  ExpenseCategory _category = ExpenseCategory.servicing;
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  bool _saving = false;
  int _shake = 0;

  bool get _editing => widget.income != null || widget.expense != null;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final i = widget.income;
    final x = widget.expense;
    if (i != null) {
      _raw = i.amount.round().toString();
      _vehicleId = i.vehicleId;
      _driverId = i.driverId;
      _date = i.date;
      _note.text = i.note ?? '';
    } else if (x != null) {
      _raw = x.amount.round().toString();
      _vehicleId = x.vehicleId;
      _category = x.category;
      _date = x.date;
      _note.text = x.note ?? '';
      if (x.quantity != null) _qty.text = _trimNum(x.quantity!);
      if (x.odometer != null) _odo.text = _trimNum(x.odometer!);
    } else {
      _driverId = widget.driverId;
      _vehicleId = widget.vehicleId;
      if (widget.mode == EntryMode.due && _driverId == null) {
        // Pre-select the driver who owes the most.
        final owing = app.dues.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
        if (owing.isNotEmpty) _driverId = owing.first.key;
      }
      if (widget.mode == EntryMode.due && _driverId != null) {
        _vehicleId ??= app.vehicleOfDriver(_driverId!)?.id;
        final due = app.dues[_driverId] ?? 0;
        if (due > 0) _raw = due.round().toString();
      }
      final active = app.activeVehicles;
      _vehicleId ??= active.isNotEmpty ? active.first.id : (app.vehicles.isNotEmpty ? app.vehicles.first.id : null);
      if (widget.mode == EntryMode.fuel) _category = ExpenseCategory.fuel;
    }
    if (widget.mode == EntryMode.fuel) _category = ExpenseCategory.fuel;
  }

  String _trimNum(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  void dispose() {
    _focus.dispose();
    _note.dispose();
    _qty.dispose();
    _odo.dispose();
    super.dispose();
  }

  void _key(String k) {
    HapticFeedback.lightImpact();
    setState(() {
      if (k == '⌫') {
        if (_raw.isNotEmpty) _raw = _raw.substring(0, _raw.length - 1);
      } else if (_raw.length < 9) {
        if (_raw.isEmpty && (k == '0' || k == '00')) return;
        _raw += k;
        if (_raw.length > 9) _raw = _raw.substring(0, 9);
      }
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (FocusManager.instance.primaryFocus != _focus) return KeyEventResult.ignored;
    final ch = event.character;
    if (ch != null && RegExp(r'^[0-9]$').hasMatch(ch)) {
      _key(ch);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _key('⌫');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _save();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _title() {
    final s = context.s;
    return switch (widget.mode) {
      EntryMode.fuel => s.fuel,
      EntryMode.expense => s.maintenance,
      EntryMode.trip => s.tripIncome,
      EntryMode.due => s.duePayment,
      EntryMode.joma => s.dailyCollection,
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    final s = context.s;
    final amount = double.tryParse(_raw) ?? 0;
    final app = context.read<AppState>();
    if (_vehicleId == null) {
      toast(context, s.noVehicleYet, icon: Icons.info_outline_rounded);
      return;
    }
    if (amount <= 0 && widget.mode != EntryMode.joma) {
      setState(() => _shake++);
      HapticFeedback.heavyImpact();
      return;
    }
    if (widget.mode == EntryMode.due && _driverId == null) {
      toast(context, s.whoPaid, icon: Icons.info_outline_rounded);
      return;
    }
    setState(() => _saving = true);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final vehicle = app.vehicle(_vehicleId)!;
    try {
      switch (widget.mode) {
        case EntryMode.fuel:
        case EntryMode.expense:
          await app.mutate((r) => r.saveExpense(Expense(
                id: widget.expense?.id,
                date: _date,
                vehicleId: _vehicleId!,
                category: _category,
                amount: amount,
                quantity: _category == ExpenseCategory.fuel ? parseAmount(_qty.text) : null,
                odometer: _category == ExpenseCategory.fuel ? parseAmount(_odo.text) : null,
                note: note,
                place: widget.expense?.place,
                tripId: widget.expense?.tripId,
                partId: widget.expense?.partId,
              )));
        case EntryMode.trip:
          await app.mutate((r) => r.saveIncome(Income(
                id: widget.income?.id,
                date: _date,
                vehicleId: _vehicleId!,
                driverId: widget.income?.driverId ?? vehicle.driverId,
                kind: IncomeKind.trip,
                amount: amount,
                note: note,
                tripId: widget.income?.tripId,
              )));
        case EntryMode.due:
          await app.mutate((r) => r.saveIncome(Income(
                id: widget.income?.id,
                date: _date,
                vehicleId: _vehicleId!,
                driverId: _driverId,
                kind: IncomeKind.due,
                amount: amount,
                note: note,
              )));
        case EntryMode.joma:
          final old = widget.income;
          await app.mutate((r) => r.saveIncome(Income(
                id: old?.id,
                date: _date,
                vehicleId: _vehicleId!,
                driverId: old?.driverId ?? vehicle.driverId,
                kind: old?.kind == IncomeKind.off && amount > 0 ? IncomeKind.joma : (old?.kind ?? IncomeKind.joma),
                target: old != null && old.kind != IncomeKind.off ? old.target : vehicle.dailyTarget,
                amount: amount,
                note: note,
              )));
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      toast(context, s.entrySaved);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, s.somethingWrong(e), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final s = context.s;
    if (!await confirm(context, title: s.deleteEntry, body: s.confirmDeleteBody)) return;
    if (!mounted) return;
    final app = context.read<AppState>();
    if (widget.income != null) {
      await app.mutate((r) => r.deleteIncome(widget.income!.id!));
    } else if (widget.expense != null) {
      await app.mutate((r) => r.deleteExpense(widget.expense!.id!));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final app = context.watch<AppState>();
    final amount = double.tryParse(_raw) ?? 0;
    final vehicle = app.vehicle(_vehicleId);
    final accent = switch (widget.mode) {
      EntryMode.trip || EntryMode.joma => p.income,
      EntryMode.due => p.warning,
      _ => _category.color,
    };

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            title: Text(_title()),
            actions: [
              if (_editing) IconButton(icon: Icon(Icons.delete_outline_rounded, color: p.expense), onPressed: _delete),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Contained(
              maxWidth: 560,
              child: Column(children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      if (widget.mode == EntryMode.due) ...[
                        _label(s.whoPaid),
                        _driverPicker(app),
                        const SizedBox(height: 18),
                      ],
                      _label(s.selectVehicle),
                      _vehiclePicker(app),
                      if (widget.mode == EntryMode.expense) ...[
                        const SizedBox(height: 18),
                        _label(s.category),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final c in ExpenseCategory.values.where((c) => c != ExpenseCategory.fuel))
                            ChoiceTag(label: c.label(s), icon: c.icon, color: c.color, selected: _category == c, onTap: () => setState(() => _category = c)),
                        ]),
                      ],
                      const SizedBox(height: 26),
                      _AmountDisplay(text: _raw.isEmpty ? f.money(0) : f.money(amount), empty: _raw.isEmpty, color: accent, shake: _shake),
                      if (widget.mode == EntryMode.joma && vehicle != null && (widget.income?.target ?? vehicle.dailyTarget) > 0)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('${s.target}: ${f.money(widget.income?.target ?? vehicle.dailyTarget)}', style: TextStyle(color: p.muted, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      if (widget.mode == EntryMode.due && _driverId != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('${s.currentDue}: ${f.money(app.dues[_driverId] ?? 0)}', style: TextStyle(color: p.muted, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      const SizedBox(height: 22),
                      if (widget.mode == EntryMode.fuel) ...[
                        Row(children: [
                          Expanded(child: _smallField(_qty, s.liters, Icons.water_drop_outlined)),
                          const SizedBox(width: 10),
                          Expanded(child: _smallField(_odo, s.odometer, Icons.speed_rounded)),
                        ]),
                        const SizedBox(height: 10),
                      ],
                      Row(children: [
                        _DateChip(date: _date, onPick: (d) => setState(() => _date = d)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _note,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _focus.requestFocus(),
                            decoration: InputDecoration(
                              hintText: widget.mode == EntryMode.trip ? s.tripFrom : s.noteHint,
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                              isDense: true,
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                _Numpad(onKey: _key, onClear: () => setState(() => _raw = ''), onSave: _save, saving: _saving, saveLabel: s.save),
              ]),
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

  Widget _smallField(TextEditingController c, String label, IconData icon) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onSubmitted: (_) => _focus.requestFocus(),
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), isDense: true),
      );

  Widget _vehiclePicker(AppState app) {
    final s = context.s;
    if (app.vehicles.isEmpty) {
      return Text(s.noVehicleYet, style: TextStyle(color: context.pal.expense, fontWeight: FontWeight.w600));
    }
    return SizedBox(
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
            onTap: () => setState(() => _vehicleId = v.id),
          );
        },
      ),
    );
  }

  Widget _driverPicker(AppState app) {
    final f = context.fmt;
    if (app.drivers.isEmpty) return Text(context.s.noDrivers, style: TextStyle(color: context.pal.muted));
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: app.drivers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = app.drivers[i];
          final due = app.dues[d.id] ?? 0;
          return ChoiceTag(
            label: due > 0 ? '${d.name} · ${f.money(due)}' : d.name,
            icon: Icons.person_rounded,
            selected: d.id == _driverId,
            onTap: () => setState(() {
              _driverId = d.id;
              _vehicleId = app.vehicleOfDriver(d.id!)?.id ?? _vehicleId;
              if (due > 0 && !_editing) _raw = due.round().toString();
            }),
          );
        },
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.text, required this.empty, required this.color, required this.shake});
  final String text;
  final bool empty;
  final Color color;
  final int shake;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return TweenAnimationBuilder<double>(
      key: ValueKey(shake),
      tween: Tween(begin: shake == 0 ? 0 : 1, end: 0),
      duration: const Duration(milliseconds: 420),
      builder: (_, t, child) => Transform.translate(offset: Offset(12 * t * (((t * 10).floor().isEven) ? 1 : -1), 0), child: child),
      child: Column(children: [
        Container(
          width: 46,
          height: 5,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: c)),
            child: Text(
              text,
              key: ValueKey(text),
              style: TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
                height: 1,
                color: empty ? p.muted.withValues(alpha: 0.5) : p.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.onPick});
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Pressable(
      onTap: () async {
        final d = await pickDate(context, date, last: DateTime.now().add(const Duration(days: 1)));
        if (d != null) onPick(d);
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: p.muted),
          const SizedBox(width: 8),
          Text(context.fmt.relativeDay(date, context.s), style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onKey, required this.onClear, required this.onSave, required this.saving, required this.saveLabel});
  final ValueChanged<String> onKey;
  final VoidCallback onClear;
  final VoidCallback onSave;
  final bool saving;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final f = context.fmt;
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '0', '⌫'];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (var row = 0; row < 4; row++)
          Row(children: [
            for (var col = 0; col < 3; col++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _NumKey(
                    label: keys[row * 3 + col] == '⌫' ? null : f.digits(keys[row * 3 + col]),
                    icon: keys[row * 3 + col] == '⌫' ? Icons.backspace_outlined : null,
                    onTap: () => onKey(keys[row * 3 + col]),
                    onLongPress: keys[row * 3 + col] == '⌫' ? onClear : null,
                  ),
                ),
              ),
          ]),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: saving ? null : onSave,
              child: saving
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onAccent))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check_rounded),
                      const SizedBox(width: 8),
                      Text(saveLabel, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({this.label, this.icon, required this.onTap, this.onLongPress});
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: p.surfaceAlt.withValues(alpha: p.isDark ? 0.7 : 0.6),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: 54,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 24, color: p.ink)
                : Text(label!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ),
      ),
    );
  }
}
