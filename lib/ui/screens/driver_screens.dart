import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/heatmap.dart';
import '../widgets/ledger_tile.dart';
import 'entry_screen.dart';
import 'vehicle_screens.dart';
import '../routes.dart';
import '../widgets/access_gate.dart';

/// Opens the add-driver form if the account has room; returns the new id.
Future<int?> openNewDriver(BuildContext context) async {
  if (!await requireDriverSlot(context, context.read<AppState>().drivers.length) || !context.mounted) return null;
  return Navigator.of(context).push<int>(AppRoute(builder: (_) => const DriverFormScreen()));
}

class DriverList extends StatelessWidget {
  const DriverList({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    if (app.drivers.isEmpty) {
      return EmptyState(
        icon: Icons.person_rounded,
        title: s.noDrivers,
        action: FilledButton.icon(
          onPressed: () => openNewDriver(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(s.addDriver),
        ),
      );
    }
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
      final items = [for (var i = 0; i < app.drivers.length; i++) Entrance(index: i, child: DriverCard(driver: app.drivers[i]))];
      if (cols == 1) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => items[i],
        );
      }
      return GridView.count(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3.2,
        children: items,
      );
    });
  }
}

class DriverCard extends StatelessWidget {
  const DriverCard({super.key, required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final due = app.dues[driver.id] ?? 0;
    final vehicle = app.vehicleOfDriver(driver.id!);

    return Panel(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => DriverDetailScreen(driverId: driver.id!))),
      child: Row(children: [
        Avatar(name: driver.name, initials: driver.initials, size: 50),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(driver.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 2),
            Row(children: [
              if (vehicle != null) ...[
                Icon(vehicle.type.icon, size: 15, color: vehicle.type.color),
                const SizedBox(width: 4),
                Flexible(child: Text(vehicle.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 13))),
              ] else
                Text(driver.active ? s.noVehicleAssigned : s.inactive, style: TextStyle(color: p.muted, fontSize: 13)),
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          Text(s.due, style: TextStyle(color: p.muted, fontSize: 11.5)),
          Text(
            due > 0 ? f.money(due) : (due < 0 ? '+${f.money(-due)}' : '—'),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: due > 0 ? p.expense : p.income),
          ),
        ]),
        if (driver.phone?.isNotEmpty ?? false) ...[
          const SizedBox(width: 6),
          IconButton(
            tooltip: s.call,
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: driver.phone)),
            icon: Icon(Icons.call_rounded, color: p.income),
          ),
        ],
      ]),
    );
  }
}

class _DriverData {
  _DriverData(this.days, this.month, this.history);
  final Map<DateTime, DayRecord> days;
  final ({double paid, int days}) month;
  final List<LedgerEntry> history;
}

class DriverDetailScreen extends StatelessWidget {
  const DriverDetailScreen({super.key, required this.driverId});
  final int driverId;

  Future<_DriverData> _load(Repository r) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final from = today.subtract(const Duration(days: 59));
    final res = await Future.wait([
      r.driverDays(driverId, Period(from, today)),
      r.driverTotals(driverId, Period.thisMonth()),
      r.ledger(driverId: driverId, limit: 40),
    ]);
    return _DriverData(res[0] as Map<DateTime, DayRecord>, res[1] as ({double paid, int days}), res[2] as List<LedgerEntry>);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final d = app.driver(driverId);
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    if (d == null) return const Scaffold();
    final due = app.dues[driverId] ?? 0;
    final vehicle = app.vehicleOfDriver(driverId);
    final today = DateUtils.dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(s.driver),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.of(context).push(AppRoute(builder: (_) => DriverFormScreen(driver: d))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Loader<_DriverData>(
        load: _load,
        deps: [driverId],
        builder: (context, data) {
          return Contained(
            maxWidth: 820,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: [
                Entrance(
                  child: Panel(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Row(children: [
                        Avatar(name: d.name, initials: d.initials, size: 64),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d.name, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                            if (d.phone?.isNotEmpty ?? false) Text(f.digits(d.phone!), style: TextStyle(color: p.muted)),
                            if (vehicle != null) ...[
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => VehicleDetailScreen(vehicleId: vehicle.id!))),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(vehicle.type.icon, size: 16, color: vehicle.type.color),
                                  const SizedBox(width: 6),
                                  Text('${s.drivesVehicle}: ${vehicle.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ]),
                              ),
                            ],
                          ]),
                        ),
                        if (d.phone?.isNotEmpty ?? false)
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: p.income, foregroundColor: Colors.white),
                            onPressed: () => launchUrl(Uri(scheme: 'tel', path: d.phone)),
                            icon: const Icon(Icons.call_rounded),
                          ),
                      ]),
                      if ((d.licenseNo?.isNotEmpty ?? false) || d.licenseExpiry != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            Icon(Icons.badge_outlined, color: p.muted, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                [
                                  if (d.licenseNo?.isNotEmpty ?? false) '${s.licenseNo}: ${d.licenseNo}',
                                  if (d.licenseExpiry != null) '${s.licenseExpiry}: ${f.date(d.licenseExpiry!)}',
                                ].join(' · '),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            if (d.licenseDaysLeft != null)
                              StatusPill(
                                s.expiresIn(d.licenseDaysLeft!),
                                d.licenseDaysLeft! < 0 ? p.expense : (d.licenseDaysLeft! <= 30 ? p.warning : p.income),
                              ),
                          ]),
                        ),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Entrance(
                  index: 1,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: due > 0 ? p.hero : p.accent, borderRadius: BorderRadius.circular(kRadius)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(due > 0 ? s.currentDue : (due < 0 ? s.advanceBalance : s.noDue),
                              style: TextStyle(color: (due > 0 ? p.onHero : p.onAccent).withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(f.money(due.abs()),
                              style: TextStyle(color: due > 0 ? p.expense : p.onAccent, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1)),
                        ]),
                      ),
                      if (due > 0)
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent),
                          onPressed: () => openEntry(context, EntryMode.due, driverId: driverId, vehicleId: vehicle?.id),
                          child: Text(s.collectDue),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: StatBlock(label: s.totalGiven, value: f.money(data.month.paid), color: p.income, icon: Icons.payments_rounded, sub: s.thisMonth)),
                  const SizedBox(width: 12),
                  Expanded(child: StatBlock(label: s.workingDays, value: f.digits(data.month.days), icon: Icons.event_available_rounded, sub: s.thisMonth)),
                ]),
                SectionHeader(s.last60Days),
                Panel(child: CollectionHeatmap(days: data.days, from: today.subtract(const Duration(days: 59)), to: today)),
                SectionHeader(s.history),
                Panel(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: data.history.isEmpty
                      ? EmptyState(icon: Icons.receipt_long_rounded, title: s.noEntries)
                      : Column(children: groupedLedger(data.history)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DriverFormScreen extends StatefulWidget {
  const DriverFormScreen({super.key, this.driver});
  final Driver? driver;

  @override
  State<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends State<DriverFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.driver?.name);
  late final _phone = TextEditingController(text: widget.driver?.phone);
  late final _nid = TextEditingController(text: widget.driver?.nid);
  late final _license = TextEditingController(text: widget.driver?.licenseNo);
  late final _address = TextEditingController(text: widget.driver?.address);
  late final _due = TextEditingController(
      text: widget.driver == null || widget.driver!.openingDue == 0 ? '' : widget.driver!.openingDue.round().toString());
  late DateTime? _join = widget.driver?.joinDate ?? DateUtils.dateOnly(DateTime.now());
  late DateTime? _licenseExpiry = widget.driver?.licenseExpiry;
  late bool _active = widget.driver?.active ?? true;

  @override
  void dispose() {
    for (final c in [_name, _phone, _nid, _license, _address, _due]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (widget.driver == null && !await requireDriverSlot(context, context.read<AppState>().drivers.length)) return;
    if (!mounted) return;
    final s = context.s;
    final d = Driver(
      id: widget.driver?.id,
      name: _name.text,
      phone: _t(_phone),
      nid: _t(_nid),
      licenseNo: _t(_license),
      address: _t(_address),
      joinDate: _join,
      openingDue: parseAmount(_due.text) ?? 0,
      active: _active,
      note: widget.driver?.note,
      licenseExpiry: _licenseExpiry,
    );
    final id = await context.read<AppState>().mutate((r) => r.saveDriver(d));
    if (!mounted) return;
    toast(context, s.saved);
    Navigator.pop(context, id);
  }

  Future<void> _delete() async {
    final s = context.s;
    if (!await confirm(context, title: s.confirmDelete, body: s.deleteDriverWarn)) return;
    if (!mounted) return;
    await context.read<AppState>().mutate((r) => r.deleteDriver(widget.driver!.id!));
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.driver == null ? s.addDriver : s.editDriver),
        actions: [
          if (widget.driver != null) IconButton(onPressed: _delete, icon: Icon(Icons.delete_outline_rounded, color: p.expense)),
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
              Center(
                child: ValueListenableBuilder(
                  valueListenable: _name,
                  builder: (_, v, _) {
                    final tmp = Driver(name: v.text.isEmpty ? '?' : v.text);
                    return Avatar(name: tmp.name, initials: tmp.initials, size: 84);
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: s.driverName, prefixIcon: const Icon(Icons.person_outline_rounded)),
                validator: (v) => (v == null || v.trim().isEmpty) ? s.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: s.phone, hintText: '01XXXXXXXXX', prefixIcon: const Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _nid, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: s.nid, prefixIcon: const Icon(Icons.credit_card_outlined)))),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _license, decoration: InputDecoration(labelText: s.licenseNo, prefixIcon: const Icon(Icons.badge_outlined)))),
              ]),
              const SizedBox(height: 12),
              DateFormField(label: s.licenseExpiry, value: _licenseExpiry, onPick: (d) => setState(() => _licenseExpiry = d)),
              const SizedBox(height: 12),
              TextFormField(controller: _address, maxLines: 2, decoration: InputDecoration(labelText: s.address, prefixIcon: const Icon(Icons.home_outlined))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: DateFormField(label: s.joinDate, value: _join, onPick: (d) => setState(() => _join = d))),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _due,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.openingDue, prefixText: '৳ ', prefixIcon: const Icon(Icons.account_balance_wallet_outlined)),
                    validator: (v) => v != null && v.trim().isNotEmpty && parseAmount(v) == null ? s.invalidNumber : null,
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.active, style: const TextStyle(fontWeight: FontWeight.w600)),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Contained(
          maxWidth: 640,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(width: double.infinity, child: FilledButton(onPressed: _save, child: Text(s.save))),
          ),
        ),
      ),
    );
  }
}
