import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';

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
    ImageData urlImage() => ImageData(url: "https://picsum.photos/400/300");
    ButtonData genButton(String label) =>
        ButtonData(image: urlImage(), label: label);

    final buttons = List.generate(
      100,
      (i) => SenteceBoxDisplayEntry(data: genButton("$i")),
    );
    var controller = SentenceBoxController(initialData: buttons);
    return Scaffold(
      appBar: AppBar(
        title: const Text('sentence box'),
        backgroundColor: Color(0xFFAFABDF),
      ),
      body: SizedBox(
        width: 500,
        height: 200,
        child: SentenceBox(controller: controller),
      ),
    );
  }
}
