class Task {
  final String id;
  String title;
  bool isChecked;

  Task({required this.id, required this.title, this.isChecked = false});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isChecked': isChecked,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        isChecked: json['isChecked'] as bool,
      );
}
