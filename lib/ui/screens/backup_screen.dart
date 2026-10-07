import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../services/drive_backup.dart';
import '../../services/local_backup.dart';
import '../../services/settings.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

/// Google Drive (app-private folder) and local-file backup of the SQLite DB.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _drive = DriveBackup.instance;
  String? _busy;

  Future<void> _run(String key, Future<void> Function() action) async {
    if (_busy != null) return;
    setState(() => _busy = key);
    try {
      await action();
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      final s = context.s;
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      toast(context, e.code == GoogleSignInExceptionCode.clientConfigurationError ? s.driveNotConfigured : s.somethingWrong(e.description ?? e.code.name),
          icon: Icons.error_outline_rounded);
    } catch (e) {
      if (mounted) toast(context, context.s.somethingWrong(e), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _connect() => _run('connect', () async {
        final settings = context.read<Settings>();
        if (!await _drive.connect()) return;
        final email = await _drive.accountEmail();
        await settings.setDriveEmail(email ?? 'Google Drive');
      });

  Future<void> _disconnect() => _run('disconnect', () async {
        final settings = context.read<Settings>();
        await _drive.disconnect();
        await settings.setDriveEmail(null);
        await settings.setAutoBackup(false);
      });

  Future<void> _backupDrive() => _run('backup', () async {
        final app = context.read<AppState>();
        final settings = context.read<Settings>();
        final s = context.s;
        final bytes = await app.repo.exportBytes();
        final at = await _drive.upload(bytes);
        await settings.setLastBackup(at);
        if (mounted) toast(context, s.backupDone, icon: Icons.cloud_done_rounded);
      });

  Future<void> _restoreDrive() => _run('restore', () async {
        final s = context.s;
        final f = Fmt.read(context);
        final files = await _drive.list();
        if (!mounted) return;
        if (files.isEmpty) {
          toast(context, s.noDriveBackups, icon: Icons.cloud_off_rounded);
          return;
        }
        final chosen = await showModalBottomSheet<String>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text(s.chooseBackup, style: ctx.text.titleMedium)),
              Flexible(
                child: ListView(shrinkWrap: true, children: [
                  for (final file in files)
                    ListTile(
                      leading: const Icon(Icons.cloud_download_rounded),
                      title: Text(file.createdTime == null
                          ? (file.name ?? '')
                          : '${f.date(file.createdTime!.toLocal())} · ${f.digits('${file.createdTime!.toLocal().hour.toString().padLeft(2, '0')}:${file.createdTime!.toLocal().minute.toString().padLeft(2, '0')}')}'),
                      subtitle: Text('${f.number((int.tryParse(file.size ?? '') ?? 0) / 1024, decimals: 0)} KB'),
                      onTap: () => Navigator.pop(ctx, file.id),
                    ),
                ]),
              ),
            ]),
          ),
        );
        if (chosen == null || !mounted) return;
        if (!await confirm(context, title: s.restore, body: s.restoreConfirm, confirmLabel: s.restore)) return;
        final bytes = await _drive.download(chosen);
        await _restoreBytes(bytes);
      });

  Future<void> _export() => _run('export', () async {
        final app = context.read<AppState>();
        final s = context.s;
        final bytes = await app.repo.exportBytes();
        if (await LocalBackup.save(bytes) && mounted) toast(context, s.backupDone);
      });

  Future<void> _import() => _run('import', () async {
        final s = context.s;
        final bytes = await LocalBackup.open();
        if (bytes == null || !mounted) return;
        if (!await confirm(context, title: s.restore, body: s.restoreConfirm, confirmLabel: s.restore)) return;
        await _restoreBytes(bytes);
      });

  Future<void> _restoreBytes(Uint8List bytes) async {
    final app = context.read<AppState>();
    final s = context.s;
    try {
      await app.mutate((r) => r.importBytes(bytes));
      if (mounted) toast(context, s.restoreDone, icon: Icons.restore_rounded);
    } on FormatException {
      if (mounted) toast(context, s.invalidBackup, icon: Icons.error_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final settings = context.watch<Settings>();
    final connected = settings.driveEmail != null;

    return Scaffold(
      appBar: AppBar(title: Text(s.backupRestore)),
      body: Contained(
        maxWidth: 680,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // ── Google Drive ──
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: p.hero, borderRadius: BorderRadius.circular(30)),
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: LanePainter(p.onHero.withValues(alpha: 0.05)))),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(16)),
                        child: Icon(Icons.add_to_drive_rounded, color: p.onAccent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.googleDrive, style: TextStyle(color: p.onHero, fontWeight: FontWeight.w800, fontSize: 19)),
                          Text(connected ? settings.driveEmail! : s.googleDriveSub, style: TextStyle(color: p.onHero.withValues(alpha: 0.65), fontSize: 13)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: p.onHero.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Icon(Icons.history_rounded, color: p.onHero.withValues(alpha: 0.7), size: 20),
                        const SizedBox(width: 10),
                        Text('${s.lastBackup}: ', style: TextStyle(color: p.onHero.withValues(alpha: 0.65))),
                        Expanded(
                          child: Text(
                            settings.lastBackup == null ? s.never : '${f.relativeDay(settings.lastBackup!, s)} · ${f.date(settings.lastBackup!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.onHero, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    if (!_drive.platformSupported || !_drive.configured)
                      Text(s.driveNotConfigured, style: TextStyle(color: p.warning, fontWeight: FontWeight.w600))
                    else if (!connected)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent),
                          onPressed: _busy == null ? _connect : null,
                          icon: _spinnerOr('connect', Icons.login_rounded, p.onAccent),
                          label: Text(s.connectDrive),
                        ),
                      )
                    else ...[
                      Row(children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.onAccent),
                            onPressed: _busy == null ? _backupDrive : null,
                            icon: _spinnerOr('backup', Icons.cloud_upload_rounded, p.onAccent),
                            label: Text(s.backupNow),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: p.onHero, side: BorderSide(color: p.onHero.withValues(alpha: 0.25))),
                            onPressed: _busy == null ? _restoreDrive : null,
                            icon: _spinnerOr('restore', Icons.cloud_download_rounded, p.onHero),
                            label: Text(s.restoreFromDrive),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: p.onHero, side: BorderSide(color: p.onHero.withValues(alpha: 0.25))),
                          onPressed: _busy == null ? _disconnect : null,
                          child: Text(s.disconnect),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.autoBackup, style: TextStyle(color: p.onHero, fontWeight: FontWeight.w600)),
                        subtitle: Text(s.autoBackupSub, style: TextStyle(color: p.onHero.withValues(alpha: 0.6))),
                        value: settings.autoBackup,
                        onChanged: settings.setAutoBackup,
                      ),
                    ],
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            // ── Local file ──
            Panel(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconBubble(Icons.sd_storage_rounded, p.info, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.localFile, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      Text(s.localFileSub, style: TextStyle(color: p.muted, fontSize: 13)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy == null ? _export : null,
                      icon: _spinnerOr('export', Icons.file_download_rounded, p.bg),
                      label: Text(s.exportFile),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy == null ? _import : null,
                      icon: _spinnerOr('import', Icons.file_upload_rounded, p.ink),
                      label: Text(s.importFile),
                    ),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            Loader<Map<String, int>>(
              load: (r) => r.counts(),
              builder: (context, c) => Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.dbStats, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    _count(s.vehicles, c['vehicles'] ?? 0, Icons.directions_car_filled_rounded),
                    _count(s.drivers, c['drivers'] ?? 0, Icons.person_rounded),
                    _count(s.income, c['incomes'] ?? 0, Icons.south_west_rounded),
                    _count(s.expense, c['expenses'] ?? 0, Icons.north_east_rounded),
                    _count(s.papers, c['papers'] ?? 0, Icons.description_rounded),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spinnerOr(String key, IconData icon, Color color) => _busy == key
      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: color))
      : Icon(icon);

  Widget _count(String label, int n, IconData icon) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: p.muted),
        const SizedBox(width: 6),
        Text(context.fmt.digits(n), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: p.muted, fontSize: 12.5)),
      ]),
    );
  }
}
