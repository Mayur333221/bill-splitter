import 'package:cloud_firestore/cloud_firestore.dart';

class BillService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _billsRef(String groupName) {
    return _firestore.collection('groups').doc(groupName).collection('bills');
  }

  /// Fetch all bills for a group
  static Future<List<Map<String, dynamic>>> getBills(String groupName) async {
    try {
      final snapshot = await _billsRef(groupName).orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      // print("Error fetching bills for $groupName: $e");
      return [];
    }
  }

  /// Add a new bill to a group
  static Future<void> addBill(String groupName, Map<String, dynamic> bill) async {
    try {
      await _billsRef(groupName).add({
        ...bill,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print("Error adding bill for $groupName: $e");
    }
  }
}
