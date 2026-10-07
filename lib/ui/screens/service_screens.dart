import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'maintenance_screen.dart';
import 'vehicle_screens.dart';
import '../routes.dart';
import '../../services/access.dart';
import '../widgets/access_gate.dart';

Future<void> openVisitForm(BuildContext context, {int? vehicleId}) async {
  if (!await requireFeature(context, Feature.serviceVisits) || !context.mounted) return;
  await Navigator.of(context).push(AppRoute(
    fullscreenDialog: true,
    builder: (_) => VisitFormScreen(vehicleId: vehicleId),
  ));
}

Future<void> openVisit(BuildContext context, int visitId) =>
    Navigator.of(context).push(AppRoute(builder: (_) => VisitDetailScreen(visitId: visitId)));

/// "Garage visit or a single part?" — the + on the parts screen.
Future<void> showMaintenanceAdd(BuildContext context, {int? vehicleId}) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) {
      final s = ctx.s;
      final p = ctx.pal;
      Widget option(IconData icon, Color color, String title, String sub, VoidCallback onTap) => Panel(
            onTap: () {
              Navigator.pop(ctx);
              onTap();
            },
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              IconBubble(icon, color, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(sub, style: TextStyle(color: p.muted, fontSize: 13)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: p.muted),
            ]),
          );
      return SafeArea(
        child: Contained(
          maxWidth: 560,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 14), child: Text(s.whatToAdd, style: ctx.text.titleLarge)),
              option(Icons.garage_rounded, ExpenseCategory.servicing.color, s.visit, s.visitQuickSub, () => openVisitForm(context, vehicleId: vehicleId)),
              const SizedBox(height: 10),
              option(PartType.engineOil.icon, PartType.engineOil.color, s.singlePart, s.singlePartSub, () => openPartForm(context, vehicleId: vehicleId)),
            ]),
          ),
        ),
      );
    },
  );
}

// ── List pieces ───────────────────────────────────────────────────────────

/// One garage visit in a list: date, where, what and the bill.
class VisitTile extends StatelessWidget {
  const VisitTile({super.key, required this.summary, this.showVehicle = true});
  final VisitSummary summary;
  final bool showVehicle;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final v = summary.visit;
    final title = v.title?.isNotEmpty == true ? v.title! : (v.workshop?.isNotEmpty == true ? v.workshop! : v.kind.shortLabel(s));
    final sub = [
      if (showVehicle) app.vehicle(v.vehicleId)?.name ?? '',
      if (v.workshop?.isNotEmpty == true && title != v.workshop) v.workshop!,
      if (summary.partsCount > 0) '${f.digits(summary.partsCount)} ${s.partsShort}',
      if (v.odometer != null) '${f.number(v.odometer!)} ${s.km}',
    ].join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openVisit(context, v.id!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: v.kind.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text(f.digits(v.date.day), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: v.kind.color, height: 1.1)),
              Text(f.monthShort(v.date.month), style: TextStyle(fontSize: 11, color: v.kind.color, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(v.kind.icon, size: 15, color: v.kind.color),
                const SizedBox(width: 5),
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
            ]),
          ),
          const SizedBox(width: 8),
          Text(f.money(summary.total), style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

/// A vehicle's next general service with how close it is.
class ServiceDueTile extends StatelessWidget {
  const ServiceDueTile({super.key, required this.status, this.showVehicle = true});
  final ServiceStatus status;
  final bool showVehicle;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final v = status.visit;
    final sub = [
      '${s.nextService}: ${[if (v.nextDate != null) f.date(v.nextDate!), if (v.nextKm != null) '${f.number(v.nextKm!)} ${s.km}'].join(' ${s.or} ')}',
    ].join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openVisit(context, v.id!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          IconBubble(Icons.event_repeat_rounded, v.kind.color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(showVehicle ? '${app.vehicle(v.vehicleId)?.name ?? ''} · ${s.serviceDue}' : s.nextService,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
            ]),
          ),
          const SizedBox(width: 8),
          StatusPill(dueLabel(status, s, f), dueColor(status.health, p)),
        ]),
      ),
    );
  }
}

// ── Detail ────────────────────────────────────────────────────────────────

class VisitDetailScreen extends StatelessWidget {
  const VisitDetailScreen({super.key, required this.visitId});
  final int visitId;

  Future<void> _delete(BuildContext context) async {
    final s = context.s;
    if (!await confirm(context, title: s.deleteVisit, body: s.deleteVisitBody)) return;
    if (!context.mounted) return;
    final nav = Navigator.of(context);
    await context.read<AppState>().mutate((r) => r.deleteVisit(visitId));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Loader<(ServiceVisit?, List<Part>, Map<int, double>)>(
      deps: [visitId],
      load: (r) async => (await r.visit(visitId), await r.visitParts(visitId), await r.odometers()),
      placeholder: const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2.4))),
      builder: (context, d) {
        final (visit, parts, odometers) = d;
        if (visit == null) return const Scaffold();
        final s = context.s;
        final f = context.fmt;
        final p = context.pal;
        final app = context.watch<AppState>();
        final vehicle = app.vehicle(visit.vehicleId);
        final partsCost = parts.fold<double>(0, (a, x) => a + x.cost);
        final wide = MediaQuery.sizeOf(context).width >= 900;
        final next = ServiceStatus(visit, currentKm: odometers[visit.vehicleId]);
        const white = Colors.white;
        final dim = white.withValues(alpha: 0.72);

        Widget infoRow(IconData icon, String text) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                Icon(icon, size: 17, color: dim),
                const SizedBox(width: 8),
                Expanded(child: Text(text, style: const TextStyle(color: white, fontWeight: FontWeight.w600))),
              ]),
            );

        final hero = Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [visit.kind.color, Color.lerp(visit.kind.color, Colors.black, 0.5)!],
            ),
          ),
          child: Stack(children: [
            Positioned(right: -30, bottom: -40, child: Icon(visit.kind.icon, size: 200, color: white.withValues(alpha: 0.12))),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _pill(visit.kind.label(s), icon: visit.kind.icon),
                  _pill(f.date(visit.date)),
                ]),
                const SizedBox(height: 16),
                Text(visit.title?.isNotEmpty == true ? visit.title! : s.visit,
                    style: const TextStyle(color: white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15)),
                if (visit.workshop?.isNotEmpty ?? false) infoRow(Icons.store_rounded, visit.workshop!),
                if (visit.mechanic?.isNotEmpty ?? false) infoRow(Icons.engineering_rounded, visit.mechanic!),
                if (visit.jobNo?.isNotEmpty ?? false) infoRow(Icons.confirmation_number_outlined, '${s.jobNo}: ${visit.jobNo}'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    Icon(vehicle?.type.icon ?? Icons.directions_car_rounded, color: white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: vehicle == null ? null : () => Navigator.of(context).push(AppRoute(builder: (_) => VehicleDetailScreen(vehicleId: vehicle.id!))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(vehicle?.name ?? '', style: const TextStyle(color: white, fontWeight: FontWeight.w700)),
                          if (visit.odometer != null) Text('${f.number(visit.odometer!)} ${s.km}', style: TextStyle(color: dim, fontSize: 12.5)),
                        ]),
                      ),
                    ),
                    if (vehicle?.regNo?.isNotEmpty ?? false) NumberPlate(regNo: vehicle!.regNo),
                  ]),
                ),
              ]),
            ),
          ]),
        );

        final stats = Column(children: [
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: StatBlock(label: s.labour, value: f.money(visit.labour), icon: Icons.engineering_rounded, color: ExpenseCategory.servicing.color)),
              const SizedBox(width: 12),
              Expanded(
                child: StatBlock(label: s.partsCost, value: f.money(partsCost), icon: Icons.settings_rounded, color: ExpenseCategory.parts.color, sub: '${f.digits(parts.length)} ${s.partsShort}'),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(kRadius)),
            child: Row(children: [
              Expanded(child: Text(s.visitTotal, style: TextStyle(color: p.onHero.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
              Text(f.money(visit.labour + partsCost), style: TextStyle(color: p.accent, fontSize: 26, fontWeight: FontWeight.w800)),
            ]),
          ),
          if (visit.nextDate != null || visit.nextKm != null) ...[
            const SizedBox(height: 12),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(children: [
                Icon(Icons.event_repeat_rounded, color: visit.kind.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.nextService, style: TextStyle(color: p.muted, fontSize: 12)),
                    Text(
                      [if (visit.nextDate != null) f.date(visit.nextDate!), if (visit.nextKm != null) '${f.number(visit.nextKm!)} ${s.km}'].join(' ${s.or} '),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
                StatusPill(dueLabel(next, s, f), dueColor(next.health, p)),
                const SizedBox(width: 4),
              ]),
            ),
          ],
        ]);

        final partsPanel = Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(s.partsFitted, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text(f.money(partsCost), style: TextStyle(fontWeight: FontWeight.w800, color: p.expense)),
            ]),
            const SizedBox(height: 6),
            if (parts.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(s.noPartsInVisit, style: TextStyle(color: p.muted)))
            else
              for (final part in parts) _PartLine(part: part, currentKm: odometers[visit.vehicleId]),
          ]),
        );

        final note = visit.note?.isNotEmpty ?? false
            ? Panel(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.edit_note_rounded, color: p.muted),
                  const SizedBox(width: 10),
                  Expanded(child: Text(visit.note!)),
                ]),
              )
            : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(s.visit),
            actions: [
              IconButton(
                tooltip: s.edit,
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => Navigator.of(context).push(AppRoute(builder: (_) => VisitFormScreen(visit: visit, parts: parts))),
              ),
              IconButton(tooltip: s.delete, icon: Icon(Icons.delete_outline_rounded, color: p.expense), onPressed: () => _delete(context)),
              const SizedBox(width: 8),
            ],
          ),
          body: Contained(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: wide
                  ? [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: Column(children: [hero, const SizedBox(height: 14), stats])),
                        const SizedBox(width: 16),
                        Expanded(child: Column(children: [partsPanel, if (note != null) ...[const SizedBox(height: 14), note]])),
                      ]),
                    ]
                  : [
                      Entrance(child: hero),
                      const SizedBox(height: 14),
                      Entrance(index: 1, child: stats),
                      const SizedBox(height: 14),
                      Entrance(index: 2, child: partsPanel),
                      if (note != null) ...[const SizedBox(height: 14), note],
                    ],
            ),
          ),
        );
      },
    );
  }

  static Widget _pill(String text, {IconData? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 5)],
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      );
}

/// A part on a job card: price, shop, warranty and when to change it next.
class _PartLine extends StatelessWidget {
  const _PartLine({required this.part, this.currentKm});
  final Part part;
  final double? currentKm;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final status = PartStatus(part, currentKm: currentKm);
    final w = part.warrantyDaysLeft;
    final line1 = [
      if (part.subLabel != null) part.subLabel!,
      if (part.qty != 1) '${f.number(part.qty, decimals: 1)} × ${f.money(part.unitPrice)}',
      if (part.shop?.isNotEmpty ?? false) part.shop!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconBubble(part.type.icon, part.type.color, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(part.label(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(f.money(part.cost), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            if (line1.isNotEmpty) Text(line1, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (status.health != DueHealth.unscheduled) StatusPill(dueLabel(status, s, f), dueColor(status.health, p), icon: Icons.event_repeat_rounded),
              if (w != null) StatusPill(s.warrantyLeft(w), w < 0 ? p.muted : p.info, icon: Icons.verified_user_outlined),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ── Form ──────────────────────────────────────────────────────────────────

/// A part being added to a job card; dates and km come from the visit on save.
class _PartDraft {
  _PartDraft({required this.type, this.detail, this.qty = 1, this.cost = 0, this.shop, this.warrantyUntil, this.everyKm, this.everyMonths, this.note});
  final PartType type;
  final String? detail;
  final double qty;
  final double cost;
  final String? shop;
  final DateTime? warrantyUntil;
  final double? everyKm;
  final int? everyMonths;
  final String? note;

  factory _PartDraft.fromPart(Part p) => _PartDraft(
        type: p.type,
        detail: p.detail,
        qty: p.qty,
        cost: p.cost,
        shop: p.shop,
        warrantyUntil: p.warrantyUntil,
        everyKm: p.nextKm != null && p.installedKm != null ? p.nextKm! - p.installedKm! : null,
        everyMonths: p.nextDate == null ? null : (p.nextDate!.year - p.installedDate.year) * 12 + p.nextDate!.month - p.installedDate.month,
        note: p.note,
      );

  Part toPart({required int vehicleId, required DateTime date, double? km}) => Part(
        vehicleId: vehicleId,
        type: type,
        detail: detail,
        installedDate: date,
        installedKm: km,
        cost: cost,
        qty: qty,
        shop: shop,
        warrantyUntil: warrantyUntil,
        nextDate: everyMonths == null || everyMonths! <= 0 ? null : DateTime(date.year, date.month + everyMonths!, date.day),
        nextKm: km == null || everyKm == null || everyKm! <= 0 ? null : km + everyKm!,
        note: note,
      );
}

class VisitFormScreen extends StatefulWidget {
  const VisitFormScreen({super.key, this.visit, this.parts = const [], this.vehicleId});
  final ServiceVisit? visit;
  final List<Part> parts;
  final int? vehicleId;

  @override
  State<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends State<VisitFormScreen> {
  final _form = GlobalKey<FormState>();
  late int? _vehicleId = widget.visit?.vehicleId ?? widget.vehicleId;
  late ServiceKind _kind = widget.visit?.kind ?? ServiceKind.local;
  late DateTime _date = widget.visit?.date ?? DateUtils.dateOnly(DateTime.now());
  late final _km = TextEditingController(text: _num(widget.visit?.odometer));
  late final _workshop = TextEditingController(text: widget.visit?.workshop);
  late final _mechanic = TextEditingController(text: widget.visit?.mechanic);
  late final _jobNo = TextEditingController(text: widget.visit?.jobNo);
  late final _title = TextEditingController(text: widget.visit?.title);
  late final _labour = TextEditingController(text: _num(widget.visit?.labour));
  late final _everyKm = TextEditingController();
  late final _everyMonths = TextEditingController();
  late final _note = TextEditingController(text: widget.visit?.note);
  late final List<_PartDraft> _parts = [for (final p in widget.parts) _PartDraft.fromPart(p)];
  Map<int, double> _odometers = {};
  List<String> _workshops = [];
  List<String> _shops = [];
  bool _saving = false;

  static String _num(double? v) => v == null || v == 0 ? '' : (v == v.roundToDouble() ? v.round().toString() : v.toString());

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final v = widget.visit;
    if (v == null) {
      _vehicleId ??= app.activeVehicles.isNotEmpty ? app.activeVehicles.first.id : (app.vehicles.isNotEmpty ? app.vehicles.first.id : null);
      _applyScheduleDefaults();
    } else {
      if (v.nextKm != null && v.odometer != null) _everyKm.text = _num(v.nextKm! - v.odometer!);
      if (v.nextDate != null) {
        final m = (v.nextDate!.year - v.date.year) * 12 + v.nextDate!.month - v.date.month;
        if (m > 0) _everyMonths.text = '$m';
      }
    }
    Future.wait([app.repo.odometers(), app.repo.suggestions('service_visits', 'workshop'), app.repo.suggestions('parts', 'shop')]).then((res) {
      if (!mounted) return;
      setState(() {
        _odometers = res[0] as Map<int, double>;
        _workshops = res[1] as List<String>;
        _shops = res[2] as List<String>;
        if (widget.visit == null && _km.text.isEmpty) _km.text = _num(_odometers[_vehicleId]);
      });
    });
  }

  void _applyScheduleDefaults() {
    final type = context.read<AppState>().vehicle(_vehicleId)?.type;
    if (type == null) return;
    _everyKm.text = '${type.serviceKm}';
    _everyMonths.text = '${type.serviceMonths}';
  }

  @override
  void dispose() {
    for (final c in [_km, _workshop, _mechanic, _jobNo, _title, _labour, _everyKm, _everyMonths, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _labourValue => parseAmount(_labour.text) ?? 0;
  double get _partsTotal => _parts.fold(0, (a, p) => a + p.cost);

  DateTime? get _nextDate {
    final m = parseAmount(_everyMonths.text)?.round();
    return m == null || m <= 0 ? null : DateTime(_date.year, _date.month + m, _date.day);
  }

  double? get _nextKm {
    final km = parseAmount(_km.text), every = parseAmount(_everyKm.text);
    return km == null || every == null || every <= 0 ? null : km + every;
  }

  Future<void> _editPart({int? index, PartType? type}) async {
    final draft = await showModalBottomSheet<_PartDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PartSheet(draft: index == null ? null : _parts[index], type: type, shops: _shops),
    );
    if (draft == null) return;
    setState(() => index == null ? _parts.add(draft) : _parts[index] = draft);
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
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final km = parseAmount(_km.text);
    final visit = ServiceVisit(
      id: widget.visit?.id,
      vehicleId: _vehicleId!,
      date: _date,
      odometer: km,
      kind: _kind,
      workshop: text(_workshop),
      mechanic: text(_mechanic),
      jobNo: text(_jobNo),
      title: text(_title),
      labour: _labourValue,
      nextDate: _nextDate,
      nextKm: _nextKm,
      note: text(_note),
    );
    final parts = [for (final d in _parts) d.toPart(vehicleId: _vehicleId!, date: _date, km: km)];
    try {
      await app.mutate((r) => r.saveVisit(visit, parts));
      if (!mounted) return;
      toast(context, s.visitSaved);
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
    final app = context.watch<AppState>();
    String? numValidator(String? v) => v != null && v.trim().isNotEmpty && parseAmount(v) == null ? s.invalidNumber : null;
    final nextDate = _nextDate, nextKm = _nextKm;
    final total = _labourValue + _partsTotal;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        title: Text(widget.visit == null ? s.newVisit : s.editVisit),
      ),
      body: Form(
        key: _form,
        child: Contained(
          maxWidth: 680,
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
                        if (widget.visit == null) {
                          if (wasAuto) _km.text = _num(_odometers[v.id]);
                          _applyScheduleDefaults();
                        }
                      }),
                    ),
                ]),
              const SizedBox(height: 20),
              _label(s.whereServiced),
              PillToggle<ServiceKind>(values: ServiceKind.values, selected: _kind, label: (k) => k.shortLabel(s), onChanged: (k) => setState(() => _kind = k)),
              const SizedBox(height: 14),
              SuggestField(controller: _workshop, suggestions: _workshops, label: s.workshop, hint: s.workshopHint, icon: Icons.store_rounded),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: DateFormField(label: s.date, value: _date, onPick: (d) => setState(() => _date = d))),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _km,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: s.odometer, prefixIcon: const Icon(Icons.speed_rounded)),
                    validator: numValidator,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: InputDecoration(labelText: s.workDone, hintText: s.workDoneHint, prefixIcon: const Icon(Icons.handyman_outlined)),
              ),
              const SizedBox(height: 12),
              FieldPair(
                TextFormField(controller: _mechanic, decoration: InputDecoration(labelText: s.mechanic, prefixIcon: const Icon(Icons.engineering_outlined))),
                TextFormField(controller: _jobNo, decoration: InputDecoration(labelText: s.jobNo, prefixIcon: const Icon(Icons.confirmation_number_outlined))),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _labour,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: s.labour, prefixText: '৳ ', prefixIcon: const Icon(Icons.payments_outlined)),
                validator: numValidator,
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _label(s.partsFitted)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, right: 4),
                  child: Text(f.money(_partsTotal), style: TextStyle(color: p.expense, fontWeight: FontWeight.w800)),
                ),
              ]),
              Panel(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                child: _parts.isEmpty
                    ? Padding(padding: const EdgeInsets.fromLTRB(4, 8, 8, 8), child: Text(s.noPartsInVisit, style: TextStyle(color: p.muted)))
                    : Column(children: [
                        for (var i = 0; i < _parts.length; i++)
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _editPart(index: i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(children: [
                                IconBubble(_parts[i].type.icon, _parts[i].type.color, size: 38),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(_parts[i].type == PartType.other && (_parts[i].detail?.isNotEmpty ?? false) ? _parts[i].detail! : _parts[i].type.label(s),
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(
                                      [
                                        if (_parts[i].type != PartType.other && (_parts[i].detail?.isNotEmpty ?? false)) _parts[i].detail!,
                                        if (_parts[i].qty != 1) '× ${f.number(_parts[i].qty, decimals: 1)}',
                                        if (_parts[i].shop?.isNotEmpty ?? false) _parts[i].shop!,
                                      ].join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: p.muted, fontSize: 12.5),
                                    ),
                                  ]),
                                ),
                                Text(f.money(_parts[i].cost), style: const TextStyle(fontWeight: FontWeight.w700)),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => setState(() => _parts.removeAt(i)),
                                  icon: Icon(Icons.close_rounded, size: 18, color: p.muted),
                                ),
                              ]),
                            ),
                          ),
                      ]),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in const [PartType.engineOil, PartType.oilFilter, PartType.airFilter, PartType.brakePad, PartType.sparkPlug])
                  ChoiceTag(label: '+ ${t.label(s)}', icon: t.icon, color: t.color, selected: false, onTap: () => _editPart(type: t)),
                ChoiceTag(label: s.addPart, icon: Icons.add_rounded, selected: false, onTap: () => _editPart()),
              ]),
              const SizedBox(height: 24),
              _label(s.nextService),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: _everyKm,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: s.serviceAfterKm, suffixText: s.km, isDense: true),
                    validator: numValidator,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _everyMonths,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: s.serviceAfterMonths, suffixText: s.months, isDense: true),
                    validator: numValidator,
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _kind.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Icon(Icons.event_repeat_rounded, color: _kind.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: nextDate == null && nextKm == null
                        ? Text(s.noSchedule, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600))
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.nextService, style: TextStyle(color: p.muted, fontSize: 12)),
                            Text([if (nextDate != null) f.date(nextDate), if (nextKm != null) '${f.number(nextKm)} ${s.km}'].join(' ${s.or} '),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.line))),
        child: SafeArea(
          child: Contained(
            maxWidth: 680,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(children: [
                Expanded(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${s.labourShort} ${f.money(_labourValue)} + ${s.partsCost} ${f.money(_partsTotal)}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('${s.visitTotal} ${f.money(total)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(140, 52)),
                  onPressed: _saving ? null : _save,
                  child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4)) : Text(s.save),
                ),
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
}

/// Bottom sheet for one part on a job card.
class _PartSheet extends StatefulWidget {
  const _PartSheet({this.draft, this.type, required this.shops});
  final _PartDraft? draft;
  final PartType? type;
  final List<String> shops;

  @override
  State<_PartSheet> createState() => _PartSheetState();
}

class _PartSheetState extends State<_PartSheet> {
  late PartType _type = widget.draft?.type ?? widget.type ?? PartType.engineOil;
  late final _detail = TextEditingController(text: widget.draft?.detail);
  late final _qty = TextEditingController(text: widget.draft == null || widget.draft!.qty == 1 ? '1' : _trim(widget.draft!.qty));
  late final _cost = TextEditingController(text: widget.draft == null || widget.draft!.cost == 0 ? '' : _trim(widget.draft!.cost));
  late final _shop = TextEditingController(text: widget.draft?.shop);
  late final _everyKm = TextEditingController(text: widget.draft == null ? (_type.km?.toString() ?? '') : (widget.draft!.everyKm == null ? '' : _trim(widget.draft!.everyKm!)));
  late final _everyMonths =
      TextEditingController(text: widget.draft == null ? (_type.months?.toString() ?? '') : (widget.draft!.everyMonths?.toString() ?? ''));
  late DateTime? _warranty = widget.draft?.warrantyUntil;
  String? _error;

  static String _trim(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  void dispose() {
    for (final c in [_detail, _qty, _cost, _shop, _everyKm, _everyMonths]) {
      c.dispose();
    }
    super.dispose();
  }

  void _done() {
    final s = context.s;
    if (_type == PartType.other && _detail.text.trim().isEmpty) {
      setState(() => _error = s.partName);
      return;
    }
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    Navigator.pop(
      context,
      _PartDraft(
        type: _type,
        detail: text(_detail),
        qty: parseAmount(_qty.text) ?? 1,
        cost: parseAmount(_cost.text) ?? 0,
        shop: text(_shop),
        warrantyUntil: _warranty,
        everyKm: parseAmount(_everyKm.text),
        everyMonths: parseAmount(_everyMonths.text)?.round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final qty = parseAmount(_qty.text) ?? 1, cost = parseAmount(_cost.text) ?? 0;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Contained(
          maxWidth: 600,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.draft == null ? s.addPart : s.editPart, style: context.text.titleLarge),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in PartType.values)
                  ChoiceTag(
                    label: t.label(s),
                    icon: t.icon,
                    color: t.color,
                    selected: t == _type,
                    onTap: () => setState(() {
                      _type = t;
                      _everyKm.text = t.km?.toString() ?? '';
                      _everyMonths.text = t.months?.toString() ?? '';
                    }),
                  ),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: _detail,
                onChanged: (_) => _error == null ? null : setState(() => _error = null),
                decoration: InputDecoration(
                  labelText: _type == PartType.other ? s.partName : s.partDetail,
                  hintText: _type == PartType.other ? null : s.partDetailHint,
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                  errorText: _error == null ? null : s.required,
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _qty,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: s.qty),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cost,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: s.priceTotal,
                      prefixText: '৳ ',
                      helperText: qty > 1 && cost > 0 ? '${f.money(cost / qty)} ${s.each}' : null,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              SuggestField(controller: _shop, suggestions: widget.shops, label: s.shop, hint: s.shopHint, icon: Icons.storefront_outlined),
              const SizedBox(height: 10),
              WarrantyField(value: _warranty, onChanged: (d) => setState(() => _warranty = d)),
              const SizedBox(height: 14),
              Text(s.nextChange, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _everyKm,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.changeAfterKm, suffixText: s.km, isDense: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _everyMonths,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.changeAfterMonths, suffixText: s.months, isDense: true),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent),
                  onPressed: _done,
                  child: Text(s.done),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Optional warranty end date with a clear button.
class WarrantyField extends StatelessWidget {
  const WarrantyField({super.key, required this.value, required this.onChanged});
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final d = await pickDate(context, value ?? DateTime.now().add(const Duration(days: 180)));
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: s.warrantyUntil,
          prefixIcon: const Icon(Icons.verified_user_outlined),
          suffixIcon: value == null ? null : IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => onChanged(null)),
        ),
        isEmpty: value == null,
        child: Text(value == null ? '' : context.fmt.date(value!), maxLines: 1),
      ),
    );
  }
}
