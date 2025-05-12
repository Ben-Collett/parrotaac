import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:parrotaac/audio/audio_source.dart';
import 'package:parrotaac/audio_player.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';

class SentenceBoxController extends ChangeNotifier {
  List<ButtonData> _dataToDisplay;
  String? projectPath;
  double _buttonWidth;
  double _buttonHeight;

  double get buttonWidth {
    return _buttonWidth;
  }

  double get buttonHeight {
    return _buttonHeight;
  }

  set buttonWidth(double width) {
    _buttonWidth = width;
    notifyListeners();
  }

  set buttonHeight(double height) {
    _buttonHeight = height;
    notifyListeners();
  }

  SentenceBoxController({
    double buttonWidth = 100,
    double buttonHeight = 100,
    this.projectPath,
    List<ButtonData>? initialData,
  })  : _buttonWidth = buttonWidth,
        _buttonHeight = buttonHeight,
        _dataToDisplay = initialData ?? [];

  void clear() {
    _dataToDisplay.clear();
    notifyListeners();
  }

  void backSpace() {
    if (_dataToDisplay.isNotEmpty) {
      _dataToDisplay.removeLast();
      notifyListeners();
    }
  }

  void updateData(List<ButtonData> buttons) {
    _dataToDisplay = buttons;
    notifyListeners();
  }

  void add(ButtonData button) {
    _dataToDisplay.add(button);
    notifyListeners();
  }

  UnmodifiableListView<ButtonData> dataCopyView() {
    return UnmodifiableListView(_dataToDisplay);
  }

  Iterable<AudioSource> get audioSourcesCopy {
    return _dataToDisplay.map(
      (b) => b.getSource(projectPath: projectPath),
    );
  }

  void speak() async {
    PreemptiveAudioPlayer().playIterable(
      audioSourcesCopy,
    );
  }
}

class SentenceBox extends StatelessWidget {
  final SentenceBoxController controller;
  const SentenceBox({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    Widget toStatelessParrotButton(ButtonData bd) => StatelessParrotButton(
        buttonData: bd, projectPath: controller.projectPath);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ListView(
          scrollDirection: Axis.horizontal,
          children: controller._dataToDisplay
              .map(toStatelessParrotButton)
              .map((b) => SizedBox(
                  width: controller.buttonWidth,
                  height: controller.buttonHeight,
                  child: b))
              .toList(),
        );
      },
    );
  }
}
