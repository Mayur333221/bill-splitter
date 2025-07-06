import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hive/hive.dart';

class OCRScreen extends StatefulWidget {
  final String groupName;
  final List<String> members;

  const OCRScreen({super.key, required this.groupName, required this.members});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  File? _image;
  List<Map<String, dynamic>> extractedItems = [];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      final imageFile = File(picked.path);
      setState(() {
        _image = imageFile;
        extractedItems = [];
      });
      await _runOCR(imageFile);
    }
  }

  Future<void> _runOCR(File image) async {
    final inputImage = InputImage.fromFile(image);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final result = await recognizer.processImage(inputImage);

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

    recognizer.close();
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
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Edit Item"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Item Name"),
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: "Amount"),
                  keyboardType: TextInputType.number,
                ),
                Divider(),
                Text("Split Between:"),
                ...widget.members.map((m) => CheckboxListTile(
                      title: Text(m),
                      value: selected.contains(m),
                      onChanged: (val) {
                        setStateDialog(() {
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
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
              child: Text("Save"),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _saveBill() async {
    if (extractedItems.isEmpty) return;

    final box = await Hive.openBox<Map>('bills_${widget.groupName}');
    await box.add({
      "title": "Scanned Bill",
      "items": extractedItems,
      "paidBy": widget.members.first,
      "date": DateTime.now().millisecondsSinceEpoch
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan & Extract Bill")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.camera_alt),
                label: Text("Camera"),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.photo),
                label: Text("Gallery"),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
          if (_image != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.file(_image!, height: 150),
            ),
          Divider(),
          Expanded(
            child: extractedItems.isEmpty
                ? Center(child: Text("No items detected yet."))
                : ListView.builder(
                    itemCount: extractedItems.length,
                    itemBuilder: (context, index) {
                      final item = extractedItems[index];
                      final members = (item['split'] as Map).keys.join(", ");
                      return ListTile(
                        title: Text("${item['name']} - ₹${item['amount']}"),
                        subtitle: Text("Split: $members"),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
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
                icon: Icon(Icons.save),
                label: Text("Save Bill"),
                onPressed: _saveBill,
              ),
            ),
        ],
      ),
    );
  }
}
