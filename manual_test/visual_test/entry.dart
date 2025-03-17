import 'package:flutter/material.dart';
import 'package:parrotaac/board_selector.dart';
import 'package:parrotaac/parrot_project.dart';

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
              imageHeight: 60),
          Divider(),
          DisplayEntry.fromDisplayData(
            imageWidth: 40,
            imageHeight: 60,
            data: ParrotProjectDisplayData("test2"),
          ),
          Divider(),
          DisplayEntry.fromDisplayData(
            imageWidth: 40,
            imageHeight: 60,
            data: ParrotProjectDisplayData("test3"),
          ),
        ],
      ),
    );
  }
}
