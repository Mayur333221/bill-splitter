import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettleUpScreen extends StatefulWidget {
  final String groupName;
  final List<String> members;
  final Map<String, double> balances;

  const SettleUpScreen({
    super.key,
    required this.groupName,
    required this.members,
    required this.balances,
  });

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  String? payer;
  String? receiver;
  final amountController = TextEditingController();

  double getOwedAmount(String? payer, String? receiver) {
    final balances = widget.balances;
    if (payer == null || receiver == null) return 0.0;
    final creditors = <String, double>{};
    final debtors = <String, double>{};

    balances.forEach((member, balance) {
      if (balance > 0) {
        creditors[member] = balance;
      } else if (balance < 0) {
        debtors[member] = -balance;
      }
    });

    final creditorList = creditors.entries.toList();
    final debtorList = debtors.entries.toList();

    int i = 0, j = 0;
    while (i < debtorList.length && j < creditorList.length) {
      final debtor = debtorList[i];
      final creditor = creditorList[j];
      final amount = debtor.value < creditor.value ? debtor.value : creditor.value;

      if (debtor.key == payer && creditor.key == receiver) {
        return double.parse(amount.toStringAsFixed(2));
      }

      debtorList[i] = MapEntry(debtor.key, debtor.value - amount);
      creditorList[j] = MapEntry(creditor.key, creditor.value - amount);

      if (debtorList[i].value == 0) i++;
      if (creditorList[j].value == 0) j++;
    }
    return 0.0;
  }

  void _updateSuggestedAmount() {
    final owed = getOwedAmount(payer, receiver);
    if (owed > 0) {
      amountController.text = owed.toStringAsFixed(2);
    } else {
      amountController.text = '';
    }
  }

  Future<void> _submitSettlement() async {
    final amt = double.tryParse(amountController.text.trim()) ?? 0;
    if (payer == null || receiver == null || amt <= 0 || payer == receiver) return;

    final settlement = {
      'from': payer,
      'to': receiver,
      'amount': amt,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupName)
        .collection('settlements')
        .add(settlement);

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Remove current receiver from Paid By options, and current payer from Paid To options
    final paidByOptions = widget.members.where((m) => m != receiver).toList();
    final paidToOptions = widget.members.where((m) => m != payer).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Settle Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: payer,
              decoration: const InputDecoration(labelText: "Paid By"),
              items: paidByOptions
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  payer = v;
                  // If receiver becomes same as payer, reset receiver
                  if (receiver == v) receiver = null;
                  _updateSuggestedAmount();
                });
              },
            ),
            DropdownButtonFormField<String>(
              value: receiver,
              decoration: const InputDecoration(labelText: "Paid To"),
              items: paidToOptions
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  receiver = v;
                  // If payer becomes same as receiver, reset payer
                  if (payer == v) payer = null;
                  _updateSuggestedAmount();
                });
              },
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitSettlement,
              child: const Text("Save Settlement"),
            )
          ],
        ),
      ),
    );
  }
}
