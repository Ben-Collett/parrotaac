import 'package:flutter/material.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/ui/widgets/displey_entry.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Parrot AAC',
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('entry test'), backgroundColor: Color(0xFFAFABDF)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("ehhlo", textAlign: TextAlign.left),
          DisplayEntry.fromDisplayData(
              data: ParrotProjectDisplayData("test1"),
              imageWidth: 40,
              imageHeight: 60,
              viewType: ViewType.list),
          Divider(),
          DisplayEntry.fromDisplayData(
            imageWidth: 40,
            imageHeight: 60,
            data: ParrotProjectDisplayData("test2"),
            viewType: ViewType.list,
          ),
          Divider(),
          DisplayEntry.fromDisplayData(
            imageWidth: 40,
            imageHeight: 60,
            data: ParrotProjectDisplayData("test3"),
            viewType: ViewType.list,
          ),
        ],
      ),
    );
  }
}
