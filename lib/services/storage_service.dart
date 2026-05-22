import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checklist.dart';

class StorageService {
  static const _key = 'checklists';

  Future<List<Checklist>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Checklist.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<Checklist> checklists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(checklists.map((c) => c.toJson()).toList()),
    );
  }
}
