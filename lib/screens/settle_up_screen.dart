import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettleUpScreen extends StatefulWidget {
  final String groupName;
  final List<String> members;

  const SettleUpScreen({
    super.key,
    required this.groupName,
    required this.members,
  });

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  String? payer;
  String? receiver;
  final amountController = TextEditingController();

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

    Navigator.pop(context, true); // Indicate success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settle Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: payer,
              decoration: const InputDecoration(labelText: "Paid By"),
              items: widget.members
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => payer = v),
            ),
            DropdownButtonFormField<String>(
              value: receiver,
              decoration: const InputDecoration(labelText: "Paid To"),
              items: widget.members
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => receiver = v),
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
