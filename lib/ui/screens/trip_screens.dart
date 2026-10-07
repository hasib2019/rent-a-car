import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'parties_screen.dart';
import 'vehicle_screens.dart';

Future<void> openTripForm(BuildContext context, {int? vehicleId}) => Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => TripFormScreen(vehicleId: vehicleId),
    ));

Future<void> openTrip(BuildContext context, int tripId) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: tripId)));

/// "12 Oct" or "12 – 14 Oct" for multi-day trips.
String tripDates(Fmt f, Trip t) {
  final end = t.endDate;
  if (end == null || dbDate(end) == dbDate(t.startDate)) return f.dayMonth(t.startDate);
  if (end.month == t.startDate.month && end.year == t.startDate.year) {
    return '${f.digits(t.startDate.day)} – ${f.dayMonth(end)}';
  }
  return '${f.dayMonth(t.startDate)} – ${f.dayMonth(end)}';
}

// ── List ──────────────────────────────────────────────────────────────────

/// Trips for a month: where each vehicle went, the fare and the road costs.
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key, this.embedded = false, this.vehicleId});

  /// True when shown as a tab on wide layouts (no app bar).
  final bool embedded;
  final int? vehicleId;

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late int? _vehicleId = widget.vehicleId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final app = context.watch<AppState>();

    final content = Column(children: [
      if (widget.embedded)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Row(children: [
            Expanded(child: Text(s.trips, style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
            RoundIconButton(icon: Icons.add_rounded, filled: true, tooltip: s.newTrip, onTap: () => openTripForm(context, vehicleId: _vehicleId)),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          MonthSwitcher(month: _month, onChanged: (m) => setState(() => _month = m)),
          const Spacer(),
          TextButton.icon(onPressed: () => openParties(context), icon: const Icon(Icons.groups_rounded, size: 20), label: Text(s.parties)),
        ]),
      ),
      if (app.vehicles.length > 1) VehicleFilter(selected: _vehicleId, onChanged: (id) => setState(() => _vehicleId = id)),
      Expanded(
        child: Loader<List<TripSummary>>(
          deps: [_month, _vehicleId],
          load: (r) => r.trips(period: Period.month(_month), vehicleId: _vehicleId),
          builder: (context, trips) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
            children: [
              Entrance(child: TripTotalsCard(trips: trips, label: context.fmt.monthYear(_month))),
              const SizedBox(height: 14),
              if (trips.isEmpty)
                EmptyState(
                  icon: Icons.route_rounded,
                  title: s.noTrips,
                  body: s.noTripsBody,
                  action: app.vehicles.isEmpty
                      ? null
                      : FilledButton.icon(
                          onPressed: () => openTripForm(context, vehicleId: _vehicleId),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(s.newTrip),
                        ),
                )
              else
                for (var i = 0; i < trips.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Entrance(index: i + 1, child: TripCard(summary: trips[i], showVehicle: _vehicleId == null)),
                  ),
            ],
          ),
        ),
      ),
    ]);

    final body = Contained(maxWidth: 820, child: content);
    if (widget.embedded) return SafeArea(bottom: false, child: body);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.trips),
        actions: [
          IconButton(tooltip: s.newTrip, onPressed: () => openTripForm(context, vehicleId: _vehicleId), icon: const Icon(Icons.add_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: body,
    );
  }
}

/// Dark summary card: profit of the listed trips with fare vs cost.
class TripTotalsCard extends StatelessWidget {
  const TripTotalsCard({super.key, required this.trips, required this.label});
  final List<TripSummary> trips;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final fare = trips.fold<double>(0, (a, t) => a + t.trip.earned);
    final cost = trips.fold<double>(0, (a, t) => a + t.cost);
    final due = trips.fold<double>(0, (a, t) => a + (t.due > 0 ? t.due : 0));
    final profit = fare - cost;
    final ratio = fare <= 0 ? 0.0 : (cost / fare).clamp(0.0, 1.0);

    Widget kv(String k, String v, Color dot) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Flexible(child: Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.onHero.withValues(alpha: 0.65), fontSize: 12.5))),
          ]),
          Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.onHero, fontWeight: FontWeight.w800, fontSize: 17)),
        ]);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: LanePainter(p.onHero.withValues(alpha: 0.05)))),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.tripProfit} · $label', style: TextStyle(color: p.onHero.withValues(alpha: 0.65), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(f.money(profit),
                  style: TextStyle(color: profit >= 0 ? p.accent : p.expense, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.4)),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: Row(children: [
                  Expanded(flex: ((1 - ratio) * 1000).round().clamp(1, 1000), child: Container(color: p.income)),
                  Expanded(flex: (ratio * 1000).round().clamp(1, 1000), child: Container(color: p.expense)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: kv(s.trips, f.digits(trips.length), p.accent)),
              Expanded(child: kv(s.fare, f.money(fare), p.income)),
              Expanded(child: kv(s.tripCost, f.money(cost), p.expense)),
            ]),
            if (due > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: p.warning.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.pending_actions_rounded, color: p.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.partyDue, style: TextStyle(color: p.onHero, fontWeight: FontWeight.w600))),
                  Text(f.money(due), style: TextStyle(color: p.warning, fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// "Dhaka → Chattogram" with an arrow, ellipsising each end.
class RouteText extends StatelessWidget {
  const RouteText(this.trip, {super.key, this.style});
  final Trip trip;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final st = style ?? const TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
    return Row(children: [
      Flexible(child: Text(trip.origin, maxLines: 1, overflow: TextOverflow.ellipsis, style: st)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(Icons.arrow_forward_rounded, size: (st.fontSize ?? 16) + 1, color: st.color ?? context.pal.muted),
      ),
      Flexible(child: Text(trip.destination, maxLines: 1, overflow: TextOverflow.ellipsis, style: st)),
    ]);
  }
}

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.summary, this.showVehicle = true});
  final TripSummary summary;
  final bool showVehicle;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final t = summary.trip;
    final v = app.vehicle(t.vehicleId);
    final driver = app.driver(t.driverId);
    final sub = [
      tripDates(f, t),
      if (showVehicle && v != null) v.name,
      if (driver != null) driver.name,
      if (t.client?.isNotEmpty ?? false) t.client!,
    ].join(' · ');

    return Panel(
      onTap: () => openTrip(context, t.id!),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (v != null) TypeBadge(v.type, size: 46) else IconBubble(Icons.route_rounded, p.income, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RouteText(t),
              const SizedBox(height: 2),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
            ]),
          ),
          if (t.status != TripStatus.done) ...[
            const SizedBox(width: 8),
            TripStatusPill(t.status),
          ] else if (t.distance != null) ...[
            const SizedBox(width: 8),
            StatusPill('${f.number(t.distance!)} ${s.km}', p.info),
          ],
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(child: KeyValue(s.fare, f.money(t.fare), color: p.income)),
            Expanded(child: KeyValue(s.tripCost, f.money(summary.cost), color: p.expense)),
            Expanded(child: KeyValue(s.profit, f.money(summary.profit), color: summary.profit >= 0 ? p.ink : p.expense, end: true)),
          ]),
        ),
        if (t.status == TripStatus.booked && summary.received > 0) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.savings_outlined, size: 16, color: p.info),
            const SizedBox(width: 6),
            Text('${s.received} ${f.money(summary.received)}', style: TextStyle(color: p.info, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ],
        if (summary.due > 0.5) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.pending_actions_rounded, size: 16, color: p.warning),
            const SizedBox(width: 6),
            Expanded(
              child: Text('${s.partyDue} ${f.money(summary.due)}',
                  style: TextStyle(color: p.warning, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            Text('${s.received} ${f.money(summary.received)}', style: TextStyle(color: p.muted, fontSize: 12)),
          ]),
        ],
      ]),
    );
  }
}

class TripStatusPill extends StatelessWidget {
  const TripStatusPill(this.status, {super.key});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final color = switch (status) {
      TripStatus.booked => p.info,
      TripStatus.running => p.warning,
      TripStatus.done => p.income,
      TripStatus.cancelled => p.muted,
    };
    return StatusPill(status.label(context.s), color, icon: status.icon);
  }
}

// ── Detail ────────────────────────────────────────────────────────────────

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.tripId});
  final int tripId;

  Future<void> _delete(BuildContext context) async {
    final s = context.s;
    if (!await confirm(context, title: s.deleteTrip, body: s.deleteTripBody)) return;
    if (!context.mounted) return;
    final nav = Navigator.of(context);
    await context.read<AppState>().mutate((r) => r.deleteTrip(tripId));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Loader<(Trip?, List<Expense>, List<TripPayment>)>(
      deps: [tripId],
      load: (r) async => (await r.trip(tripId), await r.tripCosts(tripId), await r.tripPayments(tripId)),
      placeholder: const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2.4))),
      builder: (context, d) {
        final (trip, costs, payments) = d;
        if (trip == null) return const Scaffold();
        final s = context.s;
        final p = context.pal;
        final wide = MediaQuery.sizeOf(context).width >= 900;

        final hero = _TripHero(trip: trip);
        final stats = _TripStats(trip: trip, costs: costs);
        final paymentPanel = _PaymentsPanel(trip: trip, payments: payments);
        final costPanel = TripCostsPanel(costs: costs);
        final note = trip.note?.isNotEmpty ?? false
            ? Panel(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.edit_note_rounded, color: p.muted),
                  const SizedBox(width: 10),
                  Expanded(child: Text(trip.note!)),
                ]),
              )
            : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(s.trip),
            actions: [
              IconButton(
                tooltip: s.edit,
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripFormScreen(trip: trip, costs: costs, payments: payments))),
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
                        Expanded(child: Column(children: [hero, const SizedBox(height: 14), stats, if (note != null) ...[const SizedBox(height: 14), note]])),
                        const SizedBox(width: 16),
                        Expanded(child: Column(children: [paymentPanel, const SizedBox(height: 14), costPanel])),
                      ]),
                    ]
                  : [
                      Entrance(child: hero),
                      const SizedBox(height: 14),
                      Entrance(index: 1, child: stats),
                      const SizedBox(height: 14),
                      Entrance(index: 2, child: paymentPanel),
                      const SizedBox(height: 14),
                      costPanel,
                      if (note != null) ...[const SizedBox(height: 14), note],
                    ],
            ),
          ),
        );
      },
    );
  }
}

class _TripHero extends StatelessWidget {
  const _TripHero({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;
    final f = context.fmt;
    final v = app.vehicle(trip.vehicleId);
    final driver = app.driver(trip.driverId);
    final color = v?.type.color ?? context.pal.income;
    const white = Colors.white;
    final dim = Colors.white.withValues(alpha: 0.7);

    Widget stop(String place, {required bool first}) => Row(children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: first ? Colors.transparent : white,
              shape: BoxShape.circle,
              border: Border.all(color: white, width: 3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(place, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15)),
          ),
        ]);

    Widget pill(String text, {bool dark = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: (dark ? Colors.black : white).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: Text(text, style: const TextStyle(color: white, fontWeight: FontWeight.w700, fontSize: 12.5)),
        );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, Color.lerp(color, Colors.black, 0.45)!]),
      ),
      child: Stack(children: [
        Positioned(right: -30, bottom: -40, child: Icon(Icons.route_rounded, size: 200, color: white.withValues(alpha: 0.12))),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              pill(tripDates(f, trip)),
              if (trip.days > 1) pill(s.dayCount(trip.days), dark: true),
              pill(trip.status.label(s), dark: true),
            ]),
            const SizedBox(height: 18),
            stop(trip.origin, first: true),
            Padding(
              padding: const EdgeInsets.only(left: 5.5),
              child: Column(children: [for (var i = 0; i < 3; i++) Container(width: 3, height: 5, margin: const EdgeInsets.symmetric(vertical: 2), color: dim)]),
            ),
            stop(trip.destination, first: false),
            if (trip.client?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              Row(children: [
                Icon(Icons.person_pin_circle_rounded, color: dim, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text([trip.client!, if (trip.clientPhone?.isNotEmpty ?? false) f.digits(trip.clientPhone!)].join(' · '),
                      style: const TextStyle(color: white, fontWeight: FontWeight.w600)),
                ),
                if (trip.clientPhone?.isNotEmpty ?? false)
                  IconButton.filled(
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(backgroundColor: white, foregroundColor: Colors.black),
                    tooltip: s.call,
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: trip.clientPhone)),
                    icon: const Icon(Icons.call_rounded, size: 18),
                  ),
              ]),
            ],
            if (trip.goods?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.inventory_2_outlined, color: dim, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(trip.goods!, style: const TextStyle(color: white, fontWeight: FontWeight.w600))),
              ]),
            ],
            if (trip.challanNo?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.confirmation_number_outlined, color: dim, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text('${s.challanNo}: ${trip.challanNo}', style: const TextStyle(color: white, fontWeight: FontWeight.w600))),
              ]),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                if (v != null) Icon(v.type.icon, color: white) else const Icon(Icons.directions_car_rounded, color: white),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: v == null ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicleId: v.id!))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v?.name ?? '', style: const TextStyle(color: white, fontWeight: FontWeight.w700)),
                      Text(driver?.name ?? s.noDriver, style: TextStyle(color: dim, fontSize: 12.5)),
                    ]),
                  ),
                ),
                if (v?.regNo?.isNotEmpty ?? false) NumberPlate(regNo: v!.regNo),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TripStats extends StatelessWidget {
  const _TripStats({required this.trip, required this.costs});
  final Trip trip;
  final List<Expense> costs;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final cost = costs.fold<double>(0, (a, c) => a + c.amount);
    final profit = trip.earned - cost;
    final dist = trip.distance;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 116),
      children: [
        StatBlock(label: s.fare, value: f.money(trip.fare), color: p.income, icon: Icons.south_west_rounded),
        StatBlock(label: s.tripCost, value: f.money(cost), color: p.expense, icon: Icons.north_east_rounded),
        StatBlock(
          label: s.tripProfit,
          value: f.money(profit),
          color: profit >= 0 ? p.ink : p.expense,
          icon: Icons.trending_up_rounded,
          sub: trip.fare > 0 ? '${s.margin} ${f.percent(profit / trip.fare)}' : null,
        ),
        StatBlock(
          label: s.distance,
          value: dist == null ? '—' : '${f.number(dist)} ${s.km}',
          icon: Icons.speed_rounded,
          color: p.info,
          sub: dist == null ? null : '${s.costPerKm} ${f.money(cost / dist)}',
        ),
      ],
    );
  }
}

/// What the party has paid against the fare, and the balance.
class _PaymentsPanel extends StatelessWidget {
  const _PaymentsPanel({required this.trip, required this.payments});
  final Trip trip;
  final List<TripPayment> payments;

  Future<void> _collect(BuildContext context, double due) async {
    final s = context.s;
    final app = context.read<AppState>();
    final pay = await showPaymentSheet(context, suggested: due > 0 ? due : null);
    if (pay == null) return;
    await app.mutate((r) => r.addTripPayment(TripPayment(tripId: trip.id, date: pay.date, amount: pay.amount, method: pay.method, note: pay.note)));
    if (context.mounted) toast(context, s.paymentSaved);
  }

  Future<void> _remove(BuildContext context, TripPayment pay) async {
    final s = context.s;
    if (!await confirm(context, title: s.deletePayment, body: s.confirmDeleteBody)) return;
    if (!context.mounted) return;
    await context.read<AppState>().mutate((r) => r.deleteTripPayment(pay.id!));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final received = payments.fold<double>(0, (a, x) => a + x.amount);
    // A booking can still take more advance; a cancelled trip takes nothing.
    final due = trip.status == TripStatus.cancelled ? 0.0 : trip.fare - received;
    final ratio = trip.fare <= 0 ? 0.0 : (received / trip.fare).clamp(0.0, 1.0);

    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.account_balance_wallet_rounded, color: p.income, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(s.payments, style: const TextStyle(fontWeight: FontWeight.w700))),
          if (due <= 0.5 && trip.fare > 0 && trip.status != TripStatus.cancelled) StatusPill(s.paidInFull, p.income, icon: Icons.check_circle_rounded),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: KeyValue(s.fare, f.money(trip.fare))),
          Expanded(child: KeyValue(s.received, f.money(received), color: p.income)),
          Expanded(child: KeyValue(s.partyDue, f.money(due > 0 ? due : 0), color: due > 0.5 ? p.warning : p.muted, end: true)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: ratio, minHeight: 8, color: p.income, backgroundColor: p.surfaceAlt),
        ),
        const SizedBox(height: 6),
        if (payments.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(s.noPayments, style: TextStyle(color: p.muted)))
        else
          for (final pay in payments)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                IconBubble(pay.method.icon, p.income, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.money(pay.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text([f.date(pay.date), pay.method.label(s), if (pay.note?.isNotEmpty ?? false) pay.note!].join(' · '),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
                  ]),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: s.delete,
                  onPressed: () => _remove(context, pay),
                  icon: Icon(Icons.close_rounded, size: 18, color: p.muted),
                ),
              ]),
            ),
        if (due > 0.5) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent),
              onPressed: () => _collect(context, due),
              icon: const Icon(Icons.add_card_rounded),
              label: Text(s.collectPayment),
            ),
          ),
        ],
      ]),
    );
  }
}

/// Amount, date and method of one payment from a party.
Future<TripPayment?> showPaymentSheet(BuildContext context, {TripPayment? payment, double? suggested}) {
  return showModalBottomSheet<TripPayment>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PaymentSheet(payment: payment, suggested: suggested),
  );
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({this.payment, this.suggested});
  final TripPayment? payment;
  final double? suggested;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late final _amount = TextEditingController(
      text: widget.payment != null ? _trim(widget.payment!.amount) : (widget.suggested == null ? '' : _trim(widget.suggested!)));
  late final _note = TextEditingController(text: widget.payment?.note);
  late DateTime _date = widget.payment?.date ?? DateUtils.dateOnly(DateTime.now());
  late PayMethod _method = widget.payment?.method ?? PayMethod.cash;
  bool _invalid = false;

  static String _trim(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _done() {
    final amount = parseAmount(_amount.text) ?? 0;
    if (amount <= 0) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, TripPayment(date: _date, amount: amount, method: _method, note: _note.text.trim().isEmpty ? null : _note.text.trim()));
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
              Text(s.collectPayment, style: context.text.titleLarge),
              const SizedBox(height: 14),
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                onChanged: (_) => _invalid ? setState(() => _invalid = false) : null,
                onSubmitted: (_) => _done(),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                decoration: InputDecoration(labelText: s.amount, prefixText: '৳ ', errorText: _invalid ? s.enterAmount : null),
              ),
              const SizedBox(height: 14),
              Text(s.payMethod, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in PayMethod.values)
                  ChoiceTag(label: m.label(s), icon: m.icon, selected: _method == m, onTap: () => setState(() => _method = m)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: DateFormField(label: s.date, value: _date, onPick: (d) => setState(() => _date = d))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _note, decoration: InputDecoration(labelText: s.note, prefixIcon: const Icon(Icons.edit_note_rounded)))),
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

/// Itemised road costs with a share bar by category.
class TripCostsPanel extends StatelessWidget {
  const TripCostsPanel({super.key, required this.costs});
  final List<Expense> costs;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final total = costs.fold<double>(0, (a, c) => a + c.amount);
    final byCat = <ExpenseCategory, double>{};
    for (final c in costs) {
      byCat[c.category] = (byCat[c.category] ?? 0) + c.amount;
    }
    final shares = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(s.roadCosts, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(f.money(total), style: TextStyle(fontWeight: FontWeight.w800, color: p.expense)),
        ]),
        if (costs.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.noData, style: TextStyle(color: p.muted)))
        else ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(children: [
                for (final e in shares) Expanded(flex: (e.value / total * 1000).round().clamp(1, 1000), child: Container(color: e.key.color)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 6, children: [
            for (final e in shares)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: e.key.color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('${e.key.label(s)} ${f.money(e.value)}', style: TextStyle(color: p.muted, fontSize: 12)),
              ]),
          ]),
          const SizedBox(height: 6),
          for (final c in costs) TripCostTile(category: c.category, amount: c.amount, place: c.place, quantity: c.quantity, note: c.note),
        ],
      ]),
    );
  }
}

class TripCostTile extends StatelessWidget {
  const TripCostTile({super.key, required this.category, required this.amount, this.place, this.quantity, this.note, this.onTap, this.onRemove});
  final ExpenseCategory category;
  final double amount;
  final String? place;
  final double? quantity;
  final String? note;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final sub = [
      if (place?.isNotEmpty ?? false) place!,
      if (quantity != null) '${f.number(quantity!, decimals: 1)} ${s.bn ? 'লি/m³' : 'L/m³'}',
      if (note?.isNotEmpty ?? false) note!,
    ].join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          IconBubble(category.icon, category.color, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(category.label(s), style: const TextStyle(fontWeight: FontWeight.w600)),
              if (sub.isNotEmpty) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
            ]),
          ),
          Text(f.money(amount), style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
          if (onRemove != null)
            IconButton(visualDensity: VisualDensity.compact, onPressed: onRemove, icon: Icon(Icons.close_rounded, size: 18, color: p.muted)),
        ]),
      ),
    );
  }
}

// ── Form ──────────────────────────────────────────────────────────────────

/// A road cost being edited in the trip form (not yet tied to a vehicle/date).
class _CostDraft {
  _CostDraft({required this.category, required this.amount, this.quantity, this.place, this.note});
  final ExpenseCategory category;
  final double amount;
  final double? quantity;
  final String? place;
  final String? note;
}

class TripFormScreen extends StatefulWidget {
  const TripFormScreen({super.key, this.trip, this.costs = const [], this.payments = const [], this.vehicleId});
  final Trip? trip;
  final List<Expense> costs;
  final List<TripPayment> payments;
  final int? vehicleId;

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _origin = TextEditingController(text: widget.trip?.origin);
  late final _dest = TextEditingController(text: widget.trip?.destination);
  late final _client = TextEditingController(text: widget.trip?.client);
  late final _clientPhone = TextEditingController(text: widget.trip?.clientPhone);
  late final _goods = TextEditingController(text: widget.trip?.goods);
  late final _challan = TextEditingController(text: widget.trip?.challanNo);
  late final _fare = TextEditingController(text: _num(widget.trip?.fare));
  late final _startKm = TextEditingController(text: _num(widget.trip?.startKm));
  late final _endKm = TextEditingController(text: _num(widget.trip?.endKm));
  late final _note = TextEditingController(text: widget.trip?.note);
  late int? _vehicleId = widget.trip?.vehicleId ?? widget.vehicleId;
  late int? _driverId = widget.trip?.driverId;
  late DateTime _start = widget.trip?.startDate ?? DateUtils.dateOnly(DateTime.now());
  late DateTime? _end = widget.trip?.endDate;
  late TripStatus _status = widget.trip?.status ?? TripStatus.done;
  late final List<_CostDraft> _costs = [
    for (final c in widget.costs) _CostDraft(category: c.category, amount: c.amount, quantity: c.quantity, place: c.place, note: c.note),
  ];
  late final List<TripPayment> _payments = List.of(widget.payments);
  Map<int, double> _odometers = {};
  List<String> _clients = [], _places = [];
  bool _saving = false;

  static String _num(double? v) => v == null || v == 0 ? '' : (v == v.roundToDouble() ? v.round().toString() : v.toString());

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    Future.wait([app.repo.suggestions('trips', 'client'), app.repo.suggestions('trips', 'origin'), app.repo.suggestions('trips', 'destination')]).then((res) {
      if (!mounted) return;
      setState(() {
        _clients = res[0];
        _places = {...res[1], ...res[2]}.toList();
      });
    });
    if (widget.trip == null) {
      _vehicleId ??= app.activeVehicles.isNotEmpty ? app.activeVehicles.first.id : (app.vehicles.isNotEmpty ? app.vehicles.first.id : null);
      _driverId = app.vehicle(_vehicleId)?.driverId;
      app.repo.odometers().then((m) {
        if (!mounted) return;
        setState(() {
          _odometers = m;
          _prefillStartKm();
        });
      });
    }
  }

  void _prefillStartKm() {
    final km = _odometers[_vehicleId];
    if (widget.trip == null && _startKm.text.isEmpty && km != null) _startKm.text = _num(km);
  }

  @override
  void dispose() {
    for (final c in [_origin, _dest, _client, _clientPhone, _goods, _challan, _fare, _startKm, _endKm, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _fareValue => parseAmount(_fare.text) ?? 0;
  double get _costTotal => _costs.fold(0, (a, c) => a + c.amount);
  double get _received => _payments.fold(0, (a, p) => a + p.amount);

  Future<void> _pickClient(String name) async {
    final phone = await context.read<AppState>().repo.clientPhone(name);
    if (mounted && phone != null && _clientPhone.text.trim().isEmpty) setState(() => _clientPhone.text = phone);
  }

  Future<void> _editPayment({int? index}) async {
    final due = _fareValue - _received;
    final pay = await showPaymentSheet(context, payment: index == null ? null : _payments[index], suggested: index == null && due > 0 ? due : null);
    if (pay == null) return;
    setState(() => index == null ? _payments.add(pay) : _payments[index] = pay);
  }

  void _pickVehicle(int id) {
    final app = context.read<AppState>();
    setState(() {
      final wasAuto = _startKm.text == _num(_odometers[_vehicleId]);
      _vehicleId = id;
      _driverId = app.vehicle(id)?.driverId;
      if (wasAuto) {
        _startKm.clear();
        _prefillStartKm();
      }
    });
  }

  Future<void> _editCost({int? index, ExpenseCategory? category}) async {
    final draft = await showModalBottomSheet<_CostDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CostSheet(draft: index == null ? null : _costs[index], category: category),
    );
    if (draft == null) return;
    setState(() => index == null ? _costs.add(draft) : _costs[index] = draft);
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
    final trip = Trip(
      id: widget.trip?.id,
      vehicleId: _vehicleId!,
      driverId: _driverId,
      startDate: _start,
      endDate: _end,
      origin: _origin.text,
      destination: _dest.text,
      client: text(_client),
      fare: _fareValue,
      startKm: parseAmount(_startKm.text),
      endKm: parseAmount(_endKm.text),
      note: text(_note),
      clientPhone: text(_clientPhone),
      status: _status,
      goods: text(_goods),
      challanNo: text(_challan),
    );
    final costs = [
      for (final c in _costs)
        Expense(date: _start, vehicleId: _vehicleId!, category: c.category, amount: c.amount, quantity: c.quantity, place: c.place, note: c.note),
    ];
    try {
      await app.mutate((r) => r.saveTrip(trip, costs, payments: _payments));
      if (!mounted) return;
      toast(context, s.tripSaved);
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
    final earned = _status.countsFare ? _fareValue : 0.0;
    final profit = earned - _costTotal;
    final due = _status == TripStatus.cancelled ? 0.0 : _fareValue - _received;
    final startKm = parseAmount(_startKm.text), endKm = parseAmount(_endKm.text);
    final dist = startKm != null && endKm != null && endKm > startKm ? endKm - startKm : null;
    String? numValidator(String? v) => v != null && v.trim().isNotEmpty && parseAmount(v) == null ? s.invalidNumber : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        title: Text(widget.trip == null ? s.newTrip : s.editTrip),
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
                    ChoiceTag(label: v.name, icon: v.type.icon, color: v.type.color, selected: v.id == _vehicleId, onTap: () => _pickVehicle(v.id!)),
                ]),
              const SizedBox(height: 20),
              _label(s.tripStatus),
              PillToggle<TripStatus>(values: TripStatus.values, selected: _status, label: (t) => t.label(s), onChanged: (t) => setState(() => _status = t)),
              const SizedBox(height: 20),
              _label(s.route),
              Row(children: [
                Expanded(
                  child: Column(children: [
                    SuggestField(
                      controller: _origin,
                      suggestions: _places,
                      label: s.tripOrigin,
                      hint: s.tripOriginHint,
                      icon: Icons.trip_origin_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? s.required : null,
                    ),
                    const SizedBox(height: 10),
                    SuggestField(
                      controller: _dest,
                      suggestions: _places,
                      label: s.tripDestination,
                      hint: s.tripDestinationHint,
                      icon: Icons.place_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? s.required : null,
                    ),
                  ]),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: '⇅',
                  onPressed: () => setState(() {
                    final o = _origin.text;
                    _origin.text = _dest.text;
                    _dest.text = o;
                  }),
                  icon: const Icon(Icons.swap_vert_rounded),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: DateFormField(label: s.startDate, value: _start, onPick: (d) => setState(() => _start = d))),
                const SizedBox(width: 10),
                Expanded(
                  child: _OptionalDateField(
                    label: s.endDate,
                    value: _end,
                    first: _start,
                    onChanged: (d) => setState(() => _end = d),
                  ),
                ),
              ]),
              if (_end != null && _end!.isBefore(_start))
                Padding(padding: const EdgeInsets.only(top: 6, left: 12), child: Text(s.endBeforeStart, style: TextStyle(color: p.expense, fontSize: 12.5))),
              const SizedBox(height: 24),
              _label(s.businessDetails),
              FieldPair(
                SuggestField(
                  controller: _client,
                  suggestions: _clients,
                  label: s.client,
                  icon: Icons.person_pin_circle_outlined,
                  onSelected: _pickClient,
                ),
                TextFormField(
                  controller: _clientPhone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: s.clientPhone, hintText: '01XXXXXXXXX', prefixIcon: const Icon(Icons.phone_outlined)),
                ),
                firstFlex: 3,
                secondFlex: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fare,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                decoration: InputDecoration(labelText: s.fare, helperText: s.fareHelp, prefixText: '৳ ', prefixIcon: const Icon(Icons.payments_rounded)),
                validator: numValidator,
              ),
              const SizedBox(height: 12),
              FieldPair(
                TextFormField(
                  controller: _goods,
                  decoration: InputDecoration(labelText: s.goods, hintText: s.goodsHint, prefixIcon: const Icon(Icons.inventory_2_outlined)),
                ),
                TextFormField(
                  controller: _challan,
                  decoration: InputDecoration(labelText: s.challanNo, prefixIcon: const Icon(Icons.confirmation_number_outlined)),
                ),
                firstFlex: 3,
                secondFlex: 2,
              ),
              const SizedBox(height: 20),
              _label(s.driver),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceTag(label: s.none, selected: _driverId == null, onTap: () => setState(() => _driverId = null)),
                for (final d in app.drivers.where((d) => d.active || d.id == _driverId))
                  ChoiceTag(label: d.name, icon: Icons.person_rounded, selected: _driverId == d.id, onTap: () => setState(() => _driverId = d.id)),
              ]),
              const SizedBox(height: 20),
              FieldPair(
                TextFormField(
                  controller: _startKm,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: s.startKm, prefixIcon: const Icon(Icons.speed_rounded), isDense: true),
                  validator: numValidator,
                ),
                TextFormField(
                  controller: _endKm,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: s.endKm,
                    prefixIcon: const Icon(Icons.flag_outlined),
                    isDense: true,
                    helperText: dist == null ? null : '${s.distance}: ${f.number(dist)} ${s.km}',
                  ),
                  validator: (v) {
                    final bad = numValidator(v);
                    if (bad != null) return bad;
                    final a = parseAmount(_startKm.text), b = parseAmount(v ?? '');
                    return a != null && b != null && b < a ? s.endKmTooLow : null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _label(s.roadCosts)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, right: 4),
                  child: Text(f.money(_costTotal), style: TextStyle(color: p.expense, fontWeight: FontWeight.w800)),
                ),
              ]),
              Panel(
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                child: _costs.isEmpty
                    ? Padding(padding: const EdgeInsets.fromLTRB(4, 8, 8, 8), child: Text(s.noCostsYet, style: TextStyle(color: p.muted)))
                    : Column(children: [
                        for (var i = 0; i < _costs.length; i++)
                          TripCostTile(
                            category: _costs[i].category,
                            amount: _costs[i].amount,
                            place: _costs[i].place,
                            quantity: _costs[i].quantity,
                            note: _costs[i].note,
                            onTap: () => _editCost(index: i),
                            onRemove: () => setState(() => _costs.removeAt(i)),
                          ),
                      ]),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in ExpenseCategory.tripCosts.take(7))
                  ChoiceTag(label: '+ ${c.label(s)}', icon: c.icon, color: c.color, selected: false, onTap: () => _editCost(category: c)),
                ChoiceTag(label: s.addCost, icon: Icons.add_rounded, selected: false, onTap: () => _editCost()),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _label(s.payments)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, right: 4),
                  child: Text('${s.received} ${f.money(_received)}', style: TextStyle(color: p.income, fontWeight: FontWeight.w800)),
                ),
              ]),
              Panel(
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                child: _payments.isEmpty
                    ? Padding(padding: const EdgeInsets.fromLTRB(4, 8, 8, 8), child: Text(s.noPayments, style: TextStyle(color: p.muted)))
                    : Column(children: [
                        for (var i = 0; i < _payments.length; i++)
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _editPayment(index: i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(children: [
                                IconBubble(_payments[i].method.icon, p.income, size: 38),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    [f.date(_payments[i].date), _payments[i].method.label(s), if (_payments[i].note?.isNotEmpty ?? false) _payments[i].note!].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(f.money(_payments[i].amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => setState(() => _payments.removeAt(i)),
                                  icon: Icon(Icons.close_rounded, size: 18, color: p.muted),
                                ),
                              ]),
                            ),
                          ),
                      ]),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: ChoiceTag(label: s.addPayment, icon: Icons.add_card_rounded, color: p.income, selected: false, onTap: () => _editPayment()),
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
                    Text(
                      due > 0.5 ? '${s.partyDue} ${f.money(due)}' : '${s.fare} ${f.money(_fareValue)} − ${s.expense} ${f.money(_costTotal)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: due > 0.5 ? p.warning : p.muted, fontSize: 12.5, fontWeight: due > 0.5 ? FontWeight.w700 : null),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('${s.profit} ${f.money(profit)}',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: profit >= 0 ? p.income : p.expense)),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(140, 52)),
                  onPressed: _saving || (_end != null && _end!.isBefore(_start)) ? null : _save,
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

/// Date field that can be left empty and cleared again.
class _OptionalDateField extends StatelessWidget {
  const _OptionalDateField({required this.label, required this.value, required this.first, required this.onChanged});
  final String label;
  final DateTime? value;
  final DateTime first;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final initial = value != null && !value!.isBefore(first) ? value! : first;
        final d = await pickDate(context, initial, first: first);
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_repeat_outlined),
          suffixIcon: value == null ? null : IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => onChanged(null)),
        ),
        isEmpty: value == null,
        child: Text(value == null ? '' : context.fmt.date(value!), maxLines: 1),
      ),
    );
  }
}

class _CostSheet extends StatefulWidget {
  const _CostSheet({this.draft, this.category});
  final _CostDraft? draft;
  final ExpenseCategory? category;

  @override
  State<_CostSheet> createState() => _CostSheetState();
}

class _CostSheetState extends State<_CostSheet> {
  late ExpenseCategory _cat = widget.draft?.category ?? widget.category ?? ExpenseCategory.fuel;
  late final _amount = TextEditingController(text: widget.draft == null ? '' : _trim(widget.draft!.amount));
  late final _qty = TextEditingController(text: widget.draft?.quantity == null ? '' : _trim(widget.draft!.quantity!));
  late final _place = TextEditingController(text: widget.draft?.place);
  late final _note = TextEditingController(text: widget.draft?.note);
  bool _invalid = false;

  static String _trim(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

  bool get _hasQty => _cat == ExpenseCategory.fuel || _cat == ExpenseCategory.mobil;

  @override
  void dispose() {
    for (final c in [_amount, _qty, _place, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _done() {
    final amount = parseAmount(_amount.text) ?? 0;
    if (amount <= 0) {
      setState(() => _invalid = true);
      return;
    }
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    Navigator.pop(
      context,
      _CostDraft(category: _cat, amount: amount, quantity: _hasQty ? parseAmount(_qty.text) : null, place: text(_place), note: text(_note)),
    );
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
              Text(widget.draft == null ? s.addCost : s.editCost, style: context.text.titleLarge),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in ExpenseCategory.tripCosts)
                  ChoiceTag(label: c.label(s), icon: c.icon, color: c.color, selected: _cat == c, onTap: () => setState(() => _cat = c)),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                onChanged: (_) => _invalid ? setState(() => _invalid = false) : null,
                onSubmitted: (_) => _done(),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                decoration: InputDecoration(labelText: s.amount, prefixText: '৳ ', errorText: _invalid ? s.enterAmount : null),
              ),
              if (_hasQty) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _qty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: s.quantityOptional, prefixIcon: const Icon(Icons.water_drop_outlined)),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _place,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: s.place, hintText: s.placeHint, prefixIcon: const Icon(Icons.location_on_outlined)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                onSubmitted: (_) => _done(),
                decoration: InputDecoration(labelText: s.note, prefixIcon: const Icon(Icons.edit_note_rounded)),
              ),
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
