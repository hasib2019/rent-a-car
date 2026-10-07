import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../services/settings.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'backup_screen.dart';
import 'documents_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.embedded = false});

  /// True when shown as a tab on wide layouts (no back button).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = context.fmt;
    final p = context.pal;
    final settings = context.watch<Settings>();

    final body = Contained(
      maxWidth: 680,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          if (embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
              child: Text(s.settings, style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
          Panel(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Avatar(name: settings.ownerName.isEmpty ? 'G' : settings.ownerName, initials: settings.ownerName.isEmpty ? 'G' : settings.ownerName.characters.first, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(settings.ownerName.isEmpty ? s.ownerName : settings.ownerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  Text(settings.businessName.isEmpty ? s.businessName : settings.businessName, style: TextStyle(color: p.muted)),
                ]),
              ),
              IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => _editProfile(context)),
            ]),
          ),
          SectionHeader(s.language),
          PillToggle<bool>(values: const [true, false], selected: settings.isBangla, label: (v) => v ? 'বাংলা' : 'English', onChanged: settings.setBangla),
          SectionHeader(s.appearance),
          PillToggle<ThemeMode>(
            values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
            selected: settings.themeMode,
            label: (m) => switch (m) {
              ThemeMode.system => s.themeSystem,
              ThemeMode.light => s.themeLight,
              ThemeMode.dark => s.themeDark,
            },
            onChanged: settings.setThemeMode,
          ),
          if (settings.isBangla) ...[
            const SizedBox(height: 12),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.banglaDigits, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(s.banglaDigitsSub),
                value: settings.banglaDigitsPref,
                onChanged: settings.setBanglaDigits,
              ),
            ),
          ],
          SectionHeader(s.dataBackup),
          Panel(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              _tile(context, Icons.cloud_upload_rounded, p.info, s.backupRestore,
                  settings.lastBackup == null ? '${s.lastBackup}: ${s.never}' : '${s.lastBackup}: ${f.date(settings.lastBackup!)}',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupScreen()))),
              Divider(indent: 70, color: p.line),
              _tile(context, Icons.event_note_rounded, p.warning, s.documentsReminders, null,
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DocumentsScreen()))),
              Divider(indent: 70, color: p.line),
              _tile(context, Icons.delete_forever_rounded, p.expense, s.resetData, null, () => _reset(context)),
            ]),
          ),
          SectionHeader(s.about),
          Panel(
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.menu_book_rounded, color: p.onAccent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.appName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  Text(s.tagline, style: TextStyle(color: p.muted, fontSize: 13)),
                  Text('${s.version} ${f.digits('1.0.0')}', style: TextStyle(color: p.muted, fontSize: 12)),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );

    if (embedded) return SafeArea(bottom: false, child: body);
    return Scaffold(appBar: AppBar(title: Text(s.settings)), body: body);
  }

  Widget _tile(BuildContext context, IconData icon, Color color, String title, String? sub, VoidCallback onTap) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: IconBubble(icon, color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: sub == null ? null : Text(sub),
        trailing: const Icon(Icons.chevron_right_rounded),
      );

  Future<void> _editProfile(BuildContext context) async {
    final settings = context.read<Settings>();
    final s = context.s;
    final name = TextEditingController(text: settings.ownerName);
    final biz = TextEditingController(text: settings.businessName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.profile),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(labelText: s.ownerName)),
          const SizedBox(height: 12),
          TextField(controller: biz, decoration: InputDecoration(labelText: s.businessName)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), child: Text(s.save)),
        ],
      ),
    );
    if (ok == true) {
      await settings.setOwnerName(name.text);
      await settings.setBusinessName(biz.text);
    }
    name.dispose();
    biz.dispose();
  }

  Future<void> _reset(BuildContext context) async {
    final s = context.s;
    if (!await confirm(context, title: s.resetData, body: s.resetConfirm)) return;
    if (!context.mounted) return;
    await context.read<AppState>().mutate((r) => r.eraseEverything());
    if (context.mounted) toast(context, s.deleted, icon: Icons.delete_outline_rounded);
  }
}
