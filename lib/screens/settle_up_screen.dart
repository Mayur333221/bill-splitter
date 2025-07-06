import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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

  void _submitSettlement() async {
    final amt = double.tryParse(amountController.text.trim()) ?? 0;
    if (payer == null || receiver == null || amt <= 0 || payer == receiver) return;

    final box = await Hive.openBox<Map>('settlements_${widget.groupName}');
    await box.add({
      'from': payer,
      'to': receiver,
      'amount': amt,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    Navigator.pop(context, true); // return success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settle Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: payer,
              decoration: InputDecoration(labelText: "Paid By"),
              items: widget.members.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => payer = v),
            ),
            DropdownButtonFormField<String>(
              value: receiver,
              decoration: InputDecoration(labelText: "Paid To"),
              items: widget.members.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => receiver = v),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitSettlement,
              child: Text("Save Settlement"),
            )
          ],
        ),
      ),
    );
  }
}
