import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/drive_backup.dart';
import '../services/settings.dart';
import '../state/app_state.dart';
import 'screens/entry_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ledger_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/trip_screens.dart';
import 'screens/vehicle_screens.dart';
import 'widgets/common.dart';

enum _Tab { home, fleet, trips, parts, ledger, reports, settings }

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating pill navigation on phones, a sidebar on tablets / desktop / web.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _Tab _tab = _Tab.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoBackup());
  }

  /// Once a day, silently push a backup to Drive if the owner opted in.
  Future<void> _autoBackup() async {
    final settings = context.read<Settings>();
    final app = context.read<AppState>();
    final drive = DriveBackup.instance;
    if (!settings.autoBackup || settings.driveEmail == null || !drive.configured) return;
    final last = settings.lastBackup;
    if (last != null && DateTime.now().difference(last).inHours < 20) return;
    try {
      if (!await drive.connect(interactive: false)) return;
      final at = await drive.upload(await app.repo.exportBytes());
      await settings.setLastBackup(at);
    } catch (_) {
      // Silent: the owner can always back up manually from settings.
    }
  }

  /// Phones get four tabs around the + button; trips and parts open as pages.
  List<_Tab> _tabs(bool wide) => wide ? _Tab.values : const [_Tab.home, _Tab.fleet, _Tab.ledger, _Tab.reports];

  void _open(_Tab tab) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (_tabs(wide).contains(tab)) {
      HapticFeedback.selectionClick();
      setState(() => _tab = tab);
      return;
    }
    final Widget page = switch (tab) {
      _Tab.trips => const TripsScreen(),
      _Tab.parts => const MaintenanceScreen(),
      _ => const SettingsScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  _NavItem _item(_Tab t, S s) => switch (t) {
        _Tab.home => _NavItem(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, s.navHome),
        _Tab.fleet => _NavItem(Icons.directions_car_outlined, Icons.directions_car_filled_rounded, s.navFleet),
        _Tab.trips => _NavItem(Icons.route_outlined, Icons.route_rounded, s.navTrips),
        _Tab.parts => _NavItem(Icons.build_circle_outlined, Icons.build_circle_rounded, s.navParts),
        _Tab.ledger => _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, s.navLedger),
        _Tab.reports => _NavItem(Icons.insights_outlined, Icons.insights_rounded, s.navReport),
        _Tab.settings => _NavItem(Icons.tune_outlined, Icons.tune_rounded, s.navSettings),
      };

  Widget _page(_Tab t) => switch (t) {
        _Tab.home => HomeScreen(
            onOpenLedger: () => _open(_Tab.ledger),
            onOpenTrips: () => _open(_Tab.trips),
            onOpenParts: () => _open(_Tab.parts),
          ),
        _Tab.fleet => const FleetScreen(),
        _Tab.trips => const TripsScreen(embedded: true),
        _Tab.parts => const MaintenanceScreen(embedded: true),
        _Tab.ledger => const LedgerScreen(),
        _Tab.reports => ReportsScreen(onOpenTrips: () => _open(_Tab.trips)),
        _Tab.settings => const SettingsScreen(embedded: true),
      };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final tabs = _tabs(wide);
    final items = [for (final t in tabs) _item(t, s)];
    final index = tabs.contains(_tab) ? tabs.indexOf(_tab) : 0;
    void go(int i) => _open(tabs[i]);
    final body = IndexedStack(index: index, children: [for (final t in tabs) _page(t)]);

    if (wide) {
      return Scaffold(
        body: Row(children: [
          _Sidebar(items: items, index: index, onTap: go),
          Expanded(child: body),
        ]),
      );
    }

    return Scaffold(
      extendBody: true,
      body: body,
      bottomNavigationBar: _FloatingNav(items: items, index: index, onTap: go),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.items, required this.index, required this.onTap});
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget tab(int i) {
      final it = items[i];
      final sel = i == index;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: SizedBox(
            height: 64,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                padding: EdgeInsets.symmetric(horizontal: sel ? 16 : 0, vertical: 5),
                decoration: BoxDecoration(color: sel ? p.accent : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                child: Icon(sel ? it.activeIcon : it.icon, size: 23, color: sel ? p.onAccent : p.onHero.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: kFont,
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? p.onHero : p.onHero.withValues(alpha: 0.55),
                ),
                child: Text(it.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ),
      );
    }

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 78,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: (p.isDark ? p.surfaceAlt : p.hero).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(children: [tab(0), tab(1), const SizedBox(width: 72), tab(2), tab(3)]),
                ),
              ),
            ),
            Positioned(
              top: -6,
              child: Pressable(
                onTap: () => showQuickAdd(context),
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: p.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.bg, width: 5),
                    boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Icon(Icons.add_rounded, size: 32, color: p.onAccent),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.items, required this.index, required this.onTap});
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.s;
    final settings = context.watch<Settings>();
    return Container(
      width: 260,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.menu_book_rounded, color: p.onAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.appName, style: TextStyle(color: p.onHero, fontWeight: FontWeight.w800, fontSize: 18)),
                  if (settings.businessName.isNotEmpty)
                    Text(settings.businessName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.onHero.withValues(alpha: 0.55), fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 28),
            Pressable(
              onTap: () => showQuickAdd(context),
              child: Container(
                height: 52,
                decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(18)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_rounded, color: p.onAccent),
                  const SizedBox(width: 8),
                  Text(s.quickAdd, style: TextStyle(color: p.onAccent, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: i == index ? p.onHero.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      child: Row(children: [
                        Icon(i == index ? items[i].activeIcon : items[i].icon, color: i == index ? p.accent : p.onHero.withValues(alpha: 0.6)),
                        const SizedBox(width: 14),
                        Text(items[i].label,
                            style: TextStyle(color: i == index ? p.onHero : p.onHero.withValues(alpha: 0.7), fontWeight: i == index ? FontWeight.w700 : FontWeight.w500)),
                      ]),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            Text(context.fmt.date(DateTime.now()), style: TextStyle(color: p.onHero.withValues(alpha: 0.45), fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
