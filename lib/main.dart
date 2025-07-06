import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';

void main() async{
   WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
 await Hive.openBox<String>('groups');
   runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const BillSplitterApp(),
    ),
  );
}

class BillSplitterApp extends StatelessWidget {
  const BillSplitterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bill Splitter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
