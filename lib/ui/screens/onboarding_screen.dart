import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../services/settings.dart';
import '../widgets/common.dart';
import '../../services/analytics.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    Analytics.instance.screen('onboarding');
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  /// The owner's name now comes from registration, so onboarding just ends.
  Future<void> _finish() => context.read<Settings>().setOnboarded();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    final settings = context.watch<Settings>();
    final slides = [
      (s.onb1Title, s.onb1Body, _Art.collection),
      (s.onb2Title, s.onb2Body, _Art.profit),
      (s.onb3Title, s.onb3Body, _Art.backup),
    ];
    final last = _index == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Contained(
          maxWidth: 560,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.menu_book_rounded, color: p.onAccent, size: 20),
                ),
                const SizedBox(width: 10),
                Text(s.appName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const Spacer(),
                SizedBox(
                  width: 170,
                  child: PillToggle<bool>(values: const [true, false], selected: settings.isBangla, label: (v) => v ? 'বাংলা' : 'English', onChanged: settings.setBangla),
                ),
              ]),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final (title, body, art) = slides[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AspectRatio(aspectRatio: 1.15, child: _Illustration(art: art)),
                      const SizedBox(height: 28),
                      Text(title, style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.15)),
                      const SizedBox(height: 10),
                      Text(body, style: TextStyle(color: p.muted, fontSize: 16, height: 1.45)),
                    ]),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    margin: const EdgeInsets.only(right: 6),
                    width: i == _index ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(color: i == _index ? p.ink : p.line, borderRadius: BorderRadius.circular(8)),
                  ),
                const Spacer(),
                if (!last) TextButton(onPressed: _finish, child: Text(s.skip)),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: last ? p.accent : p.ink, foregroundColor: last ? p.onAccent : p.bg),
                  onPressed: last ? _finish : () => _page.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(last ? s.getStarted : s.next),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

enum _Art { collection, profit, backup }

/// Composed, code-only illustrations (no image assets needed).
class _Illustration extends StatelessWidget {
  const _Illustration({required this.art});
  final _Art art;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final f = context.fmt;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(36)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: LanePainter(p.onHero.withValues(alpha: 0.07)))),
        Positioned(
          right: -40,
          top: -40,
          child: Container(width: 180, height: 180, decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.18), shape: BoxShape.circle)),
        ),
        Center(
          child: switch (art) {
            _Art.collection => Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final (i, t) in [VehicleType.cng, VehicleType.car, VehicleType.pickup].indexed)
                    Transform.rotate(
                      angle: (i - 1) * 0.12,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(24)),
                        child: Icon(t.icon, color: Colors.white, size: 40),
                      ),
                    ),
                ]),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(18)),
                  child: Text('+${f.money(3500)}', style: TextStyle(color: p.onAccent, fontWeight: FontWeight.w800, fontSize: 24)),
                ),
              ]),
            _Art.profit => Padding(
                padding: const EdgeInsets.all(28),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final (i, h) in [0.45, 0.7, 0.55, 0.9, 0.75].indexed)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: h),
                      duration: Duration(milliseconds: 600 + i * 120),
                      curve: Curves.easeOutBack,
                      builder: (_, v, _) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 34,
                        height: 180 * math.max(0, v),
                        decoration: BoxDecoration(color: i == 3 ? p.accent : p.onHero.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ]),
              ),
            _Art.backup => Stack(alignment: Alignment.center, children: [
                Container(width: 150, height: 150, decoration: BoxDecoration(border: Border.all(color: p.onHero.withValues(alpha: 0.15), width: 2), shape: BoxShape.circle)),
                Container(width: 210, height: 210, decoration: BoxDecoration(border: Border.all(color: p.onHero.withValues(alpha: 0.08), width: 2), shape: BoxShape.circle)),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(30)),
                  child: Icon(Icons.cloud_done_rounded, size: 50, color: p.onAccent),
                ),
              ]),
          },
        ),
      ]),
    );
  }
}
