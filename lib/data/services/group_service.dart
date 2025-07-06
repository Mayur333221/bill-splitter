import 'package:flutter/material.dart';
import 'member_service.dart';

class GroupScreen extends StatefulWidget {
  final String groupName;

  const GroupScreen({super.key, required this.groupName});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  List<String> members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    members = await MemberService.getMembers(widget.groupName);
    setState(() {});
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
              Navigator.pop(context); // Pop FIRST, no async after this
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );

  // AFTER dialog is dismissed, do async work
  if (memberName != null) {
    await MemberService.addMember(widget.groupName, memberName!);
    await _loadMembers();
  }
}



  Future<void> _deleteMember(int index) async {
    await MemberService.deleteMember(widget.groupName, index);
    await _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: members.isEmpty
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addMemberDialog,
        tooltip: 'Add Member',
        child: const Icon(Icons.person_add)
      ),
    );
  }
}
