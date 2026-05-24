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

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final task = widget.checklist.tasks.removeAt(oldIndex);
      widget.checklist.tasks.insert(newIndex, task);
    });
    widget.onChanged();
  }

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
          : ReorderableListView.builder(
              itemCount: tasks.length,
              onReorder: _reorder,
              buildDefaultDragHandles: false,
              itemBuilder: (_, i) {
                final task = tasks[i];
                return ListTile(
                  key: ValueKey(task.id),
                  leading: Checkbox(
                    value: task.isChecked,
                    onChanged: (v) {
                      setState(() => task.isChecked = v ?? false);
                      widget.onChanged();
                    },
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      decoration: task.isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: task.isChecked ? Colors.grey : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _editTask(task);
                          if (v == 'delete') _deleteTask(task);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Eliminar')),
                        ],
                      ),
                      ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.drag_handle, color: Colors.grey),
                        ),
                      ),
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
