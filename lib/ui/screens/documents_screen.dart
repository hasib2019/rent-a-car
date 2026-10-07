import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'vehicle_screens.dart';
import '../../services/access.dart';
import '../widgets/access_gate.dart';

/// All paper expiry dates across the fleet, soonest first.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(s.documentsReminders)),
      floatingActionButton: app.vehicles.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: context.pal.accent,
              foregroundColor: context.pal.onAccent,
              onPressed: () => showPaperSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(s.addPaper, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
      body: Loader<List<Paper>>(
        load: (r) => r.papers(),
        builder: (context, papers) {
          if (papers.isEmpty) {
            return EmptyState(icon: Icons.description_rounded, title: s.noPapers);
          }
          return Contained(
            maxWidth: 720,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: papers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => Entrance(index: i, child: Panel(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: PaperTile(paper: papers[i]))),
            ),
          );
        },
      ),
    );
  }
}

class PaperTile extends StatelessWidget {
  const PaperTile({super.key, required this.paper, this.showVehicle = true});
  final Paper paper;
  final bool showVehicle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final app = context.watch<AppState>();
    final days = paper.daysLeft;
    final color = days < 0 ? p.expense : (days <= 30 ? p.warning : p.income);
    final v = app.vehicle(paper.vehicleId);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showPaperSheet(context, paper: paper),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text(f.digits(paper.expiry.day), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color, height: 1.1)),
              Text(f.monthShort(paper.expiry.month), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(paper.type.label(s), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(
                [
                  if (showVehicle && v != null) v.name,
                  f.date(paper.expiry),
                  if (paper.docNo?.isNotEmpty ?? false) paper.docNo!,
                  if (paper.provider?.isNotEmpty ?? false) paper.provider!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.muted, fontSize: 12.5),
              ),
            ]),
          ),
          StatusPill(s.expiresIn(days), color),
        ]),
      ),
    );
  }
}

Future<void> showPaperSheet(BuildContext context, {Paper? paper, int? vehicleId}) async {
  if (!await requireFeature(context, Feature.papers) || !context.mounted) return;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PaperSheet(paper: paper, vehicleId: vehicleId),
  );
}

class _PaperSheet extends StatefulWidget {
  const _PaperSheet({this.paper, this.vehicleId});
  final Paper? paper;
  final int? vehicleId;

  @override
  State<_PaperSheet> createState() => _PaperSheetState();
}

class _PaperSheetState extends State<_PaperSheet> {
  late PaperType _type = widget.paper?.type ?? PaperType.taxToken;
  late int? _vehicleId = widget.paper?.vehicleId ?? widget.vehicleId;
  late DateTime? _expiry = widget.paper?.expiry;
  late final _docNo = TextEditingController(text: widget.paper?.docNo);
  late final _provider = TextEditingController(text: widget.paper?.provider);

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _vehicleId ??= app.vehicles.isEmpty ? null : app.vehicles.first.id;
  }

  @override
  void dispose() {
    _docNo.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_vehicleId == null || _expiry == null) return;
    final app = context.read<AppState>();
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    await app.mutate((r) => r.savePaper(Paper(
          id: widget.paper?.id,
          vehicleId: _vehicleId!,
          type: _type,
          expiry: _expiry!,
          note: widget.paper?.note,
          docNo: text(_docNo),
          provider: text(_provider),
        )));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    final app = context.watch<AppState>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Contained(
          maxWidth: 560,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.paper == null ? s.addPaper : s.papers, style: context.text.titleLarge),
              const SizedBox(height: 16),
              if (widget.vehicleId == null) ...[
                Text(s.selectVehicle, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final v in app.vehicles)
                    ChoiceTag(label: v.name, icon: v.type.icon, color: v.type.color, selected: _vehicleId == v.id, onTap: () => setState(() => _vehicleId = v.id)),
                ]),
                const SizedBox(height: 16),
              ],
              Text(s.paperType, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in PaperType.values) ChoiceTag(label: t.label(s), selected: _type == t, onTap: () => setState(() => _type = t)),
              ]),
              const SizedBox(height: 16),
              DateFormField(label: s.expiryDate, value: _expiry, onPick: (d) => setState(() => _expiry = d)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _docNo, decoration: InputDecoration(labelText: s.docNo, prefixIcon: const Icon(Icons.numbers_rounded)))),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _provider,
                    decoration: InputDecoration(labelText: s.provider, hintText: s.providerHint, prefixIcon: const Icon(Icons.apartment_rounded)),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                if (widget.paper != null) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: p.expense),
                    onPressed: () async {
                      final app = context.read<AppState>();
                      final nav = Navigator.of(context);
                      await app.mutate((r) => r.deletePaper(widget.paper!.id!));
                      nav.pop();
                    },
                    child: const Icon(Icons.delete_outline_rounded),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(child: FilledButton(onPressed: _vehicleId == null || _expiry == null ? null : _save, child: Text(s.save))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
