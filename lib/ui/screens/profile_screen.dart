import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n_auth.dart';
import '../../core/theme.dart';
import '../../services/api.dart';
import '../../services/auth.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'auth_screens.dart';

/// The signed-in owner's account.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    final auth = context.watch<AuthService>();
    final user = auth.user;
    if (user == null) return const Scaffold();

    Widget row(IconData icon, String label, String? value) => ListTile(
          leading: Icon(icon, color: p.muted),
          title: Text(label, style: TextStyle(color: p.muted, fontSize: 13)),
          subtitle: Text(value == null || value.isEmpty ? '—' : value, style: TextStyle(color: p.ink, fontWeight: FontWeight.w600, fontSize: 15.5)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(s.myAccount)),
      body: Contained(
        maxWidth: 640,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
          Entrance(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(28)),
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: LanePainter(p.onHero.withValues(alpha: 0.06)))),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(children: [
                    Avatar(name: user.name, initials: user.name.isEmpty ? '?' : user.name.characters.first.toUpperCase(), size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(user.name, style: TextStyle(color: p.onHero, fontSize: 22, fontWeight: FontWeight.w800)),
                        Text('@${user.username}', style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
                        if ((user.businessName ?? '').isNotEmpty)
                          Text(user.businessName!, style: TextStyle(color: p.onHero.withValues(alpha: 0.65))),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Panel(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              row(Icons.mail_outline_rounded, s.email, user.email),
              row(Icons.phone_iphone_rounded, s.mobile, context.fmt.digits(user.phone)),
              row(Icons.place_outlined, s.district, districtLabel(s, user.district)),
              row(Icons.directions_car_outlined, s.fleetSize, user.fleetSize == null ? null : context.fmt.digits(user.fleetSize!)),
            ]),
          ),
          const SizedBox(height: 14),
          Panel(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              _action(context, Icons.edit_rounded, p.info, s.editProfile, () => _editProfile(context, user)),
              Divider(indent: 70, color: p.line),
              _action(context, Icons.password_rounded, p.warning, s.changePassword, () => _changePassword(context)),
              Divider(indent: 70, color: p.line),
              _action(context, Icons.logout_rounded, p.muted, s.logout, () => _logout(context)),
            ]),
          ),
          const SizedBox(height: 28),
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: p.expense),
              onPressed: () => _deleteAccount(context),
              icon: const Icon(Icons.delete_forever_rounded),
              label: Text(s.deleteAccount),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, Color color, String title, VoidCallback onTap) => ListTile(
        onTap: onTap,
        leading: IconBubble(icon, color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded),
      );

  Future<void> _logout(BuildContext context) async {
    final s = context.s;
    if (!await confirm(context, title: s.logoutConfirm, body: s.logoutBody, confirmLabel: s.logout, danger: false)) return;
    if (!context.mounted) return;
    final nav = Navigator.of(context);
    await context.read<AuthService>().logout();
    nav.popUntil((r) => r.isFirst);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final s = context.s;
    final password = await _askPassword(context, title: s.deleteAccount, body: s.deleteAccountBody, confirmLabel: s.delete);
    if (password == null || !context.mounted) return;
    final auth = context.read<AuthService>();
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.deleteAccount(password);
      await app.mutate((r) => r.eraseEverything());
      nav.popUntil((r) => r.isFirst);
      messenger.showSnackBar(SnackBar(content: Text(s.accountDeleted)));
    } on ApiException catch (e) {
      if (context.mounted) toast(context, e.isOffline ? s.offline : (e.field('password') ?? e.message), icon: Icons.error_outline_rounded);
    }
  }

  Future<String?> _askPassword(BuildContext context, {required String title, required String body, required String confirmLabel}) {
    final ctl = TextEditingController();
    final s = context.s;
    final p = context.pal;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(body),
          const SizedBox(height: 16),
          TextField(controller: ctl, obscureText: true, autofocus: true, decoration: InputDecoration(labelText: s.password)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: p.expense, foregroundColor: Colors.white, minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, ctl.text.isEmpty ? null : ctl.text),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, AppUser user) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _EditProfileSheet(user: user),
      );

  Future<void> _changePassword(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _ChangePasswordSheet(),
      );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Contained(
          maxWidth: 560,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(title, style: context.text.titleLarge),
              const SizedBox(height: 16),
              ...children,
            ]),
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});
  final AppUser user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _username = TextEditingController(text: widget.user.username);
  late final _email = TextEditingController(text: widget.user.email);
  late final _phone = TextEditingController(text: widget.user.phone);
  late final _business = TextEditingController(text: widget.user.businessName);
  late final _fleet = TextEditingController(text: widget.user.fleetSize?.toString());
  late String? _district = widget.user.district;
  Map<String, String> _errors = {};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _username, _email, _phone, _business, _fleet]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _errors = {};
    });
    final s = context.s;
    try {
      await context.read<AuthService>().updateProfile({
        'name': _name.text.trim(),
        'username': _username.text.trim().toLowerCase(),
        'email': _email.text.trim().toLowerCase(),
        'phone': normalizePhone(_phone.text),
        'business_name': _business.text.trim().isEmpty ? null : _business.text.trim(),
        'district': _district,
        'fleet_size': int.tryParse(toLatinDigits(_fleet.text)),
      });
      if (!mounted) return;
      toast(context, s.saved);
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.fieldErrors);
      if (e.fieldErrors.isEmpty) toast(context, e.isOffline ? s.offline : e.message, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    const gap = SizedBox(height: 12);
    return _SheetFrame(title: s.editProfile, children: [
      TextField(controller: _name, decoration: InputDecoration(labelText: s.fullName, errorText: _errors['name'])),
      gap,
      TextField(
        controller: _username,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]'))],
        decoration: InputDecoration(labelText: s.username, prefixText: '@ ', errorText: _errors['username']),
      ),
      gap,
      TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: s.email, errorText: _errors['email'])),
      gap,
      TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: s.mobile, errorText: _errors['phone'])),
      gap,
      TextField(controller: _business, decoration: InputDecoration(labelText: s.businessName, errorText: _errors['business_name'])),
      gap,
      Row(children: [
        Expanded(flex: 3, child: DistrictField(value: _district, errorText: _errors['district'], onChanged: (d) => setState(() => _district = d))),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: TextField(controller: _fleet, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: s.fleetSize))),
      ]),
      const SizedBox(height: 20),
      FilledButton(onPressed: _busy ? null : _save, child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(s.save)),
    ]);
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  Map<String, String> _errors = {};
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.s;
    if (_next.text != _confirm.text) {
      setState(() => _errors = {'password_confirmation': s.passwordsDontMatch});
      return;
    }
    setState(() {
      _busy = true;
      _errors = {};
    });
    try {
      await context.read<AuthService>().changePassword(_current.text, _next.text);
      if (!mounted) return;
      toast(context, s.passwordChanged);
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.fieldErrors);
      if (e.fieldErrors.isEmpty) toast(context, e.isOffline ? s.offline : e.message, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    const gap = SizedBox(height: 12);
    return _SheetFrame(title: s.changePassword, children: [
      TextField(controller: _current, obscureText: true, decoration: InputDecoration(labelText: s.currentPassword, errorText: _errors['current_password'])),
      gap,
      TextField(controller: _next, obscureText: true, decoration: InputDecoration(labelText: s.newPassword, helperText: s.passwordHint, errorText: _errors['password'])),
      gap,
      TextField(controller: _confirm, obscureText: true, decoration: InputDecoration(labelText: s.confirmPassword, errorText: _errors['password_confirmation'])),
      const SizedBox(height: 20),
      FilledButton(onPressed: _busy ? null : _save, child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(s.save)),
    ]);
  }
}
