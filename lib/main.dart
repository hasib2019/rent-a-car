import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/repository.dart';
import 'services/access.dart';
import 'services/analytics.dart';
import 'services/auth.dart';
import 'services/settings.dart';
import 'state/app_state.dart';
import 'ui/screens/auth_screens.dart';
import 'ui/screens/mode_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/update_screen.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await Settings.load();
  final auth = await AuthService.load(language: () => settings.isBangla ? 'bn' : 'en');
  await Analytics.instance.init(auth);
  final books = AppBooks(fleet: AppState(await Repository.open()), personal: AppState(await Repository.open(personal: true), personal: true));
  await Future.wait([for (final b in books.all) b.refresh()]);

  // Keep the owner's name on the dashboard in sync with the account.
  void syncProfile() {
    final user = auth.user;
    if (user == null) return;
    if (settings.ownerName != user.name) settings.setOwnerName(user.name);
    if (settings.businessName != (user.businessName ?? '')) settings.setBusinessName(user.businessName ?? '');
  }

  auth.addListener(syncProfile);
  syncProfile();
  unawaited(auth.refresh());

  runApp(GariKhataApp(settings: settings, books: books, auth: auth));
}

/// The mode to show, or null while the owner hasn't picked one. Personal mode
/// falls back to the fleet books when the account may not use it.
AppMode? activeMode(Settings settings, AuthService auth) {
  final mode = settings.appMode;
  if (mode == AppMode.personal && !auth.access.can(Feature.personalMode)) return AppMode.fleet;
  return mode;
}

class GariKhataApp extends StatelessWidget {
  const GariKhataApp({super.key, required this.settings, required this.books, required this.auth});
  final Settings settings;
  final AppBooks books;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: auth),
        Provider.value(value: books),
      ],
      child: Consumer2<Settings, AuthService>(
        builder: (context, settings, auth, _) {
          final mode = activeMode(settings, auth);
          // Above MaterialApp, so pushed pages read the active books too.
          return ChangeNotifierProvider.value(
            value: books.of(mode ?? AppMode.fleet),
            child: MaterialApp(
              title: 'GariKhata',
              debugShowCheckedModeBanner: false,
              theme: buildTheme(Palette.light),
              darkTheme: buildTheme(Palette.dark),
              themeMode: settings.themeMode,
              locale: Locale(settings.isBangla ? 'bn' : 'en'),
              supportedLocales: const [Locale('bn'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) {
                final dark = Theme.of(context).brightness == Brightness.dark;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent),
                  child: child!,
                );
              },
              home: switch ((settings.onboarded, auth.mustUpdate, auth.loggedIn, mode)) {
                (false, _, _, _) => const OnboardingScreen(),
                (_, true, _, _) => const UpdateScreen(),
                (_, _, false, _) => const AuthScreen(),
                (_, _, _, null) => const ModeScreen(),
                (_, _, _, final m?) => AppShell(key: ValueKey(m)),
              },
            ),
          );
        },
      ),
    );
  }
}
