import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/l10n_personal.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/auth.dart';
import '../../services/settings.dart';
import '../../state/app_state.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// A4 in PDF points; pages are laid out at this size and printed edge to edge.
const _pageW = 595.0, _pageH = 842.0;
const _firstRows = 14, _moreRows = 22;

/// The month's office-work costs as a claim to hand to the employer: drawn
/// by Flutter (so Bangla shapes correctly), then rasterised into a PDF.
class OfficeReportScreen extends StatefulWidget {
  const OfficeReportScreen({super.key, this.vehicleId});
  final int? vehicleId;

  @override
  State<OfficeReportScreen> createState() => _OfficeReportScreenState();
}

class _OfficeReportScreenState extends State<OfficeReportScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late int? _vehicleId = widget.vehicleId;
  final List<GlobalKey> _pages = [];
  bool _busy = false;

  Future<void> _share(int pages) async {
    final s = S.read(context);
    setState(() => _busy = true);
    try {
      final doc = pw.Document(title: s.claimTitle, creator: 'GariKhata');
      for (final key in _pages.take(pages)) {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final picture = pw.MemoryImage(png!.buffer.asUint8List());
        doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero, build: (_) => pw.Image(picture, fit: pw.BoxFit.fill)));
      }
      final month = '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
      await Printing.sharePdf(bytes: await doc.save(), filename: 'office-claim-$month.pdf');
    } catch (e) {
      if (mounted) toast(context, s.somethingWrong(e), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(s.officeReport)),
      body: Loader<List<Expense>>(
        deps: [_month, _vehicleId],
        load: (r) => r.officeExpenses(Period.month(_month), vehicleId: _vehicleId),
        builder: (context, rows) {
          final chunks = <List<Expense>>[];
          for (var i = 0; i < rows.length; i += chunks.isEmpty ? _firstRows : _moreRows) {
            chunks.add(rows.sublist(i, (i + (chunks.isEmpty ? _firstRows : _moreRows)).clamp(0, rows.length)));
          }
          while (_pages.length < chunks.length) {
            _pages.add(GlobalKey());
          }
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(children: [MonthSwitcher(month: _month, onChanged: (m) => setState(() => _month = m))]),
            ),
            if (app.vehicles.length > 1)
              SizedBox(
                height: 58,
                child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 10, 16, 4), children: [
                  ChoiceTag(label: s.allCars, selected: _vehicleId == null, onTap: () => setState(() => _vehicleId = null)),
                  for (final v in app.vehicles) ...[
                    const SizedBox(width: 8),
                    ChoiceTag(label: v.name, icon: v.type.icon, color: v.type.color, selected: _vehicleId == v.id, onTap: () => setState(() => _vehicleId = v.id)),
                  ],
                ]),
              ),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: EmptyState(icon: Icons.work_outline_rounded, title: s.noOfficeCosts, body: s.noOfficeCostsBody),
                      ),
                    )
                  // Every page stays built and painted so it can be captured.
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      child: Contained(
                        maxWidth: 640,
                        child: Column(children: [
                          for (var i = 0; i < chunks.length; i++) ...[
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: FittedBox(
                                child: RepaintBoundary(
                                  key: _pages[i],
                                  child: _ClaimPage(
                                    rows: chunks[i],
                                    all: rows,
                                    page: i,
                                    pages: chunks.length,
                                    month: _month,
                                    vehicle: app.vehicle(_vehicleId),
                                    startIndex: i == 0 ? 0 : _firstRows + (i - 1) * _moreRows,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ]),
                      ),
                    ),
            ),
          ]);
        },
      ),
      floatingActionButton: Builder(builder: (context) {
        return FloatingActionButton.extended(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          onPressed: _busy ? null : () => _share(_pages.length),
          icon: _busy
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onAccent))
              : const Icon(Icons.picture_as_pdf_rounded),
          label: Text(_busy ? s.makingPdf : s.sharePdf),
        );
      }),
    );
  }
}

/// One A4 page: header on the first, rows, and the total with signatures on the last.
class _ClaimPage extends StatelessWidget {
  const _ClaimPage({required this.rows, required this.all, required this.page, required this.pages, required this.month, required this.startIndex, this.vehicle});
  final List<Expense> rows;
  final List<Expense> all;
  final int page;
  final int pages;
  final DateTime month;
  final int startIndex;
  final Vehicle? vehicle;

  static const _ink = Color(0xFF111418);
  static const _muted = Color(0xFF6B7280);
  static const _rule = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final app = context.watch<AppState>();
    final user = context.watch<AuthService>().user;
    final settings = context.watch<Settings>();
    final name = user?.name ?? settings.ownerName;
    final last = page == pages - 1;
    final total = all.fold<double>(0, (a, e) => a + e.amount);
    const small = TextStyle(color: _muted, fontSize: 9.5);

    String item(Expense e) {
      final unit = (e.fuelType ?? vehicleFor(app, e)?.fuel)?.unit(s);
      final detail = [
        if (e.quantity != null && unit != null) '${f.number(e.quantity!, decimals: 1)} $unit',
        if (e.note?.isNotEmpty ?? false) e.note!,
        if (e.place?.isNotEmpty ?? false) e.place!,
        if (vehicle == null) vehicleFor(app, e)?.name ?? '',
      ].where((x) => x.isNotEmpty).join(' · ');
      return detail.isEmpty ? e.category.label(s) : '${e.category.label(s)} — $detail';
    }

    return Container(
      width: _pageW,
      height: _pageH,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(40, 36, 40, 28),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: _ink, fontSize: 10.5, height: 1.25),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (page == 0) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.claimTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${s.claimPeriod}: ${f.monthYear(month)}', style: const TextStyle(fontSize: 11.5, color: _muted)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFD4FF3A), borderRadius: BorderRadius.circular(6)),
                child: Text(s.appName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: _rule), borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                Expanded(child: _kv(s.claimant, [name, if (user?.phone.isNotEmpty ?? false) user!.phone].join(' · '))),
                Expanded(
                  child: _kv(s.claimVehicle, vehicle == null ? s.allCars : [vehicle!.model ?? vehicle!.name, if (vehicle!.regNo?.isNotEmpty ?? false) vehicle!.regNo!].join(' · ')),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          // Table header.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            color: const Color(0xFFF3F4F6),
            child: Row(children: [
              const SizedBox(width: 26, child: Text('#', style: TextStyle(fontWeight: FontWeight.w700))),
              SizedBox(width: 78, child: Text(s.claimDate, style: const TextStyle(fontWeight: FontWeight.w700))),
              Expanded(child: Text(s.claimItem, style: const TextStyle(fontWeight: FontWeight.w700))),
              SizedBox(width: 80, child: Text(s.claimAmount, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
          ),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _rule))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 26, child: Text(f.digits(startIndex + i + 1))),
                SizedBox(width: 78, child: Text(f.date(rows[i].date))),
                Expanded(child: Text(item(rows[i]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                SizedBox(width: 80, child: Text(f.money(rows[i].amount), textAlign: TextAlign.right)),
              ]),
            ),
          if (last) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: _ink, width: 1.2))),
              child: Row(children: [
                Expanded(child: Text(s.claimTotal, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))),
                Text(f.money(total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ]),
            ),
            const Spacer(),
            Row(children: [
              Expanded(child: _sign(s.claimant, s.signature)),
              const SizedBox(width: 40),
              Expanded(child: _sign(s.approvedBy, s.signature)),
            ]),
            const SizedBox(height: 18),
          ] else
            const Spacer(),
          Row(children: [
            Text('${s.claimMadeWith} · ${f.date(DateTime.now())}', style: small),
            const Spacer(),
            Text(s.claimPage(page + 1, pages), style: small),
          ]),
        ]),
      ),
    );
  }

  static Vehicle? vehicleFor(AppState app, Expense e) => app.vehicle(e.vehicleId);

  Widget _kv(String k, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: const TextStyle(color: _muted, fontSize: 9.5)),
        const SizedBox(height: 2),
        Text(v, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]);

  Widget _sign(String who, String line) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 28),
        Container(height: 1, color: _ink),
        const SizedBox(height: 4),
        Text(who, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(line, style: const TextStyle(color: _muted, fontSize: 9.5)),
      ]);
}

/// Dashboard entry: this month's office costs and a way to the claim.
class OfficeClaimCard extends StatelessWidget {
  const OfficeClaimCard({super.key, required this.vehicleId, required this.thisMonth});
  final int vehicleId;
  final double thisMonth;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    return Panel(
      onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => OfficeReportScreen(vehicleId: vehicleId))),
      child: Row(children: [
        IconBubble(Icons.work_rounded, p.info, size: 44),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.officeReport, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(thisMonth > 0 ? s.officeThisMonth(f.money(thisMonth)) : s.officeReportSub, style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.3)),
          ]),
        ),
        const Icon(Icons.picture_as_pdf_rounded),
      ]),
    );
  }
}
