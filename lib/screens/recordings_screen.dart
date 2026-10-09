import 'dart:io';

import 'package:amakawa_core/amakawa_core.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../engine.dart';
import '../l10n/app_localizations.dart';
import 'playback_screen.dart';

class _Rec {
  _Rec(this.file)
    : duration = AmakawaCore.fileDuration(file.path),
      modified = file.lastModifiedSync(),
      size = file.lengthSync();
  final File file;
  final double? duration;
  final DateTime modified;
  final int size;
}

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key, required this.engine});
  final EngineController engine;

  @override
  State<RecordingsScreen> createState() => RecordingsScreenState();
}

class RecordingsScreenState extends State<RecordingsScreen> {
  List<_Rec>? _items;
  String _dir = '';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final d = await widget.engine.recordingsDir();
    final files =
        d
            .listSync()
            .whereType<File>()
            .where(
              (f) => const [
                '.wav',
                '.mp3',
                '.flac',
              ].contains(p.extension(f.path).toLowerCase()),
            )
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
    if (!mounted) return;
    setState(() {
      _dir = d.path;
      _items = [for (final f in files) _Rec(f)];
    });
  }

  String _fmtDur(double? s) {
    if (s == null) return '--:--';
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s - m * 60).floor().toString().padLeft(2, '0')}';
  }

  String _fmtDate(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  Future<void> _rename(_Rec r) async {
    final t = AppLocalizations.of(context);
    final ctl = TextEditingController(
      text: p.basenameWithoutExtension(r.file.path),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.renameTitle),
        content: TextField(controller: ctl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(c, ctl.text.trim()),
            child: Text(t.ok),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final safe = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    await r.file.rename(
      p.join(p.dirname(r.file.path), '$safe${p.extension(r.file.path)}'),
    );
    refresh();
  }

  Future<void> _delete(_Rec r) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.deleteTitle),
        content: Text(p.basename(r.file.path)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await r.file.delete();
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final items = _items;
    if (items == null) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return Center(child: Text(t.recordingsEmpty));
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.graphic_eq)),
                title: Text(p.basenameWithoutExtension(r.file.path)),
                subtitle: Text(
                  '${_fmtDate(r.modified)} · ${_fmtDur(r.duration)} · ${(r.size / 1024).round()} KB',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlaybackScreen(
                      engine: widget.engine,
                      path: r.file.path,
                    ),
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'rename':
                        _rename(r);
                      case 'share':
                        SharePlus.instance.share(
                          ShareParams(files: [XFile(r.file.path)]),
                        );
                      case 'delete':
                        _delete(r);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'rename', child: Text(t.menuRename)),
                    PopupMenuItem(value: 'share', child: Text(t.menuShare)),
                    PopupMenuItem(value: 'delete', child: Text(t.menuDelete)),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: SelectableText(
            t.savedIn(_dir),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
