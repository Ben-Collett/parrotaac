import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/audio_player.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/sound_extensions.dart';
import 'package:parrotaac/extensions/image_extensions.dart';

void Function(Obf) _defaultGoToLinkedBoard = (_) {};

class ParrotButtonNotifier extends ChangeNotifier {
  ButtonData data;
  void Function(Obf) goToLinkedBoard;
  String? rootBoardPath;

  ParrotButtonNotifier({
    ButtonData? data,
    void Function(Obf)? goToLinkedBoard,
    this.rootBoardPath,
  })  : data = data ?? ButtonData(),
        goToLinkedBoard = goToLinkedBoard ?? _defaultGoToLinkedBoard;

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
      buttonData.sound?.play(rootPath: controller.rootBoardPath);
    } else {
      PreemptiveAudioPlayer()
          .playTTS(buttonData.voclization ?? buttonData.label ?? "");
    }

    if (buttonData.linkedBoard != null) {
      Obf linkedBoard = buttonData.linkedBoard!;
      controller.goToLinkedBoard(linkedBoard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          List<Widget> column = [];
          if (buttonData.image != null) {
            column.add(Expanded(
              // flex: 3,
              child: buttonData.image!
                  .toImage(projectPath: controller.rootBoardPath),
            ));
          }
          if (buttonData.label != null) {
            column.add(Text(buttonData.label!));
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
