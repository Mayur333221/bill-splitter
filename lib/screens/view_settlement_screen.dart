import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewSettlementsScreen extends StatefulWidget {
  final String groupName;

  const ViewSettlementsScreen({super.key, required this.groupName});

  @override
  State<ViewSettlementsScreen> createState() => _ViewSettlementsScreenState();
}

class _ViewSettlementsScreenState extends State<ViewSettlementsScreen> {
  List<Map<String, dynamic>> settlements = [];

  @override
  void initState() {
    super.initState();
    _loadSettlements();
  }

  Future<void> _loadSettlements() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupName)
        .collection('settlements')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      settlements = snapshot.docs
          .map((doc) => {
                'from': doc['from'],
                'to': doc['to'],
                'amount': doc['amount'],
                'timestamp': (doc['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ??
                    DateTime.now().millisecondsSinceEpoch,
              })
          .toList();
    });
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Settlements")),
      body: settlements.isEmpty
          ? const Center(child: Text("No settlements yet."))
          : ListView.separated(
              itemCount: settlements.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final s = settlements[index];
                return ListTile(
                  leading: const Icon(Icons.payment),
                  title:
                      Text("${s['from']} paid ${s['to']} ₹${s['amount'].toStringAsFixed(2)}"),
                  subtitle: Text(_formatDate(s['timestamp'])),
                );
              },
            ),
    );
  }
}
