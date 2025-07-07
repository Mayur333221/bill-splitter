import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddBillScreen extends StatefulWidget {
  final String groupName;
  final List<String> members;

  const AddBillScreen({
    super.key,
    required this.groupName,
    required this.members,
  });

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final billTitleController = TextEditingController();
  List<Map<String, dynamic>> items = [];
  String? selectedPayer;

  @override
  void initState() {
    super.initState();
    if (widget.members.isNotEmpty) {
      selectedPayer = widget.members[0]; // Default to first member
    }
  }

  void _addItemDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final selected = <String>{...widget.members};

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: const Text("Add Item"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Item Name"),
                  ),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: "Amount"),
                    keyboardType: TextInputType.number,
                  ),
                  const Divider(),
                  const Text("Split Between:"),
                  ...widget.members.map((m) => CheckboxListTile(
                        title: Text(m),
                        value: selected.contains(m),
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              selected.add(m);
                            } else {
                              selected.remove(m);
                            }
                          });
                        },
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final amount = double.tryParse(amountController.text.trim()) ?? 0;

                  if (name.isNotEmpty && amount > 0 && selected.isNotEmpty) {
                    final perPerson = (amount / selected.length);
                    final split = {
                      for (var member in selected)
                        member: double.parse(perPerson.toStringAsFixed(2))
                    };

                    final newItem = {
                      "name": name,
                      "amount": amount,
                      "split": split,
                    };

                    Navigator.pop(context, newItem);
                  }
                },
                child: const Text("Add"),
              )
            ],
          ),
        );
      },
    ).then((newItem) {
      if (newItem != null) {
        setState(() {
          items.add(newItem);
        });
      }
    });
  }

  Future<void> _saveBill() async {
    final title = billTitleController.text.trim();
    if (title.isEmpty || items.isEmpty || selectedPayer == null) return;

    final bill = {
      "title": title,
      "items": items,
      "date": DateTime.now().millisecondsSinceEpoch,
      "paidBy": selectedPayer
    };

    final billsCollection = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupName)
        .collection('bills');

    await billsCollection.add(bill);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Bill")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: billTitleController,
              decoration: const InputDecoration(labelText: "Bill Title"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPayer,
              decoration: const InputDecoration(labelText: "Paid By"),
              items: widget.members.map((member) {
                return DropdownMenuItem(
                  value: member,
                  child: Text(member),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPayer = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addItemDialog,
              icon: const Icon(Icons.add),
              label: const Text("Add Item"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text("No items added yet"))
                  : ListView(
                      children: items
                          .map((item) => ListTile(
                                title: Text(item['name']),
                                subtitle: Text("₹${item['amount']}"),
                              ))
                          .toList(),
                    ),
            ),
            ElevatedButton(
              onPressed: _saveBill,
              child: const Text("Save Bill"),
            )
          ],
        ),
      ),
    );
  }
}
