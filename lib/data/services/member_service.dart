import 'package:cloud_firestore/cloud_firestore.dart';

class MemberService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<List<String>> getMembers(String groupName) async {
    final snapshot = await _firestore.collection('groups').doc(groupName).get();
    final data = snapshot.data();
    if (data != null && data['members'] is List) {
      return List<String>.from(data['members']);
    }
    return [];
  }

  static Future<void> addMember(String groupName, String memberName) async {
    final members = await getMembers(groupName);
    if (!members.contains(memberName)) {
      members.add(memberName);
      await _firestore.collection('groups').doc(groupName).update({
        'members': members,
      });
    }
  }

  static Future<void> deleteMember(String groupName, String memberName) async {
    final members = await getMembers(groupName);
    members.remove(memberName);
    await _firestore.collection('groups').doc(groupName).update({
      'members': members,
    });
  }
}
