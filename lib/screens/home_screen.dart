import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/checklist.dart';
import '../services/storage_service.dart';
import 'checklist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _uuid = const Uuid();
  List<Checklist> _checklists = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _storage.load();
    setState(() => _checklists = data);
  }

  Future<void> _save() => _storage.save(_checklists);

  // ── Import / Export ────────────────────────────────────────────────────────

  Future<void> _exportAll() async {
    await _shareJson(
      _checklists.map((c) => c.toJson()).toList(),
      filename: 'mae_check_export.json',
      subject: 'MAE_Check — todas las checklists',
    );
  }

  Future<void> _exportOne(Checklist checklist) async {
    await _shareJson(
      [checklist.toJson()],
      filename: '${_safeName(checklist.name)}.json',
      subject: 'MAE_Check — ${checklist.name}',
    );
  }

  Future<void> _shareJson(
    List<dynamic> data, {
    required String filename,
    required String subject,
  }) async {
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: subject,
    );
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    try {
      final content = await File(result.files.single.path!).readAsString();
      final list = jsonDecode(content) as List;
      final imported = list
          .map((e) => Checklist.fromJson(e as Map<String, dynamic>))
          .toList();

      int added = 0;
      setState(() {
        for (final cl in imported) {
          if (!_checklists.any((e) => e.id == cl.id)) {
            _checklists.add(cl);
            added++;
          }
        }
      });
      await _save();
      _snack('$added checklist(s) importada(s)');
    } catch (_) {
      _snack('Archivo inválido. ¿Es un JSON de MAE_Check?');
    }
  }

  // ── CRUD checklists ────────────────────────────────────────────────────────

  void _addChecklist() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva checklist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _checklists.add(Checklist(id: _uuid.v4(), name: name));
              });
              _save();
              Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _editChecklist(Checklist checklist) {
    final controller = TextEditingController(text: checklist.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              setState(() => checklist.name = name);
              _save();
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _deleteChecklist(Checklist checklist) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar checklist'),
        content: Text('¿Eliminar "${checklist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _checklists.remove(checklist));
              _save();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _safeName(String name) => name.replaceAll(RegExp(r'[^\w]'), '_');

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAE_Check'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'export') _exportAll();
              if (v == 'import') _import();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Exportar todo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Importar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _checklists.isEmpty
          ? const Center(
              child: Text(
                'Sin checklists.\nToca + para crear una.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: _checklists.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final cl = _checklists[i];
                final done = cl.tasks.where((t) => t.isChecked).length;
                final total = cl.tasks.length;
                return ListTile(
                  title: Text(
                    cl.name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    total == 0 ? 'Sin tareas' : '$done/$total completadas',
                    style: TextStyle(
                      fontSize: 18,
                      color: total > 0 && done == total
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _editChecklist(cl);
                      if (v == 'delete') _deleteChecklist(cl);
                      if (v == 'export') _exportOne(cl);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar nombre')),
                      PopupMenuItem(value: 'export', child: Text('Exportar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChecklistScreen(
                          checklist: cl,
                          onChanged: _save,
                        ),
                      ),
                    );
                    setState(() {});
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addChecklist,
        tooltip: 'Nueva checklist',
        child: const Icon(Icons.add),
      ),
    );
  }
}
