import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class ViewSettlementsScreen extends StatefulWidget {
  final String groupName;

  const ViewSettlementsScreen({super.key, required this.groupName});

  @override
  State<ViewSettlementsScreen> createState() => _ViewSettlementsScreenState();
}

class _ViewSettlementsScreenState extends State<ViewSettlementsScreen> {
  List<Map> settlements = [];

  @override
  void initState() {
    super.initState();
    _loadSettlements();
  }

  Future<void> _loadSettlements() async {
    final box = await Hive.openBox<Map>('settlements_${widget.groupName}');
    setState(() {
      settlements = box.values.toList();
    });
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Settlements")),
      body: settlements.isEmpty
          ? Center(child: Text("No settlements yet."))
          : ListView.separated(
              itemCount: settlements.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final s = settlements[index];
                final from = s['from'];
                final to = s['to'];
                final amount = s['amount'];
                final date = _formatDate(s['timestamp']);

                return ListTile(
                  leading: Icon(Icons.payment),
                  title: Text("$from paid $to ₹${amount.toStringAsFixed(2)}"),
                  subtitle: Text(date),
                );
              },
            ),
    );
  }
}
