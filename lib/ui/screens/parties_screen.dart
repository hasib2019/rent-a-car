import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import 'trip_screens.dart';

Future<void> openParties(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartiesScreen()));

/// Every client the vehicles have worked for, and what each still owes.
class PartiesScreen extends StatelessWidget {
  const PartiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    return Scaffold(
      appBar: AppBar(title: Text(s.parties)),
      body: Loader<List<PartySummary>>(
        load: (r) => r.parties(),
        builder: (context, parties) {
          if (parties.isEmpty) {
            return EmptyState(icon: Icons.groups_rounded, title: s.noParties, body: s.noPartiesBody);
          }
          final totalDue = parties.fold<double>(0, (a, x) => a + (x.due > 0 ? x.due : 0));
          final owing = parties.where((x) => x.due > 0.5).length;
          return Contained(
            maxWidth: 820,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Entrance(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.totalDue, style: TextStyle(color: p.onHero.withValues(alpha: 0.65), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(f.money(totalDue),
                                style: TextStyle(color: totalDue > 0 ? p.warning : p.accent, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.2)),
                          ),
                          Text(s.partiesSub, style: TextStyle(color: p.onHero.withValues(alpha: 0.55), fontSize: 12.5)),
                        ]),
                      ),
                      Column(children: [
                        Text(f.digits(owing), style: TextStyle(color: p.onHero, fontSize: 28, fontWeight: FontWeight.w800)),
                        Text('/ ${f.digits(parties.length)}', style: TextStyle(color: p.onHero.withValues(alpha: 0.55))),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < parties.length; i++)
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: Entrance(index: i + 1, child: _PartyCard(party: parties[i]))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.party});
  final PartySummary party;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final initials = Driver(name: party.name).initials;
    return Panel(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PartyDetailScreen(name: party.name))),
      child: Row(children: [
        Avatar(name: party.name, initials: initials, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(party.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(
              [
                s.tripCount(party.trips),
                '${s.fare} ${f.money(party.fare)}',
                if (party.lastTrip != null) '${s.lastTrip} ${f.dayMonth(party.lastTrip!)}',
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.muted, fontSize: 12.5),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(s.due, style: TextStyle(color: p.muted, fontSize: 11.5)),
          Text(party.due > 0.5 ? f.money(party.due) : '—',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: party.due > 0.5 ? p.warning : p.income)),
        ]),
        if (party.phone?.isNotEmpty ?? false) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: s.call,
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: party.phone)),
            icon: Icon(Icons.call_rounded, color: p.income),
          ),
        ],
      ]),
    );
  }
}

/// One client's trips with fares, payments and the balance.
class PartyDetailScreen extends StatelessWidget {
  const PartyDetailScreen({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final key = PartySummary.keyOf(name);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Loader<List<TripSummary>>(
        deps: [name],
        load: (r) async => (await r.trips()).where((t) => t.trip.client != null && PartySummary.keyOf(t.trip.client!) == key).toList(),
        builder: (context, trips) {
          final fare = trips.fold<double>(0, (a, t) => a + t.trip.earned);
          final received = trips.fold<double>(0, (a, t) => a + (t.trip.status.countsFare ? t.received : 0));
          final due = fare - received;
          final phone = trips.map((t) => t.trip.clientPhone).firstWhere((x) => x?.isNotEmpty ?? false, orElse: () => null);
          return Contained(
            maxWidth: 820,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Panel(
                  child: Column(children: [
                    Row(children: [
                      Avatar(name: name, initials: Driver(name: name).initials, size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          if (phone != null) Text(f.digits(phone), style: TextStyle(color: p.muted)),
                        ]),
                      ),
                      if (phone != null)
                        IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: p.income, foregroundColor: Colors.white),
                          onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                          icon: const Icon(Icons.call_rounded),
                        ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: KeyValue(s.trips, f.digits(trips.length))),
                      Expanded(child: KeyValue(s.fare, f.money(fare))),
                      Expanded(child: KeyValue(s.received, f.money(received), color: p.income)),
                      Expanded(child: KeyValue(s.partyDue, f.money(due > 0 ? due : 0), color: due > 0.5 ? p.warning : p.muted, end: true)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),
                for (final t in trips) Padding(padding: const EdgeInsets.only(bottom: 12), child: TripCard(summary: t)),
              ],
            ),
          );
        },
      ),
    );
  }
}
