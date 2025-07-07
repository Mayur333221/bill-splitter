import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  final List<String> _groups = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> get groups => _groups;

  /// Loads all group names from Firebase Firestore
  Future<void> loadGroups() async {
    try {
      final snapshot = await _firestore.collection('groups').get();

      _groups.clear();
      for (final doc in snapshot.docs) {
        _groups.add(doc.id); // Using document ID as group name
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error loading groups: $e");
    }
  }

  /// Adds a new group by its name
  Future<void> addGroup(String name) async {
    try {
      await _firestore.collection('groups').doc(name).set({
        'createdAt': FieldValue.serverTimestamp(),
        'members': [], // Initial empty member list
      });

      await loadGroups();
    } catch (e) {
      if (kDebugMode) print("Error adding group: $e");
    }
  }

  /// Optional: Delete a group by name
  Future<void> deleteGroup(String name) async {
    try {
      await _firestore.collection('groups').doc(name).delete();
      await loadGroups();
    } catch (e) {
      if (kDebugMode) print("Error deleting group: $e");
    }
  }
}
