import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../db/database.dart';
import '../services/backup_service.dart';
import '../services/platform.dart';
import '../services/widget_sync.dart';
import 'themes_screen.dart';

const kAppVersion = '1.0.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themes = ref.watch(themesProvider).value ?? const <AppTheme>[];
    final defaultId = themes.where((t) => t.isDefault).firstOrNull?.id;
    void open(Widget page) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & new phone'),
            onTap: () => open(const BackupScreen()),
          ),
          if (kHomeWidgetSupported) ...[
            ListTile(
              leading: const Icon(Icons.widgets),
              title: const Text('Widget settings'),
              onTap: () => open(const WidgetSettingsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Widget setup guide'),
              onTap: () => open(const WidgetGuideScreen()),
            ),
          ],
          if (themes.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Default theme'),
              trailing: DropdownButton<String>(
                value: defaultId,
                items: [
                  for (final t in themes)
                    DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: (id) {
                  if (id != null) {
                    ref.read(repositoryProvider).setDefaultTheme(id);
                  }
                },
              ),
              onTap: () => open(const ThemesScreen()),
            ),
        ],
      ),
    );
  }
}

class WidgetGuideScreen extends StatelessWidget {
  const WidgetGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget setup guide')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Adding the widget\n'
          '1. Press and hold an empty area of your home screen.\n'
          '2. Tap "Widgets".\n'
          '3. Find "Bible Pic" and press and hold its widget.\n'
          '4. Drag it onto the home screen and release.\n'
          '5. Resize it by pressing and holding it, then dragging the handles.\n\n'
          'Choosing what it shows\n'
          'Open Settings, then Widget settings. Verse of the day shows one '
          'verse that stays the same all day and changes at midnight. Fixed '
          'verse always shows the verse (and optionally the photo) you pick.\n\n'
          'If the widget is blank\n'
          '- Open the app once so it can draw the widget images.\n'
          '- Add at least one verse.\n'
          '- The widget refreshes about every 30 minutes, so the new day can '
          'appear shortly after midnight rather than exactly at midnight.\n'
          '- Tapping the widget opens the app at that verse.',
          style: TextStyle(height: 1.4),
        ),
      ),
    );
  }
}

class WidgetSettingsScreen extends ConsumerStatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  ConsumerState<WidgetSettingsScreen> createState() =>
      _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends ConsumerState<WidgetSettingsScreen> {
  WidgetConfig? _config;

  @override
  void initState() {
    super.initState();
    WidgetConfig.load().then((c) {
      if (mounted) setState(() => _config = c);
    });
  }

  Future<void> _apply(WidgetConfig c) async {
    setState(() => _config = c);
    await c.save();
    if (!mounted) return;
    await WidgetSync(ref.read(repositoryProvider)).sync(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = _config;
    final verses = ref.watch(versesProvider).value ?? const <Verse>[];
    final photos = ref.watch(photosProvider).value ?? const <Photo>[];
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Widget settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Widget settings')),
      body: ListView(
        children: [
          RadioGroup<WidgetMode>(
            groupValue: c.mode,
            onChanged: (m) {
              if (m != null) {
                _apply(
                  WidgetConfig(
                    mode: m,
                    fixedVerseId: c.fixedVerseId,
                    fixedPhotoId: c.fixedPhotoId,
                  ),
                );
              }
            },
            child: const Column(
              children: [
                RadioListTile<WidgetMode>(
                  value: WidgetMode.verseOfTheDay,
                  title: Text('Verse of the day'),
                  subtitle: Text('Changes at midnight'),
                ),
                RadioListTile<WidgetMode>(
                  value: WidgetMode.fixed,
                  title: Text('Fixed verse'),
                ),
              ],
            ),
          ),
          if (c.mode == WidgetMode.fixed) ...[
            DropdownButtonFormField<String>(
              initialValue: verses.any((v) => v.id == c.fixedVerseId)
                  ? c.fixedVerseId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Verse',
                contentPadding: EdgeInsets.all(16),
              ),
              isExpanded: true,
              items: [
                for (final v in verses)
                  DropdownMenuItem(value: v.id, child: Text(v.reference)),
              ],
              onChanged: (id) => _apply(
                WidgetConfig(
                  mode: c.mode,
                  fixedVerseId: id,
                  fixedPhotoId: c.fixedPhotoId,
                ),
              ),
            ),
            DropdownButtonFormField<String?>(
              initialValue: photos.any((p) => p.id == c.fixedPhotoId)
                  ? c.fixedPhotoId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Photo',
                contentPadding: EdgeInsets.all(16),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Automatic pairing'),
                ),
                for (var i = 0; i < photos.length; i++)
                  DropdownMenuItem(
                    value: photos[i].id,
                    child: Text('Photo ${i + 1}'),
                  ),
              ],
              onChanged: (id) => _apply(
                WidgetConfig(
                  mode: c.mode,
                  fixedVerseId: c.fixedVerseId,
                  fixedPhotoId: id,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  BackupService get _service => BackupService(ref.read(repositoryProvider));

  void _say(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _backUp() async {
    setState(() => _busy = true);
    try {
      await _service.backUpNow(appVersion: kAppVersion);
    } catch (e) {
      if (mounted) _say('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final mode = await showDialog<RestoreMode>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Restore mode'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, RestoreMode.replace),
            child: const Text('Replace — wipe this app, then load the backup'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, RestoreMode.merge),
            child: const Text('Merge — add only what is missing'),
          ),
        ],
      ),
    );
    if (mode == null || !mounted) return;
    if (mode == RestoreMode.replace) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Replace everything?'),
          content: const Text(
            'All verses, topics, photos and themes on this phone will be '
            'deleted and replaced by the backup. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final s = await _service.restore(await file.readAsBytes(), mode);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            mode == RestoreMode.replace ? 'Restore complete' : 'Merge complete',
          ),
          content: Text(
            '${mode == RestoreMode.replace ? 'Loaded' : 'Added'}:\n'
            '- ${s.verses} verses\n- ${s.topics} topics\n'
            '- ${s.photos} photos\n- ${s.themes} themes\n'
            '${s.missingPhotoFiles > 0 ? '\n${s.missingPhotoFiles} photo file(s) were missing from the backup.' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on BackupException catch (e) {
      if (mounted) _say(e.message);
    } catch (e) {
      if (mounted) _say('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider).value;
    final verses = ref.watch(versesProvider).value ?? const <Verse>[];
    final last = meta?.lastBackup;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & new phone')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            last == null
                ? 'Last backup: never'
                : 'Last backup: ${last.toLocal().toString().substring(0, 16)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (verses.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('This app is empty. Use "Restore" to load a backup.'),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _backUp,
                  child: const Text('Back up now'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _restore,
                  child: const Text('Restore'),
                ),
              ),
            ],
          ),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Before you need it\n'
            '- Keep the source code in Git and the signing keystore somewhere safe.\n'
            '- Back up regularly and keep a copy outside the phone.\n\n'
            'Moving to a new phone\n'
            '1. Back up on the old phone and send the file somewhere reachable.\n'
            '2. Build the APK with the same keystore and install it on the new phone.\n'
            '3. Download the backup file on the new phone.\n'
            '4. Restore from backup, choosing Replace.\n'
            '5. Re-add the home-screen widget.\n'
            '6. Check verses and photos before resetting the old phone.\n\n'
            'Restore modes\n'
            '- Replace: deletes everything in the app, then loads the backup. '
            'Asks for confirmation first.\n'
            '- Merge: keeps what is in the app and adds only items from the '
            'backup that are not already present (matched by id).\n\n'
            'Troubleshooting\n'
            '- "Backup from a newer version": install the newer app version, then restore.\n'
            '- Missing photos: the summary lists photo files absent from the '
            'zip; the verses still load and fall back to other photos.\n'
            '- Compare the counts in the restore summary with the counts on the old phone.',
            style: TextStyle(height: 1.4),
          ),
        ],
      ),
    );
  }
}
