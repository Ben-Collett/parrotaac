import 'dart:ui';

import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/audio/audio_source.dart';
import 'package:parrotaac/audio_player.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import '../widgets/sentence_box.dart';

void executeActions(ParrotButtonNotifier button, {Obf? board}) {
  SentenceBoxController? boxController = button.boxController;
  final dataCopy = boxController?.dataCopyView();
  final List<SenteceBoxDisplayEntry> sentenceBoxInitialState =
      List.of(dataCopy ?? []);
  Iterable<ParrotAction> actions;

  List<String> actionStrings = button.data.actions;
  if (actionStrings.isEmpty && button.data.action != null) {
    actionStrings.add(button.data.action!);
  }

  actions = button.actions.nonNulls;

  final String? projectPath = button.projectPath;
  final actionBuilder = _ActionBuilder(
    displayEntry: SenteceBoxDisplayEntry(data: button.data, board: board),
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
  final List<SenteceBoxDisplayEntry> sentenceBoxState;
  final String? projectPath;
  final SenteceBoxDisplayEntry? displayEntry;
  ButtonData? get buttonData => displayEntry?.data;
  VoidCallback? goHome;

  _ActionBuilder(
    this.sentenceBoxState, {
    this.projectPath,
    this.displayEntry,
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
        goHome?.call();
    }
  }

  void execute({SentenceBoxController? boxController}) {
    PreemptiveAudioPlayer().playIterable(toSpeak);
    boxController?.updateData(sentenceBoxState);
  }

  void speak() {
    toSpeak.addAll(
      _toAudioSources(
        sentenceBoxState.map((entry) => entry.data).toList(),
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
      sentenceBoxState.add(displayEntry!);
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
