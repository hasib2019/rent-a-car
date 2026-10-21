import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/l10n_personal.dart';
import '../../core/theme.dart';
import '../../services/access.dart';
import '../../services/analytics.dart';
import '../../services/auth.dart';
import '../../services/settings.dart';
import '../widgets/access_gate.dart';
import '../widgets/common.dart';

/// Switches to [mode], or explains that it's locked for this account.
Future<void> chooseMode(BuildContext context, AppMode mode) async {
  if (mode == AppMode.personal && !await requireFeature(context, Feature.personalMode)) return;
  if (!context.mounted) return;
  HapticFeedback.mediumImpact();
  Navigator.of(context).popUntil((r) => r.isFirst);
  await context.read<Settings>().setAppMode(mode);
}

/// Shown once after signing in: fleet business or the owner's own car.
class ModeScreen extends StatefulWidget {
  const ModeScreen({super.key});

  @override
  State<ModeScreen> createState() => _ModeScreenState();
}

class _ModeScreenState extends State<ModeScreen> {
  @override
  void initState() {
    super.initState();
    Analytics.instance.screen('mode_select');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final cards = [
      for (final m in AppMode.values) _ModeCard(mode: m, onTap: () => chooseMode(context, m)),
    ];
    return Scaffold(
      body: SafeArea(
        child: Contained(
          maxWidth: 900,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            children: [
              Entrance(
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.menu_book_rounded, color: p.onAccent),
                  ),
                  const SizedBox(width: 12),
                  Text(s.appName, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(height: 28),
              Entrance(index: 1, child: Text(s.modeTitle, style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
              const SizedBox(height: 8),
              Entrance(index: 1, child: Text(s.modeBody, style: TextStyle(color: p.muted, height: 1.4))),
              const SizedBox(height: 24),
              if (wide)
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(child: Entrance(index: 2, child: cards[0])),
                    const SizedBox(width: 16),
                    Expanded(child: Entrance(index: 3, child: cards[1])),
                  ]),
                )
              else ...[
                Entrance(index: 2, child: cards[0]),
                const SizedBox(height: 14),
                Entrance(index: 3, child: cards[1]),
              ],
              const SizedBox(height: 20),
              Entrance(
                index: 4,
                child: Row(children: [
                  Icon(Icons.lock_outline_rounded, size: 16, color: p.muted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.modeSeparate, style: TextStyle(color: p.muted, fontSize: 12.5))),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onTap, this.current = false});
  final AppMode mode;
  final VoidCallback onTap;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    final locked = mode == AppMode.personal && !context.watch<AuthService>().access.can(Feature.personalMode);
    final fleet = mode == AppMode.fleet;
    final bg = fleet ? p.hero : p.surface;
    final fg = fleet ? p.onHero : p.ink;
    final sub = fleet ? p.onHero.withValues(alpha: 0.7) : p.muted;
    final types = fleet ? const [VehicleType.cng, VehicleType.pickup, VehicleType.microbus] : const [VehicleType.car, VehicleType.bike];
    final points = fleet
        ? [(Icons.payments_rounded, s.dailyCollection), (Icons.route_rounded, s.trips), (Icons.account_balance_wallet_rounded, s.driverDues)]
        : [(Icons.local_gas_station_rounded, s.mileage), (Icons.build_circle_rounded, s.serviceShort), (Icons.event_note_rounded, s.papers)];

    return Pressable(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: current ? p.accent : (fleet ? Colors.transparent : p.line), width: current ? 2.4 : 1.2),
        ),
        child: Stack(children: [
          if (fleet) Positioned.fill(child: CustomPaint(painter: LanePainter(p.onHero.withValues(alpha: 0.05)))),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                for (final t in types)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(16)),
                      child: Icon(t.icon, color: Colors.white, size: 26),
                    ),
                  ),
                const Spacer(),
                if (locked)
                  Icon(Icons.lock_rounded, color: sub)
                else if (current)
                  StatusPill(s.modeCurrent, fleet ? p.accent : p.income, icon: Icons.check_rounded),
              ]),
              const SizedBox(height: 20),
              Text(fleet ? s.modeFleet : s.modePersonal, style: context.text.titleLarge?.copyWith(color: fg, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(fleet ? s.modeFleetBody : s.modePersonalBody, style: TextStyle(color: sub, height: 1.4)),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final (icon, label) in points)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: fg.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 15, color: fleet ? p.accent : ExpenseCategory.fuel.color),
                      const SizedBox(width: 6),
                      Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                const Spacer(),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                  child: Icon(Icons.arrow_forward_rounded, color: p.onAccent),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Bottom sheet to move between the two books.
Future<void> showModeSheet(BuildContext context) {
  Analytics.instance.screen('mode_switch');
  final current = context.read<Settings>().appMode;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final s = ctx.s;
      final p = ctx.pal;
      return SafeArea(
        child: Contained(
          maxWidth: 560,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 4), child: Text(s.modeSwitch, style: ctx.text.headlineSmall)),
              Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 14), child: Text(s.modeSeparate, style: TextStyle(color: p.muted, fontSize: 13))),
              for (final m in AppMode.values) ...[
                _ModeCard(
                  mode: m,
                  current: m == current,
                  onTap: () {
                    if (m == current) {
                      Navigator.pop(ctx);
                      return;
                    }
                    chooseMode(context, m);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ]),
          ),
        ),
      );
    },
  );
}

/// Header chip on both dashboards showing which books are open.
class ModeSwitchButton extends StatelessWidget {
  const ModeSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    final personal = context.watch<Settings>().appMode == AppMode.personal;
    return Tooltip(
      message: s.modeSwitch,
      child: Pressable(
        onTap: () => showModeSheet(context),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(23), border: Border.all(color: p.line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(personal ? Icons.directions_car_filled_rounded : Icons.storefront_rounded, size: 19, color: personal ? ExpenseCategory.fuel.color : p.income),
            const SizedBox(width: 6),
            Text(personal ? s.myCar : s.modeFleetShort, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 2),
            Icon(Icons.swap_horiz_rounded, size: 18, color: p.muted),
          ]),
        ),
      ),
    );
  }
}

/// Settings row with the same switch.
class ModeSettingsTile extends StatelessWidget {
  const ModeSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    final personal = context.watch<Settings>().appMode == AppMode.personal;
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () => showModeSheet(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: IconBubble(Icons.swap_horiz_rounded, personal ? ExpenseCategory.fuel.color : p.income),
        title: Text(s.modeSwitch, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${s.modeCurrent}: ${personal ? s.modePersonal : s.modeFleet}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
