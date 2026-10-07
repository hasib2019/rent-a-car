import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/l10n_auth.dart';
import '../../core/theme.dart';
import '../../services/analytics.dart';
import '../../services/api.dart';
import '../../services/auth.dart';
import '../../services/settings.dart';
import '../routes.dart';
import '../widgets/common.dart';

enum _Mode { login, register }

/// First screen for signed-out users: log in or create an account.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _Mode _mode = _Mode.login;

  @override
  void initState() {
    super.initState();
    Analytics.instance.screen('login');
    WidgetsBinding.instance.addPostFrameCallback((_) => _explainSignOut());
  }

  /// Tells the user why they're here if the server signed them out.
  void _explainSignOut() {
    final auth = context.read<AuthService>();
    final reason = auth.signedOutReason;
    if (reason == null || !mounted) return;
    auth.signedOutReason = null;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.s.signedOutTitle),
        content: Text(reason),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.s.close))],
      ),
    );
  }

  void _switch(_Mode m) {
    setState(() => _mode = m);
    Analytics.instance.screen(m == _Mode.login ? 'login' : 'register');
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final s = context.s;
    final form = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
      child: _mode == _Mode.login
          ? _LoginForm(key: const ValueKey('login'), onRegister: () => _switch(_Mode.register))
          : _RegisterForm(key: const ValueKey('register'), onLogin: () => _switch(_Mode.login)),
    );
    final toggle = PillToggle<_Mode>(
      values: _Mode.values,
      selected: _mode,
      label: (m) => m == _Mode.login ? s.loginTab : s.registerTab,
      onChanged: _switch,
    );

    if (wide) {
      return Scaffold(
        body: Row(children: [
          Expanded(flex: 5, child: Padding(padding: const EdgeInsets.all(16), child: _Hero(mode: _mode, tall: true))),
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Align(alignment: Alignment.centerRight, child: _LangToggle()),
                    const SizedBox(height: 24),
                    toggle,
                    const SizedBox(height: 24),
                    form,
                  ]),
                ),
              ),
            ),
          ),
        ]),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const _Logo(),
              const SizedBox(width: 10),
              Text(s.appName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const Spacer(),
              const _LangToggle(),
            ]),
            const SizedBox(height: 16),
            _Hero(mode: _mode),
            const SizedBox(height: 18),
            toggle,
            const SizedBox(height: 18),
            form,
          ]),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.menu_book_rounded, color: p.onAccent, size: 20),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    return SizedBox(
      width: 160,
      child: PillToggle<bool>(values: const [true, false], selected: settings.isBangla, label: (v) => v ? 'বাংলা' : 'English', onChanged: settings.setBangla),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.mode, this.tall = false});
  final _Mode mode;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    return Container(
      clipBehavior: Clip.antiAlias,
      constraints: tall ? const BoxConstraints.expand() : null,
      decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: LanePainter(p.onHero.withValues(alpha: 0.06)))),
        Positioned(
          right: -50,
          top: -50,
          child: Container(width: 180, height: 180, decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.16), shape: BoxShape.circle)),
        ),
        Padding(
          padding: EdgeInsets.all(tall ? 48 : 22),
          child: Column(
            mainAxisAlignment: tall ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tall) ...[const _Logo(), const Spacer()],
              Row(children: [
                for (final (i, t) in [VehicleType.cng, VehicleType.car, VehicleType.pickup].indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Transform.rotate(
                      angle: (i - 1) * 0.1,
                      child: Container(
                        width: tall ? 64 : 44,
                        height: tall ? 64 : 44,
                        decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(tall ? 20 : 14)),
                        child: Icon(t.icon, color: Colors.white, size: tall ? 34 : 24),
                      ),
                    ),
                  ),
              ]),
              SizedBox(height: tall ? 28 : 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  mode == _Mode.login ? s.welcomeBack : s.createAccount,
                  key: ValueKey(mode),
                  style: TextStyle(color: p.onHero, fontWeight: FontWeight.w800, fontSize: tall ? 44 : 28, letterSpacing: -0.8, height: 1.1),
                ),
              ),
              const SizedBox(height: 8),
              Text(s.authTagline, style: TextStyle(color: p.onHero.withValues(alpha: 0.7), height: 1.4, fontSize: tall ? 17 : 14)),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Inline red banner for errors that don't belong to one field.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.expense.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: p.expense),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(color: p.expense, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

String _messageFor(BuildContext context, ApiException e) {
  if (e.isOffline) return context.s.offline;
  return e.message;
}

Widget _primaryButton(BuildContext context, {required String label, required bool busy, required VoidCallback onPressed}) {
  final p = context.pal;
  return SizedBox(
    height: 58,
    child: FilledButton(
      style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      onPressed: busy ? null : onPressed,
      child: busy
          ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onAccent))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded),
            ]),
    ),
  );
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.controller, required this.label, this.errorText, this.validator, this.helperText, this.onSubmitted, this.action = TextInputAction.next});
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction action;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      validator: widget.validator,
      textInputAction: widget.action,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

// ── Login ───────────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm({super.key, required this.onRegister});
  final VoidCallback onRegister;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = {};
    });
    try {
      await context.read<AuthService>().login(_login.text, _password.text);
      TextInput.finishAutofillContext();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? _messageFor(context, e) : null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    return AutofillGroup(
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_error != null) _ErrorBanner(_error!),
          TextFormField(
            controller: _login,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            decoration: InputDecoration(labelText: s.loginField, prefixIcon: const Icon(Icons.person_outline_rounded), errorText: _fieldErrors['login']),
            validator: (v) => (v == null || v.trim().isEmpty) ? s.required : null,
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _password,
            label: s.password,
            errorText: _fieldErrors['password'],
            action: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (v) => (v == null || v.isEmpty) ? s.required : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(AppRoute(builder: (_) => ForgotPasswordScreen(initialEmail: _login.text.contains('@') ? _login.text.trim() : null))),
              child: Text(s.forgotPassword, style: TextStyle(color: p.muted)),
            ),
          ),
          const SizedBox(height: 6),
          _primaryButton(context, label: s.loginButton, busy: _busy, onPressed: _submit),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s.noAccount, style: TextStyle(color: p.muted)),
            TextButton(onPressed: widget.onRegister, child: Text(s.registerTab, style: const TextStyle(fontWeight: FontWeight.w800))),
          ]),
        ]),
      ),
    );
  }
}

// ── Register ────────────────────────────────────────────────────────────────

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _usernameRe = RegExp(r'^[a-z0-9_.]{3,30}$');

/// Accepts 01XXXXXXXXX, +8801…, 8801… and Bangla digits.
String normalizePhone(String raw) {
  var d = toLatinDigits(raw).replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('880')) d = d.substring(2);
  return d;
}

String toLatinDigits(String s) {
  const bn = '০১২৩৪৫৬৭৮৯';
  final b = StringBuffer();
  for (final ch in s.characters) {
    final i = bn.indexOf(ch);
    b.write(i >= 0 ? '$i' : ch);
  }
  return b.toString();
}

bool _strongPassword(String v) => v.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(v) && RegExp(r'\d').hasMatch(v);

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({super.key, required this.onLogin});
  final VoidCallback onLogin;

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _business = TextEditingController();
  final _fleet = TextEditingController();
  String? _district;
  bool _showBusiness = false;
  bool _busy = false;
  bool _usernameEdited = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    // Suggest a username from the name until the user types their own.
    _name.addListener(() {
      if (_usernameEdited) return;
      final base = _name.text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      _username.text = base.length > 20 ? base.substring(0, 20) : base;
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _username, _email, _phone, _password, _confirm, _business, _fleet]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.s;
    final auth = context.read<AuthService>();
    if (!auth.config.registrationOpen) {
      setState(() => _error = s.registrationClosed);
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = {};
    });
    try {
      await auth.register({
        'name': _name.text.trim(),
        'username': _username.text.trim().toLowerCase(),
        'email': _email.text.trim().toLowerCase(),
        'phone': normalizePhone(_phone.text),
        'password': _password.text,
        'password_confirmation': _confirm.text,
        if (_business.text.trim().isNotEmpty) 'business_name': _business.text.trim(),
        if (_district != null) 'district': _district,
        if (int.tryParse(toLatinDigits(_fleet.text)) != null) 'fleet_size': int.parse(toLatinDigits(_fleet.text)),
      });
      TextInput.finishAutofillContext();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? _messageFor(context, e) : null;
        if (e.fieldErrors.keys.any((k) => k == 'business_name' || k == 'district' || k == 'fleet_size')) _showBusiness = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    const gap = SizedBox(height: 12);
    return AutofillGroup(
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_error != null) _ErrorBanner(_error!),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: InputDecoration(labelText: s.fullName, prefixIcon: const Icon(Icons.badge_outlined), errorText: _fieldErrors['name']),
            validator: (v) => (v == null || v.trim().length < 2) ? s.required : null,
          ),
          gap,
          TextFormField(
            controller: _username,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.]')), _LowerCase()],
            onChanged: (_) => _usernameEdited = true,
            autofillHints: const [AutofillHints.newUsername],
            decoration: InputDecoration(labelText: s.username, prefixText: '@ ', helperText: s.usernameHint, prefixIcon: const Icon(Icons.alternate_email_rounded), errorText: _fieldErrors['username']),
            validator: (v) => _usernameRe.hasMatch((v ?? '').trim()) ? null : s.invalidUsername,
          ),
          gap,
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: '${s.email} *', prefixIcon: const Icon(Icons.mail_outline_rounded), errorText: _fieldErrors['email']),
            validator: (v) => _emailRe.hasMatch((v ?? '').trim()) ? null : s.invalidEmail,
          ),
          gap,
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(labelText: '${s.mobile} *', hintText: '01XXXXXXXXX', prefixIcon: const Icon(Icons.phone_iphone_rounded), errorText: _fieldErrors['phone']),
            validator: (v) => RegExp(r'^01[3-9]\d{8}$').hasMatch(normalizePhone(v ?? '')) ? null : s.invalidPhone,
          ),
          gap,
          _PasswordField(
            controller: _password,
            label: s.password,
            helperText: s.passwordHint,
            errorText: _fieldErrors['password'],
            validator: (v) => _strongPassword(v ?? '') ? null : s.weakPassword,
          ),
          gap,
          _PasswordField(
            controller: _confirm,
            label: s.confirmPassword,
            validator: (v) => v == _password.text ? null : s.passwordsDontMatch,
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _showBusiness = !_showBusiness),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(children: [
                Icon(Icons.storefront_rounded, color: p.muted),
                const SizedBox(width: 10),
                Expanded(child: Text(s.businessInfo, style: const TextStyle(fontWeight: FontWeight.w700))),
                AnimatedRotation(turns: _showBusiness ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.expand_more_rounded)),
              ]),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _showBusiness ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(children: [
              const SizedBox(height: 4),
              TextFormField(
                controller: _business,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: s.businessName, prefixIcon: const Icon(Icons.store_outlined), errorText: _fieldErrors['business_name']),
              ),
              gap,
              Row(children: [
                Expanded(
                  flex: 3,
                  child: DistrictField(value: _district, errorText: _fieldErrors['district'], onChanged: (d) => setState(() => _district = d)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _fleet,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.fleetSize, prefixIcon: const Icon(Icons.directions_car_outlined), errorText: _fieldErrors['fleet_size']),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          _primaryButton(context, label: s.registerButton, busy: _busy, onPressed: _submit),
          const SizedBox(height: 12),
          Text(s.termsNote, textAlign: TextAlign.center, style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s.haveAccount, style: TextStyle(color: p.muted)),
            TextButton(onPressed: widget.onLogin, child: Text(s.loginTab, style: const TextStyle(fontWeight: FontWeight.w800))),
          ]),
        ]),
      ),
    );
  }
}

class _LowerCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}

/// Bangladesh's 64 districts (English value, Bangla label).
const kDistricts = <(String, String)>[
  ('Bagerhat', 'বাগেরহাট'), ('Bandarban', 'বান্দরবান'), ('Barguna', 'বরগুনা'), ('Barishal', 'বরিশাল'),
  ('Bhola', 'ভোলা'), ('Bogura', 'বগুড়া'), ('Brahmanbaria', 'ব্রাহ্মণবাড়িয়া'), ('Chandpur', 'চাঁদপুর'),
  ('Chapainawabganj', 'চাঁপাইনবাবগঞ্জ'), ('Chattogram', 'চট্টগ্রাম'), ('Chuadanga', 'চুয়াডাঙ্গা'), ("Cox's Bazar", 'কক্সবাজার'),
  ('Cumilla', 'কুমিল্লা'), ('Dhaka', 'ঢাকা'), ('Dinajpur', 'দিনাজপুর'), ('Faridpur', 'ফরিদপুর'),
  ('Feni', 'ফেনী'), ('Gaibandha', 'গাইবান্ধা'), ('Gazipur', 'গাজীপুর'), ('Gopalganj', 'গোপালগঞ্জ'),
  ('Habiganj', 'হবিগঞ্জ'), ('Jamalpur', 'জামালপুর'), ('Jashore', 'যশোর'), ('Jhalokati', 'ঝালকাঠি'),
  ('Jhenaidah', 'ঝিনাইদহ'), ('Joypurhat', 'জয়পুরহাট'), ('Khagrachhari', 'খাগড়াছড়ি'), ('Khulna', 'খুলনা'),
  ('Kishoreganj', 'কিশোরগঞ্জ'), ('Kurigram', 'কুড়িগ্রাম'), ('Kushtia', 'কুষ্টিয়া'), ('Lakshmipur', 'লক্ষ্মীপুর'),
  ('Lalmonirhat', 'লালমনিরহাট'), ('Madaripur', 'মাদারীপুর'), ('Magura', 'মাগুরা'), ('Manikganj', 'মানিকগঞ্জ'),
  ('Meherpur', 'মেহেরপুর'), ('Moulvibazar', 'মৌলভীবাজার'), ('Munshiganj', 'মুন্সীগঞ্জ'), ('Mymensingh', 'ময়মনসিংহ'),
  ('Naogaon', 'নওগাঁ'), ('Narail', 'নড়াইল'), ('Narayanganj', 'নারায়ণগঞ্জ'), ('Narsingdi', 'নরসিংদী'),
  ('Natore', 'নাটোর'), ('Netrokona', 'নেত্রকোনা'), ('Nilphamari', 'নীলফামারী'), ('Noakhali', 'নোয়াখালী'),
  ('Pabna', 'পাবনা'), ('Panchagarh', 'পঞ্চগড়'), ('Patuakhali', 'পটুয়াখালী'), ('Pirojpur', 'পিরোজপুর'),
  ('Rajbari', 'রাজবাড়ী'), ('Rajshahi', 'রাজশাহী'), ('Rangamati', 'রাঙ্গামাটি'), ('Rangpur', 'রংপুর'),
  ('Satkhira', 'সাতক্ষীরা'), ('Shariatpur', 'শরীয়তপুর'), ('Sherpur', 'শেরপুর'), ('Sirajganj', 'সিরাজগঞ্জ'),
  ('Sunamganj', 'সুনামগঞ্জ'), ('Sylhet', 'সিলেট'), ('Tangail', 'টাঙ্গাইল'), ('Thakurgaon', 'ঠাকুরগাঁও'),
];

String districtLabel(S s, String? value) {
  if (value == null) return '';
  for (final d in kDistricts) {
    if (d.$1 == value) return s.bn ? d.$2 : d.$1;
  }
  return value;
}

/// Tap-to-pick field with a searchable sheet.
class DistrictField extends StatelessWidget {
  const DistrictField({super.key, required this.value, required this.onChanged, this.errorText});
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _DistrictSheet(),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _pick(context),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(labelText: s.district, prefixIcon: const Icon(Icons.place_outlined), errorText: errorText, suffixIcon: const Icon(Icons.unfold_more_rounded)),
        child: Text(districtLabel(s, value), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _DistrictSheet extends StatefulWidget {
  const _DistrictSheet();

  @override
  State<_DistrictSheet> createState() => _DistrictSheetState();
}

class _DistrictSheetState extends State<_DistrictSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final q = _q.toLowerCase();
    final list = kDistricts.where((d) => q.isEmpty || d.$1.toLowerCase().contains(q) || d.$2.contains(_q)).toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v.trim()),
                decoration: InputDecoration(hintText: s.district, prefixIcon: const Icon(Icons.search_rounded), isDense: true),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(s.bn ? list[i].$2 : list[i].$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(s.bn ? list[i].$1 : list[i].$2),
                  onTap: () => Navigator.pop(context, list[i].$1),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Forgot password ─────────────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});
  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  String? _info;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = {};
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? _messageFor(context, e) : null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
        final msg = await context.read<AuthService>().forgotPassword(_email.text);
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _info = msg;
        });
      });

  Future<void> _reset() => _run(() async {
        final auth = context.read<AuthService>();
        final msg = await auth.resetPassword(email: _email.text, code: toLatinDigits(_code.text), password: _password.text);
        if (!mounted) return;
        toast(context, msg);
        Navigator.pop(context);
      });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    return Scaffold(
      appBar: AppBar(title: Text(s.resetTitle)),
      body: Contained(
        maxWidth: 480,
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(26)),
              child: Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(16)),
                  child: Icon(_codeSent ? Icons.mark_email_read_rounded : Icons.key_rounded, color: p.onAccent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(_codeSent ? s.resetStep2(_email.text.trim()) : s.resetStep1, style: TextStyle(color: p.onHero, height: 1.4, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            if (_error != null) _ErrorBanner(_error!),
            TextFormField(
              controller: _email,
              enabled: !_codeSent,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: s.email, prefixIcon: const Icon(Icons.mail_outline_rounded), errorText: _fieldErrors['email']),
              validator: (v) => _emailRe.hasMatch((v ?? '').trim()) ? null : s.invalidEmail,
            ),
            if (_codeSent) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 12),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯]'))],
                decoration: InputDecoration(labelText: s.code, counterText: '', errorText: _fieldErrors['code']),
                validator: (v) => toLatinDigits(v ?? '').length == 6 ? null : s.required,
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _password,
                label: s.newPassword,
                helperText: s.passwordHint,
                errorText: _fieldErrors['password'],
                validator: (v) => _strongPassword(v ?? '') ? null : s.weakPassword,
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _confirm,
                label: s.confirmPassword,
                action: TextInputAction.done,
                onSubmitted: (_) => _reset(),
                validator: (v) => v == _password.text ? null : s.passwordsDontMatch,
              ),
              if (_info != null)
                Padding(padding: const EdgeInsets.only(top: 10), child: Text(_info!, style: TextStyle(color: p.muted, fontSize: 13))),
            ],
            const SizedBox(height: 20),
            _primaryButton(context, label: _codeSent ? s.setPassword : s.sendCode, busy: _busy, onPressed: _codeSent ? _reset : _send),
            if (_codeSent)
              TextButton(
                onPressed: _busy ? null : () => setState(() => _codeSent = false),
                child: Text(s.resendCode),
              ),
          ]),
        ),
      ),
    );
  }
}
