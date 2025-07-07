import 'package:bill_splitter_app/screens/settle_up_screen.dart';
import 'package:bill_splitter_app/screens/view_settlement_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/services/member_service.dart';
import 'add_bill_screen.dart';
import 'ocr_screen.dart';

class GroupScreen extends StatefulWidget {
  final String groupName;

  const GroupScreen({super.key, required this.groupName});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  List<String> members = [];
  List<Map<String, dynamic>> bills = [];
  Map<String, double> balances = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadBills();
  }

  Future<void> _loadMembers() async {
    final result = await MemberService.getMembers(widget.groupName);
    setState(() {
      members = result;
    });
  }

  Future<void> _loadBills() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupName)
        .collection('bills')
        .get();

    setState(() {
      bills = snapshot.docs.map((doc) => doc.data()).toList();
    });

    _calculateBalances();
  }

  Future<void> _calculateBalances() async {
    final Map<String, double> netBalance = {for (var m in members) m: 0.0};

    for (final bill in bills) {
      final items = (bill['items'] as List).cast<Map>();
      final payer = bill['paidBy'] as String?;

      if (payer == null) continue;

      double totalPaid = 0.0;

      for (final item in items) {
        final double amount = item['amount'];
        final split = (item['split'] as Map).cast<String, double>();

        totalPaid += amount;

        for (final entry in split.entries) {
          netBalance[entry.key] = (netBalance[entry.key] ?? 0) - entry.value;
        }
      }

      netBalance[payer] = (netBalance[payer] ?? 0) + totalPaid;
    }

    final settleSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupName)
        .collection('settlements')
        .get();

    for (final s in settleSnapshot.docs) {
      final data = s.data();
      final from = data['from'];
      final to = data['to'];
      final amt = data['amount'] * 1.0;

      netBalance[from] = (netBalance[from] ?? 0) + amt;
      netBalance[to] = (netBalance[to] ?? 0) - amt;
    }

    setState(() {
      balances = netBalance;
    });
  }

  List<String> _getWhoOwesWhom() {
    final creditors = <String, double>{};
    final debtors = <String, double>{};

    balances.forEach((member, balance) {
      if (balance > 0) {
        creditors[member] = balance;
      } else if (balance < 0) {
        debtors[member] = -balance;
      }
    });

    final result = <String>[];
    final creditorList = creditors.entries.toList();
    final debtorList = debtors.entries.toList();

    int i = 0, j = 0;
    while (i < debtorList.length && j < creditorList.length) {
      final debtor = debtorList[i];
      final creditor = creditorList[j];
      final amount =
          debtor.value < creditor.value ? debtor.value : creditor.value;

      result.add(
          "${debtor.key} owes ${creditor.key} ₹${amount.toStringAsFixed(2)}");

      debtorList[i] = MapEntry(debtor.key, debtor.value - amount);
      creditorList[j] = MapEntry(creditor.key, creditor.value - amount);

      if (debtorList[i].value == 0) i++;
      if (creditorList[j].value == 0) j++;
    }

    return result;
  }

  Future<void> _addMemberDialog() async {
    final controller = TextEditingController();
    String? memberName;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Member'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Member Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  memberName = name;
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (memberName != null) {
      await MemberService.addMember(widget.groupName, memberName!);
      await _loadMembers();
    }
  }

  Future<void> _deleteMember(int index) async {
    final memberName = members[index];
    await MemberService.deleteMember(widget.groupName, memberName);
    await _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: "Add Bill",
            onPressed: members.isEmpty
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddBillScreen(
                          groupName: widget.groupName,
                          members: members,
                        ),
                      ),
                    );
                    await _loadBills();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: members.isEmpty
                ? const Center(child: Text('No members yet. Tap + to add one.'))
                : ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(members[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteMember(index),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          const Text("Bills", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            flex: 2,
            child: bills.isEmpty
                ? const Center(child: Text("No bills yet. Tap 🧾 to add one."))
                : ListView.builder(
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
                      final bill = bills[index];
                      final total = (bill['items'] as List).fold(
                        0.0,
                        (sum, item) => sum + (item['amount'] as double),
                      );
                      return ListTile(
                        title: Text(bill['title'] ?? 'Untitled'),
                        subtitle: Text("₹${total.toStringAsFixed(2)}"),
                        trailing: const Icon(Icons.receipt_long),
                      );
                    },
                  ),
          ),
          const Divider(),
          const Text("Balances", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            flex: 1,
            child: balances.isEmpty
                ? const Center(child: Text("No balances yet."))
                : ListView(
                    children: balances.entries.map((entry) {
                      final value = entry.value;
                      final status = value == 0
                          ? "is settled up"
                          : value > 0
                              ? "is owed ₹${value.toStringAsFixed(2)}"
                              : "owes ₹${value.abs().toStringAsFixed(2)}";
                      return ListTile(
                        title: Text(entry.key),
                        subtitle: Text(status),
                      );
                    }).toList(),
                  ),
          ),
          const Divider(),
          const Text("Who Owes Whom", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            flex: 1,
            child: ListView(
              children: _getWhoOwesWhom()
                  .map((entry) => ListTile(title: Text(entry)))
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'view-settlements',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ViewSettlementsScreen(groupName: widget.groupName),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text("View Settlements"),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'settle',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettleUpScreen(
                    groupName: widget.groupName,
                    members: members,
                  ),
                ),
              );
              if (result == true) {
                await _loadBills();
              }
            },
            icon: const Icon(Icons.compare_arrows),
            label: const Text("Settle Up"),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add-member',
            onPressed: _addMemberDialog,
            tooltip: 'Add Member',
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'ocr',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OCRScreen(
                    groupName: widget.groupName,
                    members: members,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.camera),
            label: const Text("Scan Bill"),
          ),
        ],
      ),
    );
  }
}
