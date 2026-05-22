import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/checklist.dart';
import '../models/task.dart';

class ChecklistScreen extends StatefulWidget {
  final Checklist checklist;
  final Future<void> Function() onChanged;

  const ChecklistScreen({
    super.key,
    required this.checklist,
    required this.onChanged,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final _uuid = const Uuid();

  void _addTask() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva tarea'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Descripción'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              setState(() {
                widget.checklist.tasks.add(
                  Task(id: _uuid.v4(), title: title),
                );
              });
              widget.onChanged();
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _editTask(Task task) {
    final controller = TextEditingController(text: task.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar tarea'),
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
              final title = controller.text.trim();
              if (title.isEmpty) return;
              setState(() => task.title = title);
              widget.onChanged();
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _deleteTask(Task task) {
    setState(() => widget.checklist.tasks.remove(task));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.checklist.tasks;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.checklist.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: tasks.isEmpty
          ? const Center(
              child: Text(
                'Sin tareas.\nToca + para agregar una.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final task = tasks[i];
                return ListTile(
                  leading: Checkbox(
                    value: task.isChecked,
                    onChanged: (v) {
                      setState(() => task.isChecked = v ?? false);
                      widget.onChanged();
                    },
                  ),
                  title: Text(
                    task.title,
                    style: task.isChecked
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _editTask(task);
                      if (v == 'delete') _deleteTask(task);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        tooltip: 'Nueva tarea',
        child: const Icon(Icons.add),
      ),
    );
  }
}
