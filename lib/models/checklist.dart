import 'task.dart';

class Checklist {
  final String id;
  String name;
  List<Task> tasks;

  Checklist({required this.id, required this.name, List<Task>? tasks})
      : tasks = tasks ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory Checklist.fromJson(Map<String, dynamic> json) => Checklist(
        id: json['id'] as String,
        name: json['name'] as String,
        tasks: (json['tasks'] as List)
            .map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
