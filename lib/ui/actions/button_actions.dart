import 'dart:ui';

import 'package:openboard_wrapper/button_data.dart';
import 'package:parrotaac/audio/audio_source.dart';
import 'package:parrotaac/audio_player.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import '../widgets/sentence_box.dart';

void executeActions(ParrotButtonNotifier button) {
  SentenceBoxController? boxController = button.boxController;
  final dataCopy = boxController?.dataCopyView();
  final List<ButtonData> sentenceBoxInitialState = List.of(dataCopy ?? []);
  Iterable<ParrotAction> actions;

  List<String> actionStrings = button.data.actions;
  if (actionStrings.isEmpty && button.data.action != null) {
    actionStrings.add(button.data.action!);
  }

  actions = button.actions.nonNulls;

  final String? projectPath = button.projectPath;
  final actionBuilder = _ActionBuilder(
    buttonData: button.data,
    sentenceBoxInitialState,
    projectPath: projectPath,
    goHome: button.goHome,
  );

  for (ParrotAction action in actions) {
    actionBuilder.addAction(action);
  }

  actionBuilder.execute(boxController: boxController);
}

class _ActionBuilder {
  final List<AudioSource> toSpeak = [];
  final List<ButtonData> sentenceBoxState;
  final String? projectPath;
  final ButtonData? buttonData;
  VoidCallback? goHome;

  _ActionBuilder(
    this.sentenceBoxState, {
    this.projectPath,
    this.buttonData,
    this.goHome,
  });

  void addAction(ParrotAction action) {
    switch (action) {
      case ParrotAction.speak:
        speak();
      case ParrotAction.clear:
        clear();
      case ParrotAction.backspace:
        backspace();
      case ParrotAction.playButton:
        playButton();
      case ParrotAction.addToSentenceBox:
        addToSentenceBox();
      case ParrotAction.home:
        if (goHome != null) {
          goHome!();
        }
    }
  }

  void execute({SentenceBoxController? boxController}) {
    PreemptiveAudioPlayer().playIterable(toSpeak);
    boxController?.updateData(sentenceBoxState);
  }

  void speak() {
    toSpeak.addAll(
      _toAudioSources(
        sentenceBoxState,
        projectPath: projectPath,
      ),
    );
  }

  void clear() {
    sentenceBoxState.clear();
  }

  void backspace() {
    if (sentenceBoxState.isNotEmpty) {
      sentenceBoxState.removeLast();
    }
  }

  void playButton() {
    AudioSource? source = buttonData?.getSource(projectPath: projectPath);
    if (source != null) {
      toSpeak.add(source);
    }
  }

  void addToSentenceBox() {
    if (buttonData != null) {
      sentenceBoxState.add(buttonData!);
    }
  }

  Iterable<AudioSource> _toAudioSources(
    List<ButtonData> buttons, {
    String? projectPath,
  }) {
    //Type  needs inculuded for extensions to work
    AudioSource toAuidoSource(ButtonData bd) =>
        bd.getSource(projectPath: projectPath);

    return buttons.map(toAuidoSource);
  }
}

enum ParrotAction {
  speak(":speak"),
  clear(":clear"),
  home(":home"),
  backspace(":backspace"),
  playButton(":ext_play_button"),
  addToSentenceBox(":ext_add_to_sentence_box");

  const ParrotAction(this.name);

  final String name;
  @override
  String toString() {
    return name;
  }

  static ParrotAction? fromString(String name) {
    bool theNamesMatch(ParrotAction action) => action.name == name;
    return ParrotAction.values.where(theNamesMatch).firstOrNull;
  }
}
