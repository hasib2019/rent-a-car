import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/l10n_auth.dart';
import '../../core/theme.dart';
import '../../services/auth.dart';
import 'common.dart';

/// True when the signed-in account may use [feature]; otherwise explains
/// that it's locked (without mentioning packages) and returns false.
Future<bool> requireFeature(BuildContext context, String feature) async {
  if (context.read<AuthService>().access.can(feature)) return true;
  await showLockedSheet(context);
  return false;
}

/// Checks the vehicle limit before adding a new vehicle.
Future<bool> requireVehicleSlot(BuildContext context, int currentCount) async {
  final access = context.read<AuthService>().access;
  if (access.canAddVehicle(currentCount)) return true;
  await showLockedSheet(context, message: context.s.vehicleLimit(access.maxVehicles!));
  return false;
}

Future<bool> requireDriverSlot(BuildContext context, int currentCount) async {
  final access = context.read<AuthService>().access;
  if (access.canAddDriver(currentCount)) return true;
  await showLockedSheet(context, message: context.s.driverLimit(access.maxDrivers!));
  return false;
}

Future<void> showLockedSheet(BuildContext context, {String? title, String? message}) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) {
      final s = ctx.s;
      final p = ctx.pal;
      final config = ctx.read<AuthService>().config;
      return SafeArea(
        child: Contained(
          maxWidth: 520,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Stack(alignment: Alignment.center, children: [
                Container(width: 92, height: 92, decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.3), shape: BoxShape.circle)),
                Transform.rotate(
                  angle: -0.12,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(20)),
                    child: Icon(Icons.lock_rounded, color: p.accent, size: 30),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              Text(title ?? s.lockedTitle, textAlign: TextAlign.center, style: ctx.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(message ?? s.lockedBody, textAlign: TextAlign.center, style: TextStyle(color: p.muted, height: 1.4)),
              const SizedBox(height: 20),
              if (config.supportPhone.isNotEmpty || config.supportWhatsapp.isNotEmpty)
                Row(children: [
                  if (config.supportPhone.isNotEmpty)
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent),
                        onPressed: () => launchUrl(Uri(scheme: 'tel', path: config.supportPhone)),
                        icon: const Icon(Icons.call_rounded),
                        label: Text(s.contactSupport),
                      ),
                    ),
                  if (config.supportPhone.isNotEmpty && config.supportWhatsapp.isNotEmpty) const SizedBox(width: 10),
                  if (config.supportWhatsapp.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse('https://wa.me/88${config.supportWhatsapp.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^88'), '')}'),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.chat_rounded),
                        label: Text(s.whatsapp),
                      ),
                    ),
                ]),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.close))),
            ]),
          ),
        ),
      );
    },
  );
}
