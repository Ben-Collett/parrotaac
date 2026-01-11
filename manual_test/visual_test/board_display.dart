import 'package:flutter/material.dart';
import 'package:parrotaac/project_selector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Parrot AAC', home: MainScreen());
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('board selector'),
        backgroundColor: Color(0xFFAFABDF),
      ),
      body: DisplayView(searchController: TextEditingController()),
    );
  }
}
