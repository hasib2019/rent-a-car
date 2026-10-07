import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/l10n_auth.dart';
import '../../core/theme.dart';
import '../../services/auth.dart';

/// Shown when the admin forces an update (App settings → minimum version).
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = context.pal;
    final config = context.watch<AuthService>().config;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(30)),
                  child: Icon(Icons.system_update_rounded, size: 48, color: p.onAccent),
                ),
                const SizedBox(height: 24),
                Text(s.updateTitle, textAlign: TextAlign.center, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(s.updateBody, textAlign: TextAlign.center, style: TextStyle(color: p.muted, height: 1.4)),
                const SizedBox(height: 6),
                Text('v${config.latestVersion}', style: TextStyle(color: p.muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                if (config.updateUrl.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent),
                      onPressed: () => launchUrl(Uri.parse(config.updateUrl), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.download_rounded),
                      label: Text(s.updateNow),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
