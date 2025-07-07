import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddBillScreen extends StatefulWidget {
  final String groupName;
  final List<String> members;
  final Map<String, dynamic>? bill;
  final String? billId;

  const AddBillScreen({
    super.key,
    required this.groupName,
    required this.members,
    this.bill,
    this.billId,
  });

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  late TextEditingController billTitleController;
  late List<Map<String, dynamic>> items;
  String? selectedPayer;

  bool get isEditing => widget.bill != null && widget.billId != null;

  @override
  void initState() {
    super.initState();
    billTitleController =
        TextEditingController(text: widget.bill?['title'] ?? '');
    items = (widget.bill?['items'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    selectedPayer = widget.bill?['paidBy'] ??
        (widget.members.isNotEmpty ? widget.members[0] : null);
  }

  void _addItemDialog({Map<String, dynamic>? item, int? editIndex}) {
    final nameController =
        TextEditingController(text: item != null ? item['name'] : '');
    final amountController =
        TextEditingController(text: item != null ? item['amount'].toString() : '');
    final selected = <String>{
      ...(item != null
          ? (item['split'] as Map).keys
          : widget.members)
    };

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: Text(item == null ? "Add Item" : "Edit Item"),
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
                child: Text(item == null ? "Add" : "Save"),
              )
            ],
          ),
        );
      },
    ).then((newItem) {
      if (newItem != null) {
        setState(() {
          if (editIndex != null) {
            items[editIndex] = newItem;
          } else {
            items.add(newItem);
          }
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

    if (isEditing) {
      // Update existing bill
      await billsCollection.doc(widget.billId).update(bill);
    } else {
      // Add new bill
      await billsCollection.add(bill);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Edit Bill" : "New Bill")),
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
              onPressed: () => _addItemDialog(),
              icon: const Icon(Icons.add),
              label: const Text("Add Item"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text("No items added yet"))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item['name']),
                          subtitle: Text("₹${item['amount']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _addItemDialog(
                                  item: item,
                                  editIndex: index,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    items.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            ElevatedButton(
              onPressed: _saveBill,
              child: Text(isEditing ? "Save Changes" : "Save Bill"),
            )
          ],
        ),
      ),
    );
  }
}
