import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/audio/audio_source.dart';
import 'package:parrotaac/audio_player.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';

class SentenceBoxController extends ChangeNotifier {
  List<SenteceBoxDisplayEntry> _dataToDisplay;
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
    List<SenteceBoxDisplayEntry>? initialData,
  })  : _buttonWidth = buttonWidth,
        _buttonHeight = buttonHeight,
        _dataToDisplay = initialData ?? [];

  void clear() {
    _dataToDisplay.clear();
    notifyListeners();
  }

  void update() {
    notifyListeners();
  }

  void backSpace() {
    if (_dataToDisplay.isNotEmpty) {
      _dataToDisplay.removeLast();

      notifyListeners();
    }
  }

  void updateData(List<SenteceBoxDisplayEntry> entries) {
    _dataToDisplay = entries;
    notifyListeners();
  }

  void add(SenteceBoxDisplayEntry entry) {
    _dataToDisplay.add(entry);
    notifyListeners();
  }

  UnmodifiableListView<SenteceBoxDisplayEntry> dataCopyView() {
    return UnmodifiableListView(_dataToDisplay);
  }

  Iterable<AudioSource> get audioSourcesCopy {
    return _dataToDisplay.map(
      (b) => b.data.getSource(projectPath: projectPath),
    );
  }

  void speak() async {
    PreemptiveAudioPlayer().playIterable(
      audioSourcesCopy,
    );
  }
}

class SenteceBoxDisplayEntry {
  final ButtonData data;
  final Obf? board;

  SenteceBoxDisplayEntry({
    required this.data,
    this.board,
  });
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
              .map((entry) => entry.data)
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
