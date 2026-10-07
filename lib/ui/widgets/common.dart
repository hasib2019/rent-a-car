import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../state/app_state.dart';

/// Runs [load] against the repository and re-runs it whenever the data
/// changes ([AppState.revision]) or [deps] change. Keeps the previous value
/// on screen while reloading so nothing flickers.
class Loader<T> extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder, this.deps = const [], this.placeholder});

  final Future<T> Function(Repository repo) load;
  final Widget Function(BuildContext context, T data) builder;
  final List<Object?> deps;
  final Widget? placeholder;

  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  T? _data;
  bool _has = false;
  int _rev = -1;
  List<Object?> _deps = const [];
  int _ticket = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  @override
  void didUpdateWidget(covariant Loader<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeLoad();
  }

  bool _sameDeps(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _maybeLoad() {
    final app = context.watch<AppState>();
    if (app.revision == _rev && _sameDeps(widget.deps, _deps)) return;
    _rev = app.revision;
    _deps = List.of(widget.deps);
    final ticket = ++_ticket;
    widget.load(app.repo).then((value) {
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _data = value;
        _has = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_has) {
      return widget.placeholder ??
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))),
          );
    }
    return widget.builder(context, _data as T);
  }
}

/// Bordered surface used for nearly every card in the app.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color, this.onTap, this.radius = kRadius, this.border = true});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: p.line) : null,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Pressable(onTap: onTap!, child: box);
  }
}

/// Subtle press-down scale for tappable cards.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.onLongPress, this.scale = 0.97});
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fades + slides children in on first build, staggered by [index].
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + math.min(index, 8) * 60),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.trailing});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 26, 4, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2))),
          ?trailing,
          if (action != null)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(action!, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: p.muted),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Vehicle type glyph inside a tinted rounded square.
class TypeBadge extends StatelessWidget {
  const TypeBadge(this.type, {super.key, this.size = 46});
  final VehicleType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: context.pal.isDark ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(type.icon, color: type.color, size: size * 0.52),
    );
  }
}

/// Coloured icon bubble for a ledger category.
class IconBubble extends StatelessWidget {
  const IconBubble(this.icon, this.color, {super.key, this.size = 42});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: context.pal.isDark ? 0.18 : 0.13), shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

const _avatarColors = [
  Color(0xFF4C7DFF), Color(0xFF22C17A), Color(0xFFFF8A3D), Color(0xFFA06BFF),
  Color(0xFFFF4F7B), Color(0xFF14B8C9), Color(0xFFE5B812),
];

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, required this.initials, this.size = 44});
  final String name;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = _avatarColors[name.codeUnits.fold<int>(0, (a, b) => a + b) % _avatarColors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c, Color.lerp(c, Colors.black, 0.25)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        shape: BoxShape.circle,
      ),
      child: Text(initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.36, height: 1.1)),
    );
  }
}

/// Bangladeshi number-plate styled chip: city line on top, number below,
/// with a vehicle-type colour band on the left.
class NumberPlate extends StatelessWidget {
  const NumberPlate({super.key, required this.regNo, this.color, this.scale = 1});
  final String? regNo;
  final Color? color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final reg = (regNo ?? '').trim();
    if (reg.isEmpty) return const SizedBox.shrink();
    final idx = reg.lastIndexOf(' ');
    final top = idx > 0 ? reg.substring(0, idx) : '';
    final bottom = idx > 0 ? reg.substring(idx + 1) : reg;
    const ink = Color(0xFF111317);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDF8),
        borderRadius: BorderRadius.circular(7 * scale),
        border: Border.all(color: ink, width: 1.4 * scale),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: IntrinsicHeight(
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (color != null)
            Container(
              width: 6 * scale,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(5 * scale)),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 3 * scale),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (top.isNotEmpty)
                Text(top, style: TextStyle(color: ink, fontSize: 9.5 * scale, fontWeight: FontWeight.w600, height: 1.15)),
              Text(bottom,
                  style: TextStyle(color: ink, fontSize: 14 * scale, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 0.6, fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Animated pill segmented control.
class PillToggle<T> extends StatelessWidget {
  const PillToggle({super.key, required this.values, required this.selected, required this.label, required this.onChanged, this.expand = true});

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final v in values)
            _wrap(
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == selected ? p.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: v == selected ? p.bg : p.muted,
                    ),
                    child: Text(label(v), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _wrap(Widget w) => expand ? Expanded(child: w) : w;
}

/// Small rounded chip used for selections (vehicles, categories…).
class ChoiceTag extends StatelessWidget {
  const ChoiceTag({super.key, required this.label, required this.selected, required this.onTap, this.icon, this.color});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = color ?? p.ink;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? p.ink : p.surface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: selected ? p.ink : p.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: selected ? (color != null ? Color.lerp(c, Colors.white, 0.25) : p.bg) : c),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: selected ? p.bg : p.ink)),
        ]),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.action});
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(alignment: Alignment.center, children: [
          Container(width: 96, height: 96, decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.35), shape: BoxShape.circle)),
          Transform.rotate(
            angle: -0.12,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, color: p.accent, size: 32),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (body != null) ...[
          const SizedBox(height: 6),
          Text(body!, textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
        ],
        if (action != null) ...[const SizedBox(height: 20), action!],
      ]),
    );
  }
}

/// Horizontal progress made of one segment per vehicle.
class SegmentBar extends StatelessWidget {
  const SegmentBar({super.key, required this.parts, this.height = 10, this.track});
  /// (fraction filled 0..1, colour)
  final List<(double, Color)> parts;
  final double height;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final t = track ?? context.pal.surfaceAlt;
    if (parts.isEmpty) {
      return Container(height: height, decoration: BoxDecoration(color: t, borderRadius: BorderRadius.circular(height)));
    }
    return Row(children: [
      for (var i = 0; i < parts.length; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: Stack(children: [
              Container(height: height, color: t),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: parts[i].$1.clamp(0, 1)),
                duration: Duration(milliseconds: 700 + i * 120),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(height: height, color: parts[i].$2),
                ),
              ),
            ]),
          ),
        ),
      ],
    ]);
  }
}

/// Simple smooth sparkline.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, required this.color, this.height = 48});
  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, t, _) => CustomPaint(painter: _SparkPainter(values, color, t)),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.t);
  final List<double> values;
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    // Running cumulative profit reads better than noisy daily values.
    final cum = <double>[];
    var acc = 0.0;
    for (final v in values) {
      acc += v;
      cum.add(acc);
    }
    final minV = cum.reduce(math.min);
    final maxV = cum.reduce(math.max);
    final range = (maxV - minV).abs() < 1 ? 1.0 : maxV - minV;
    final pts = <Offset>[
      for (var i = 0; i < cum.length; i++)
        Offset(size.width * i / (cum.length - 1), size.height - (cum[i] - minV) / range * size.height * 0.9 - size.height * 0.05),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      path.quadraticBezierTo(a.dx, a.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * t, size.height));
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
    if (t > 0.98) {
      canvas.drawCircle(pts.last, 4.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.t != t || old.values != values || old.color != color;
}

/// Decorative dashed "lane markings" for hero cards.
class LanePainter extends CustomPainter {
  LanePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(size.width * 0.72, -20);
    canvas.rotate(0.5);
    for (var lane = 0; lane < 3; lane++) {
      final x = lane * 26.0;
      for (var y = 0.0; y < size.height * 1.6; y += 22) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 10), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LanePainter old) => old.color != color;
}

/// Coloured pill with a short status text.
class StatusPill extends StatelessWidget {
  const StatusPill(this.text, this.color, {super.key, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }
}

/// Big number with a small label above — used in stat grids.
class StatBlock extends StatelessWidget {
  const StatBlock({super.key, required this.label, required this.value, this.color, this.icon, this.sub});
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[Icon(icon, size: 16, color: color ?? p.muted), const SizedBox(width: 6)],
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: color ?? p.ink, fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12)),
        ],
      ]),
    );
  }
}

/// Round icon button with a border — header actions.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, this.tooltip, this.filled = false});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final btn = Pressable(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: filled ? p.accent : p.surface,
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: p.line),
        ),
        child: Icon(icon, size: 22, color: filled ? p.onAccent : p.ink),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Constrains content width on tablets / web.
///
/// Takes only its child's height ([Align.heightFactor] = 1), so it is safe in
/// bottom bars and sheets; scrollables inside still fill the available space.
class Contained extends StatelessWidget {
  const Contained({super.key, required this.child, this.maxWidth = 1100});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// ‹ October 2026 › pill. Never moves past the current month.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key, required this.month, required this.onChanged});
  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    return Container(
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(40), border: Border.all(color: p.line)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(context.fmt.monthYear(month), style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: isCurrent ? null : () => onChanged(DateTime(month.year, month.month + 1)),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ]),
    );
  }
}

/// Horizontal "All · vehicle · vehicle…" chips.
class VehicleFilter extends StatelessWidget {
  const VehicleFilter({super.key, required this.selected, required this.onChanged});
  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        children: [
          ChoiceTag(label: context.s.all, selected: selected == null, onTap: () => onChanged(null)),
          for (final v in app.vehicles) ...[
            const SizedBox(width: 8),
            ChoiceTag(label: v.name, icon: v.type.icon, color: v.type.color, selected: selected == v.id, onTap: () => onChanged(v.id)),
          ],
        ],
      ),
    );
  }
}

/// Text field that suggests values typed before (garages, shops, clients) so
/// the same name is not spelled three different ways.
class SuggestField extends StatefulWidget {
  const SuggestField({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.label,
    this.hint,
    this.icon,
    this.onSelected,
    this.validator,
  });

  final TextEditingController controller;
  final List<String> suggestions;
  final String label;
  final String? hint;
  final IconData? icon;
  final ValueChanged<String>? onSelected;
  final FormFieldValidator<String>? validator;

  @override
  State<SuggestField> createState() => _SuggestFieldState();
}

class _SuggestFieldState extends State<SuggestField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focus,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<String>.empty();
        return widget.suggestions.where((s) => s.toLowerCase().contains(q) && s.toLowerCase() != q).take(6);
      },
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextFormField(
        controller: controller,
        focusNode: focus,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: widget.label, hintText: widget.hint, prefixIcon: widget.icon == null ? null : Icon(widget.icon)),
        validator: widget.validator,
        onFieldSubmitted: (_) => onSubmit(),
      ),
      optionsViewBuilder: (context, onSelect, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 6,
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260, maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.history_rounded, size: 18, color: p.muted),
                    title: Text(o, style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => onSelect(o),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two form fields side by side, stacked when the screen is too narrow for
/// their labels.
class FieldPair extends StatelessWidget {
  const FieldPair(this.first, this.second, {super.key, this.firstFlex = 1, this.secondFlex = 1});
  final Widget first;
  final Widget second;
  final int firstFlex;
  final int secondFlex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => c.maxWidth < 460
            ? Column(children: [first, const SizedBox(height: 12), second])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: firstFlex, child: first),
                const SizedBox(width: 10),
                Expanded(flex: secondFlex, child: second),
              ]),
      );
}

/// Small key/value column used in card footers.
class KeyValue extends StatelessWidget {
  const KeyValue(this.label, this.value, {super.key, this.color, this.end = false});
  final String label;
  final String value;
  final Color? color;
  final bool end;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.pal.muted, fontSize: 11.5)),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
      ]);
}

// ── Dialog / feedback helpers ─────────────────────────────────────────────

Future<bool> confirm(BuildContext context, {required String title, String? body, String? confirmLabel, bool danger = true}) async {
  final s = S.read(context);
  final p = context.pal;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: body == null ? null : Text(body),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger ? p.expense : p.ink, foregroundColor: Colors.white, minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? s.delete),
        ),
      ],
    ),
  );
  return ok ?? false;
}

void toast(BuildContext context, String message, {IconData icon = Icons.check_circle_rounded}) {
  final p = context.pal;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [Icon(icon, color: p.accent, size: 20), const SizedBox(width: 10), Expanded(child: Text(message))]),
      duration: const Duration(seconds: 2),
    ));
}

Future<DateTime?> pickDate(BuildContext context, DateTime initial, {DateTime? first, DateTime? last}) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(2000),
    lastDate: last ?? DateTime(2100),
  );
}

/// Parses user-entered numbers, accepting Bangla digits and commas.
double? parseAmount(String raw) {
  const bn = '০১২৩৪৫৬৭৮৯';
  final b = StringBuffer();
  for (final ch in raw.characters) {
    final i = bn.indexOf(ch);
    if (i >= 0) {
      b.write(i);
    } else if (ch != ',' && ch != ' ' && ch != '৳') {
      b.write(ch);
    }
  }
  final s = b.toString();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

/// Money text in the app's tabular style.
class Money extends StatelessWidget {
  const Money(this.value, {super.key, this.style, this.color, this.sign = false, this.compact = false});
  final double value;
  final TextStyle? style;
  final Color? color;
  final bool sign;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final f = context.fmt;
    return Text(
      compact ? f.compact(value) : f.money(value, sign: sign),
      maxLines: 1,
      style: (style ?? const TextStyle()).copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}
