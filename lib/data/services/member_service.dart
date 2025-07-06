import 'package:hive/hive.dart';

class MemberService {
  static String boxName(String groupName) => 'members_$groupName';

  static Future<List<String>> getMembers(String groupName) async {
    final box = await Hive.openBox<String>(boxName(groupName));
    return box.values.toList();
  }

  static Future<void> addMember(String groupName, String memberName) async {
    final box = await Hive.openBox<String>(boxName(groupName));
    await box.add(memberName);
  }

  static Future<void> deleteMember(String groupName, int index) async {
    final box = await Hive.openBox<String>(boxName(groupName));
    await box.deleteAt(index);
  }
}
