import 'package:flutter/material.dart';
import 'package:openboard_wrapper/_utils.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/ui/parrot_button.dart';

import '../constiants.dart';

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
    SoundData urlSound = SoundData(url: audioURL, duration: 3);
    ImageData urlImage = ImageData(url: "https://picsum.photos/400/300");
    ImageData rawSvg = ImageData(
      inlineData: InlineData(
        dataType: 'image/svg',
        data: svgGreenCircle,
      ),
    );

    List<ButtonData> dataList = [
      ButtonData(label: "TTS test", backgroundColor: ColorData(green: 255)),
      ButtonData(
        label: "voclization",
        voclization: "hello world",
        backgroundColor: ColorData(blue: 255),
      ),
      ButtonData(image: urlImage, label: "url", sound: urlSound),
    ];

    List<Widget> boxes = dataList
        .map((data) => ParrotButton(initialData: data))
        .map((button) => SizedBox(width: 150, height: 150, child: button))
        .toList();

    ParrotButton update = ParrotButton();
    return Scaffold(
      appBar: AppBar(
          title: const Text('entry test'), backgroundColor: Color(0xFFAFABDF)),
      body: Column(
        children: [
          ...boxes,
          SizedBox(width: 150, height: 150, child: update),
          SizedBox(
            width: 50,
            height: 50,
            child: TextButton(
                child: Text("hello"),
                onPressed: () {
                  update.update((entry) {
                    entry.label = "hello";
                    entry.sound = urlSound;
                    entry.backgroundColor =
                        ColorData.fromString("RGB(255,0,0)");
                    entry.image = rawSvg;
                    entry.borderColor = ColorData.fromString("RGB(0,0,255)");
                  });
                }),
          ),
        ],
      ),
    );
  }
}
