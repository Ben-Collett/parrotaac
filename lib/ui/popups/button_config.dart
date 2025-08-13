import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/audio/prefered_audio_source.dart';
import 'package:parrotaac/audio_recorder.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project/temp_files.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/image_extensions.dart';
import 'package:parrotaac/extensions/map_extensions.dart';
import 'package:parrotaac/file_utils.dart';
import 'package:parrotaac/ui/actions/button_actions.dart';
import 'package:parrotaac/ui/board_screen_popup_history.dart';
import 'package:parrotaac/ui/codgen/board_screen_popups.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import 'package:parrotaac/ui/restore_button_diff.dart';
import 'package:parrotaac/ui/screens/board_select.dart';
import 'package:parrotaac/ui/util_widgets/action_modifier.dart';
import 'package:parrotaac/ui/util_widgets/segmented_button_menu.dart';
import 'package:parrotaac/utils.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';
import 'package:path/path.dart' as p;

import 'create_board.dart';
import 'popup_utils.dart';

void showConfigExistingPopup({
  required BuildContext context,
  required ParrotButtonNotifier controller,
  Obf? currentBoard,
  BoardScreenPopupHistory? popupHistory,
  RestorableButtonDiff? restorableButtonDiff,
  bool writeHistory = true,
}) {
  popupHistory?.pushScreen(
    ButtonConfig(controller.data.id),
    writeHistory: writeHistory,
  );
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      ButtonData data = controller.data;
      final Map<String, dynamic> originalJson =
          Map.unmodifiable(controller.data.toJson());
      final SoundData? originalSound = data.sound;
      final ImageData? originalImage = data.image;
      //The sentence box controller has to be null in the config screen to avoid taps in the preview being added to the sentence box
      final sentenceBoxController = controller.boxController;
      controller.boxController = null;
      final goToLinkedBoard = controller.goToLinkedBoard;
      controller.goToLinkedBoard = (_) {};

      IconButton cancelButton = IconButton(
        color: Colors.red,
        icon: Icon(Icons.cancel_rounded),
        onPressed: () {
          controller.setButtonData(ButtonData.decode(json: originalJson));
          controller.setImage(originalImage);
          controller.setSound(originalSound);
          Navigator.of(context).pop();
        },
      );

      IconButton acceptButton = IconButton(
        color: Colors.green,
        icon: Icon(Icons.check),
        onPressed: () {
          controller.boxController = sentenceBoxController;
          controller.goToLinkedBoard = goToLinkedBoard;
          Navigator.of(context).pop();
          final Map<String, dynamic> currentJson = controller.data.toJson();
          final Map<String, dynamic> diff =
              originalJson.valuesThatAreDifferent(currentJson);
          final Map<String, dynamic> undoDiff =
              currentJson.valuesThatAreDifferent(originalJson);

          //WARNING: mapEquals only works if there are no nested structures
          bool soundChanged = !mapEquals(
            originalSound?.toJson(),
            data.sound?.toJson(),
          );
          bool imageChanged = !mapEquals(
            originalImage?.toJson(),
            data.image?.toJson(),
          );

          if (diff.isNotEmpty || soundChanged || imageChanged) {
            controller.eventHandler.addConfigureButtonToHistory(
              controller.data.id,
              diff,
              undoDiff,
              originalSound: originalSound,
              originalImage: originalImage,
              newImage: data.image,
              newSound: data.sound,
            );

            //forces sentenceBox to rebuild to update the appearance of the buttons
            sentenceBoxController?.update();
          }
        },
      );

      IconButton deleteButton = IconButton(
        color: Colors.red,
        icon: Icon(Icons.delete),
        onPressed: () {
          _showConfirmDeleteDialog(context, controller.onDelete);
        },
      );

      List<Widget> actions = [];

      Row row = Row(
        children: [
          cancelButton,
          acceptButton,
        ],
      );
      if (controller.onDelete != null) {
        row = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [deleteButton, row],
        );
      }
      actions.add(cancelButton);
      actions.add(acceptButton);

      if (restorableButtonDiff != null) {
        restorableButtonDiff.apply(controller.data,
            project: controller.project);
      }

      return AlertDialog(
        content: ButtonConfigPopup(
          buttonController: controller,
          eventHandler: controller.eventHandler,
          currentBoard: currentBoard,
          restorableButtonDiff: restorableButtonDiff,
          popupHistory: popupHistory,
        ),
        actions: [row],
      );
    },
  ).then((_) {
    popupHistory?.popScreen();
    restorableButtonDiff?.clear();
  });
}

void _showConfirmDeleteDialog(BuildContext context, VoidCallback? onDelete) {
  IconButton cancelButton = IconButton(
    color: Colors.red,
    icon: Icon(Icons.cancel_rounded),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  IconButton acceptButton = IconButton(
    color: Colors.green,
    icon: Icon(Icons.check),
    onPressed: () {
      if (onDelete != null) {
        onDelete();
      }
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    },
  );
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("confirm button delete"),
        actions: [cancelButton, acceptButton],
      );
    },
  );
}

class ButtonConfigPopup extends StatefulWidget {
  final ParrotButtonNotifier buttonController;
  final ProjectEventHandler eventHandler;
  final Obf? currentBoard;
  final RestorableButtonDiff? restorableButtonDiff;
  final BoardScreenPopupHistory? popupHistory;
  const ButtonConfigPopup({
    super.key,
    required this.buttonController,
    this.popupHistory,
    required this.eventHandler,
    this.restorableButtonDiff,
    this.currentBoard,
  });

  @override
  State<ButtonConfigPopup> createState() => _ButtonConfigPopupState();
}

class _ButtonConfigPopupState extends State<ButtonConfigPopup> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _voclizationController = TextEditingController();
  late final BoardHistoryStack _lastLinkedBoard;
  late final ValueNotifier<String?> _selectedAudioPath;
  final ValueNotifier<bool> recording = ValueNotifier(false);
  String? currentRecordingPath;
  static const String recordedAudioString = "recorded_audio";

  late final ParrotButtonNotifier buttonController;
  ParrotAction selectedAction = ParrotAction.playButton;

  late final BoardLinkingActionMode startingMode;
  late final PreferredAudioSourceType startingAudioSource;
  late final Obf currentBoard;

  ColorData? get currentBackgroundColor =>
      widget.buttonController.data.backgroundColor;
  ColorData? get currentBorderColor => widget.buttonController.data.borderColor;
  ParrotProject? get project => widget.buttonController.project;

  @override
  void dispose() {
    _voclizationController.dispose();
    _labelController.dispose();
    recording.dispose();
    _selectedAudioPath.dispose();
    _lastLinkedBoard.dispose();
    super.dispose();
  }

  ///the last image set after opening the create screen, this will be null until the user sets an image, even if the board being edited already had an image
  File? lastSetTempImage;
  @override
  void initState() {
    buttonController = widget.buttonController;
    _lastLinkedBoard = BoardHistoryStack(
        currentBoard: buttonController.data.linkedBoard, maxHistorySize: 1);
    _lastLinkedBoard.addListener(() {
      Obf? board = _lastLinkedBoard.currentBoardOrNull;
      if (board != null) {
        widget.restorableButtonDiff
            ?.update("load_board", LinkedBoard.fromObf(board).toJson());
      }
      buttonController.data.linkedBoard = _lastLinkedBoard.currentBoardOrNull;
    });

    buttonController.enableParrotActionModeIfDisabled();
    _selectedAudioPath = ValueNotifier(buttonController.data.sound?.path);
    _labelController.text = buttonController.data.label ?? "";
    _voclizationController.text = buttonController.data.voclization ?? "";
    _labelController.addListener(
      () {
        final text = _labelController.text;
        buttonController.setLabel(text);
        widget.restorableButtonDiff?.update(ButtonData.labelKey, text);
      },
    );
    _voclizationController.addListener(() {
      if (_voclizationController.text.trim() == "") {
        buttonController.data.voclization = null;
      } else {
        buttonController.data.voclization = _voclizationController.text;
      }
      widget.restorableButtonDiff?.update(
        ButtonData.voclizationKey,
        buttonController.data.voclization,
      );
    });

    _changeSelection(widget.restorableButtonDiff?.boardLinkingActionMode);
    if (widget.restorableButtonDiff?.boardLinkingActionMode != null) {
      startingMode = widget.restorableButtonDiff!.boardLinkingActionMode!;
    } else if (buttonController.data.linkedBoard != null) {
      startingMode = BoardLinkingActionMode.customSelection;
    } else if (buttonController.actions.contains(ParrotAction.home)) {
      startingMode = BoardLinkingActionMode.home;
    } else {
      startingMode = BoardLinkingActionMode.none;
    }

    startingAudioSource = widget.buttonController.data.preferredAudioSourceType;

    _restorePopupHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //TODO: it may be better to not have the grid update instead
      buttonController.update(); //needed to initialize in the grid.
    });
    super.initState();
  }

  void _restorePopupHistory() {
    BoardScreenPopup? popup = widget.popupHistory?.removeNextToRecover();
    if (popup is SelectBackgroundColor) {
      widget.popupHistory?.pushScreen(popup, writeHistory: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showColorChangeDialog(
          changeBackgroundColor,
          initialColor: currentBackgroundColor?.toColor(),
        );
      });
    } else if (popup is SelectBorderColor) {
      widget.popupHistory?.pushScreen(popup, writeHistory: false);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showColorChangeDialog(
          changeBorderColor,
          initialColor: currentBorderColor?.toColor(),
        ),
      );
    } else if (popup is SelectBoardScreen) {
      if (project == null) {
        throw Exception("A project is needed to select a board");
      }

      Obf? initialBoard = project?.findBoardById(popup.boardId);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) async => _selectBoard(
          initialBoard: initialBoard,
          writeHistory: false,
        ),
      );
    } else if (popup is CreateBoard) {
      WidgetsBinding.instance.addPostFrameCallback((_) => showCreateBoardDialog(
            context,
            _lastLinkedBoard,
            history: widget.popupHistory,
            widget.eventHandler,
            name: popup.name,
            rowCount: popup.rowCount,
            colCount: popup.colCount,
          ));
    }
  }

  void changeBackgroundColor(Color color) {
    setState(() {
      ColorData colorData = ColorDataCovertor.fromColorToColorData(color);
      widget.restorableButtonDiff
          ?.update(ButtonData.bgColorKey, colorData.toString());
      buttonController.setBackgroundColor(colorData);
    });
  }

  Future<void> _selectBoard({
    Obf? initialBoard,
    bool writeHistory = true,
  }) async {
    if (project == null) {
      throw Exception("A project is needed to select a board");
    }
    Obf board = initialBoard ??
        _lastLinkedBoard.currentBoardOrNull ??
        buttonController.project!.root!;

    widget.popupHistory?.pushScreen(SelectBoardScreen(board.id));
    Obf? newLinkedBoard = await Navigator.of(context).push<Obf?>(
      MaterialPageRoute(
        builder: (_) => BoardSelectScreen(
          project: project!,
          eventHandler: widget.eventHandler,
          startingBoard: board,
          popupHistory: widget.popupHistory,
        ),
      ),
    );
    widget.popupHistory?.popScreen();

    if (newLinkedBoard != null) {
      _lastLinkedBoard.push(newLinkedBoard);
    }
  }

  void changeBorderColor(Color color) {
    setState(() {
      ColorData colorData = ColorDataCovertor.fromColorToColorData(color);
      widget.restorableButtonDiff
          ?.update(ButtonData.borderColorKey, colorData.toString());
      buttonController.setBorderColor(colorData);
    });
  }

  void _showColorChangeDialog(
    void Function(Color color) onColorChanged, {
    Color? initialColor,
    bool removeFromPopupHistory = true,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        title: Text("pick a color"),
        content: SingleChildScrollView(
          child: ColorPicker(
              pickerColor: initialColor ?? Colors.white,
              onColorChanged: onColorChanged),
        ),
      ),
    ).then((_) {
      if (removeFromPopupHistory) {
        widget.popupHistory?.popScreen();
      }
    });
  }

  Widget _actionConfig(ParrotButtonNotifier controller, double width) {
    return subsection(
      "acions:",
      ActionConfig(
        controller: controller,
        width: width,
        onChange: _updateActions,
        totalHeight: 300,
        topBarHeight: 50,
      ),
    );
  }

  void _updateActions(List<ParrotAction> actions) {
    String toNames(ParrotAction action) => action.name;

    widget.restorableButtonDiff?.update(
      ButtonData.actionsKey,
      actions.map(toNames).toList(),
    );
  }

  Widget _linkedBoard(double width) {
    Widget customSelectionContent = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Row(
        children: [
          ListenableBuilder(
              listenable: _lastLinkedBoard,
              builder: (context, child) {
                return Flexible(
                  child: Text(
                    "${_lastLinkedBoard.currentBoardOrNull?.name ?? "none"}: ",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
          Flexible(
            child: TextButton(
              onPressed: () async => _selectBoard(),
              style: TextButton.styleFrom(backgroundColor: Colors.orange),
              child: Text("select board"),
            ),
          ),
          Flexible(
            child: TextButton(
              onPressed: () async {
                if (project == null) {
                  throw Exception("A project is needed to create a board");
                }
                showCreateBoardDialog(
                  context,
                  _lastLinkedBoard,
                  widget.eventHandler,
                  history: widget.popupHistory,
                );
              },
              style: TextButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(
                "create board",
                style: TextStyle(color: Colors.yellow),
              ),
            ),
          ),
        ],
      ),
    );

    Widget customSelectionSpace = space(maxHeight: 8);

    return subsection(
      "linked board:",
      SegmentedButtonMenu<BoardLinkingActionMode>(
        values: BoardLinkingActionMode.values,
        maxWidth: width,
        getContent: (ld) {
          if (ld == BoardLinkingActionMode.customSelection) {
            return [customSelectionSpace, customSelectionContent];
          }
          return [];
        },
        initialValue: startingMode,
        onChange: _changeSelection,
      ),
    );
  }

  void _changeSelection(dynamic selection) {
    if (selection == BoardLinkingActionMode.none) {
      buttonController.clearAllLinkActions();
    } else if (selection == BoardLinkingActionMode.home) {
      buttonController.setLinkActionToGoHome();
    }

    if (selection is BoardLinkingActionMode?) {
      widget.restorableButtonDiff?.boardLinkingActionMode = selection;
    }
  }

  Widget _audioTypeMenu(double width) {
    final values =
        List<PreferredAudioSourceType>.of(PreferredAudioSourceType.values);
    if (startingAudioSource != PreferredAudioSourceType.alternative) {
      values.remove(PreferredAudioSourceType.alternative);
    }
    Widget ttsContent = _ttsLabel(width);
    Widget fileContent = Row(
      children: [
        ValueListenableBuilder(
            valueListenable: _selectedAudioPath,
            builder: (context, value, _) {
              String name = "none";
              if (value != null) {
                name = p.basenameWithoutExtension(value);
                if (name.startsWith(recordedAudioString)) {
                  name = removeTrailingIncrement(name);
                }
              }
              return Text(
                name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            }),
        TextButton(
          onPressed: () async {
            if (buttonController.projectPath == null) {
              return;
            }
            XFile? audio = await getAudioFile();
            if (audio == null) {
              return;
            }

            _selectedAudioPath.value = await writeTempAudio(
              Directory(buttonController.projectPath!),
              audio,
            );

            _setSound(
              SoundData(
                duration: 0, //TODO
                path: _selectedAudioPath.value,
                id: Obz.generateSoundId(project),
              ),
            );
          },
          child: Text("select audio file"),
        ),
        ValueListenableBuilder(
            valueListenable: recording,
            builder: (context, isRecording, child) {
              return TextButton(
                onPressed: () {
                  recording.value = !isRecording;
                  if (buttonController.projectPath == null) {
                    throw Exception("needs audio path for recording");
                  }

                  final projectPath = buttonController.projectPath!;
                  final audioPath = tmpAudioPath(projectPath);
                  if (!isRecording) {
                    final audioDir = Directory(audioPath);
                    audioDir.createSync(recursive: true);
                    String name = recordedAudioString;

                    Iterable<String> existingNames = Directory(audioPath)
                        .listSync()
                        .whereType<File>()
                        .map((f) => f.path)
                        .map(p.basenameWithoutExtension);

                    name = determineNoncollidingName(name, existingNames);
                    MyAudioRecorder().start(
                      parentDirectory: audioDir,
                      fileName: name,
                    );
                    currentRecordingPath = p.relative(
                        p.setExtension(
                          p.join(
                            audioPath,
                            name,
                          ),
                          '.wav',
                        ),
                        from: projectPath);
                  } else {
                    MyAudioRecorder().stop();
                    if (_selectedAudioPath.value != null) {
                      File(
                        p.join(projectPath, _selectedAudioPath.value!),
                      ).deleteSync();
                    }
                    _selectedAudioPath.value = currentRecordingPath!;
                    _setSound(
                      SoundData(
                        duration: 0, //TODO:
                        id: Obz.generateImageId(project),
                        path: currentRecordingPath,
                      ),
                    );
                  }
                },
                child: Text(isRecording ? "stop" : "record"),
              );
            }),
      ],
    );

    return subsection(
      "audio",
      SegmentedButtonMenu<PreferredAudioSourceType>(
        values: values,
        initialValue: startingAudioSource,
        maxWidth: width,
        getContent: (ptype) {
          if (ptype == PreferredAudioSourceType.tts) {
            return [ttsContent];
          }
          if (ptype == PreferredAudioSourceType.file) {
            return [fileContent];
          }
          return [];
        },
        onChange: (ptype) {
          widget.buttonController.data.preferredAudioSourceType = ptype;
          const tts = PreferredAudioSourceType.tts;
          const mute = PreferredAudioSourceType.mute;
          if (ptype == tts || ptype == mute) {
            widget.buttonController.data.sound = null;
          } else if (ptype == PreferredAudioSourceType.file &&
              _selectedAudioPath.value != null) {
            widget.buttonController.data.sound = SoundData(
              duration: 0, //TODO
              path: _selectedAudioPath.value,
              id: Obz.generateImageId(project),
            );
          }

          widget.restorableButtonDiff?.update(
            preferredAudioSourceKey,
            ptype.label,
          );
          widget.restorableButtonDiff?.update(
            ButtonData.soundKey,
            widget.buttonController.data.sound?.toJson(),
          );
        },
      ),
    );
  }

  void _setSound(SoundData sound) {
    widget.restorableButtonDiff?.update(ButtonData.soundKey, sound.toJson());
    buttonController.setSound(sound);
  }

  Widget _ttsLabel(double width) {
    return ValueListenableBuilder(
        valueListenable: _labelController,
        builder: (context, value, child) {
          return textInput(
            "tts says",
            _voclizationController,
            width,
            hintOverride: value.text.trim() != "" ? value.text : null,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    ButtonData buttonData = buttonController.data;
    ColorData? backGroundColorData = buttonData.backgroundColor;
    Color backgroundColor = backGroundColorData?.toColor() ?? Colors.white;
    Color borderColor = buttonData.borderColor?.toColor() ?? Colors.white;
    Widget image = Container();
    const double maxWidth = 500;
    if (buttonData.image != null) {
      image = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 100, maxHeight: 100),
        child: SizedBox.expand(
          child: buttonData.image!
              .toImage(projectPath: buttonController.projectPath),
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textInput("label", _labelController, maxWidth),
          space(),
          image,
          TextButton(
              onPressed: () async {
                if (buttonController.projectPath == null) {
                  return;
                }

                XFile? file = await getImage();
                if (file == null) {
                  return;
                }

                lastSetTempImage?.deleteSync();

                String path = await writeTempImage(
                  Directory(buttonController.projectPath!),
                  file,
                );

                lastSetTempImage =
                    File(p.join(buttonController.projectPath!, path));

                ImageData image = ImageData(
                  path: path,
                  id: Obz.generateImageId(project),
                );

                widget.restorableButtonDiff?.update(
                  ButtonData.imageKey,
                  image.toJson(),
                );
                setState(() {
                  buttonController.setImage(image);
                });
              },
              child: Text("select image")),
          colorPickerButton(
            "background color",
            backgroundColor,
            () {
              widget.popupHistory?.pushScreen(SelectBackgroundColor());
              _showColorChangeDialog(
                changeBackgroundColor,
                initialColor: currentBackgroundColor?.toColor(),
              );
            },
          ),
          space(),
          colorPickerButton(
            "border color",
            borderColor,
            () {
              widget.popupHistory?.pushScreen(SelectBorderColor());
              _showColorChangeDialog(
                changeBorderColor,
                initialColor: currentBorderColor?.toColor(),
              );
            },
          ),
          space(),
          _actionConfig(widget.buttonController, maxWidth),
          space(),
          _linkedBoard(maxWidth),
          space(),
          _audioTypeMenu(maxWidth),
          space(),
          _previewButton(
            "preview",
            buttonController,
            widget.eventHandler,
            maxWidth,
            currentBoard: widget.currentBoard,
          ),
        ],
      ),
    );
  }
}

enum BoardLinkingActionMode {
  none("none"),
  customSelection("custom selection"),
  home("home");

  final String label;
  @override
  String toString() {
    return label;
  }

  const BoardLinkingActionMode(this.label);
}

Widget _previewButton(
  String label,
  ParrotButtonNotifier controller,
  ProjectEventHandler eventHandler,
  double width, {
  Obf? currentBoard,
}) {
  //TODO: might be better if I preserve the size in the grid screen or do something based on the screen size
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      boldText("$label:"),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: width),
        child: SizedBox(
          width: width,
          height: 350,
          child: ParrotButton(
            controller: controller,
            currentBoard: currentBoard,
          ),
        ),
      ),
    ],
  );
}
