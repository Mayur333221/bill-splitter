import 'package:hive/hive.dart';

class BillService {
  static String boxName(String groupName) => 'bills_$groupName';

  static Future<List<Map>> getBills(String groupName) async {
    final box = await Hive.openBox<Map>(boxName(groupName));
    return box.values.toList();
  }

  static Future<void> addBill(String groupName, Map bill) async {
    final box = await Hive.openBox<Map>(boxName(groupName));
    await box.add(bill);
  }
}
