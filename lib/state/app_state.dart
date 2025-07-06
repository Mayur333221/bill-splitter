import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class AppState extends ChangeNotifier {
  List<String> _groups = [];

  List<String> get groups => _groups;

  Future<void> loadGroups() async {
    final box = Hive.box<String>('groups');
    _groups = box.values.toList();
    notifyListeners();
  }

  Future<void> addGroup(String name) async {
    final box = Hive.box<String>('groups');
    await box.add(name);
    await loadGroups();
  }
}
