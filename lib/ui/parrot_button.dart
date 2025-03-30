import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/audio_player.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/sound_extensions.dart';
import 'package:parrotaac/extensions/image_extensions.dart';

class ParrotButtonNotifier extends ChangeNotifier {
  ButtonData data;
  ParrotButtonNotifier({ButtonData? data}) : data = data ?? ButtonData();

  void setLabel(String label) {
    data.label = label;
    notifyListeners();
  }

  void setImage(ImageData image) {
    data.image = image;
    notifyListeners();
  }

  void setBackgroundColor(ColorData color) {
    data.backgroundColor = color;
    notifyListeners();
  }

  void setBorderColor(ColorData border) {
    data.borderColor = border;
    notifyListeners();
  }

  void setSound(SoundData sound) {
    data.sound = sound; //doesn't need to rebuild as change is not visual
  }
}

class ParrotButton extends StatelessWidget {
  final ParrotButtonNotifier controller;
  ButtonData get buttonData => controller.data;
  const ParrotButton({super.key, required this.controller});
  void onTap() {
    if (buttonData.sound != null) {
      //TODO: I need to pass a root path
      buttonData.sound?.play();
    } else {
      PreemptiveAudioPlayer()
          .playTTS(buttonData.voclization ?? buttonData.label ?? "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          List<Widget> column = [];
          if (buttonData.image != null) {
            column.add(buttonData.image!.toImage());
          }
          if (buttonData.label != null) {
            column.add(Flexible(child: Text(buttonData.label!)));
          }
          return Material(
            key: UniqueKey(),
            color: buttonData.backgroundColor?.toColor() ?? Colors.white,
            child: InkWell(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      width: 2,
                      color: buttonData.borderColor?.toColor() ?? Colors.white),
                ),
                child: Column(children: column),
              ),
            ),
          );
        });
  }
}
