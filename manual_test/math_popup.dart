import 'package:flutter/material.dart';
import 'package:parrotaac/backend/project/authentication/math_problem_generator.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/ui/popups/lock_popups/math_popup.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: TextButton(
          child: Text("hello"),
          onPressed: () => showMathAuthenticationPopup(
            context,
            getMultiplicationProblem(),
            onAccept: () {
              SimpleLogger().logInfo('accepted');
            },
            onReject: () {
              SimpleLogger().logInfo('rejected');
            },
          ),
        ),
      ),
    );
  }
}
