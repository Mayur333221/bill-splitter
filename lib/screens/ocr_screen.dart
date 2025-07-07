import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRScreen extends StatefulWidget {
  final String groupName;
  final List<String> members;

  const OCRScreen({super.key, required this.groupName, required this.members});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  Uint8List? _imageBytes;
  List<Map<String, dynamic>> extractedItems = [];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        extractedItems = [];
      });
      await _runOCR(bytes);
    }
  }

  Future<void> _runOCR(Uint8List bytes) async {
    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: const Size(1000, 1000), // Replace with actual if known
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: 1000,
      ),
    );

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final result = await recognizer.processImage(inputImage);
    recognizer.close();

    final items = <Map<String, dynamic>>[];

    for (final block in result.blocks) {
      for (final line in block.lines) {
        final text = line.text;
        final match = RegExp(r'(.+?)\s+(\d+(\.\d{1,2})?)$').firstMatch(text);
        if (match != null) {
          final name = match.group(1)!.trim();
          final amount = double.tryParse(match.group(2)!) ?? 0;
          items.add({
            "name": name,
            "amount": amount,
            "split": {
              for (var m in widget.members)
                m: double.parse((amount / widget.members.length).toStringAsFixed(2))
            }
          });
        }
      }
    }

    setState(() {
      extractedItems = items;
    });
  }

  Future<void> _editItem(int index) async {
    final item = extractedItems[index];
    final nameController = TextEditingController(text: item['name']);
    final amountController = TextEditingController(text: item['amount'].toString());
    final selected = Set<String>.from(item['split'].keys);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("Edit Item"),
          content: SingleChildScrollView(
            child: Column(
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
                  final per = amount / selected.length;
                  final split = {
                    for (var m in selected) m: double.parse(per.toStringAsFixed(2))
                  };

                  setState(() {
                    extractedItems[index] = {
                      "name": name,
                      "amount": amount,
                      "split": split,
                    };
                  });

                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _saveBill() async {
    if (extractedItems.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupName)
        .collection('bills')
        .add({
      "title": "Scanned Bill",
      "items": extractedItems,
      "paidBy": widget.members.first,
      "date": DateTime.now().millisecondsSinceEpoch,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan & Extract Bill")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Camera"),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text("Gallery"),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
          if (_imageBytes != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.memory(_imageBytes!, height: 150),
            ),
          const Divider(),
          Expanded(
            child: extractedItems.isEmpty
                ? const Center(child: Text("No items detected yet."))
                : ListView.builder(
                    itemCount: extractedItems.length,
                    itemBuilder: (context, index) {
                      final item = extractedItems[index];
                      final members = (item['split'] as Map).keys.join(", ");
                      return ListTile(
                        title: Text("${item['name']} - ₹${item['amount']}"),
                        subtitle: Text("Split: $members"),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editItem(index),
                        ),
                      );
                    },
                  ),
          ),
          if (extractedItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Bill"),
                onPressed: _saveBill,
              ),
            ),
        ],
      ),
    );
  }
}
