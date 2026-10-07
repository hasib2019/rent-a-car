import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/repository.dart';
import 'services/settings.dart';
import 'state/app_state.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await Settings.load();
  final repo = await Repository.open();
  final app = AppState(repo);
  await app.refresh();
  runApp(GariKhataApp(settings: settings, app: app));
}

class GariKhataApp extends StatelessWidget {
  const GariKhataApp({super.key, required this.settings, required this.app});
  final Settings settings;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: app),
      ],
      child: Consumer<Settings>(
        builder: (context, settings, _) => MaterialApp(
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
          home: settings.onboarded ? const AppShell() : const OnboardingScreen(),
        ),
      ),
    );
  }
}
