import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/audio/prefered_audio_source.dart';
import 'package:parrotaac/audio_recorder.dart';
import 'package:parrotaac/backend/project/temp_files.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/image_extensions.dart';
import 'package:parrotaac/file_utils.dart';
import 'package:parrotaac/ui/actions/button_actions.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import 'package:parrotaac/ui/screens/board_select.dart';
import 'package:parrotaac/ui/util_widgets/action_modifier.dart';
import 'package:parrotaac/ui/util_widgets/segmented_button_menu.dart';
import 'package:parrotaac/utils.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';
import 'package:path/path.dart' as p;

class ButtonConfigPopup extends StatefulWidget {
  final ParrotButtonNotifier buttonController;
  const ButtonConfigPopup({super.key, required this.buttonController});

  @override
  State<ButtonConfigPopup> createState() => _ButtonConfigPopupState();
}

class _ButtonConfigPopupState extends State<ButtonConfigPopup> {
  //WARNING: still need to dsipose these
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _voclizationController = TextEditingController();
  late final ValueNotifier<Obf?> _lastLinkedBoard;
  late final ValueNotifier<String?> _selectedAudioPath;
  final ValueNotifier<bool> recording = ValueNotifier(false);
  String? currentRecordingPath;
  static const String recordedAudioString = "recorded_audio";

  late final ParrotButtonNotifier buttonController;
  ParrotAction selectedAction = ParrotAction.playButton;

  late final BoardLinkingActionMode startingMode;
  late final PreferredAudioSourceType startingAudioSource;
  @override
  void dispose() {
    _voclizationController.dispose();
    _labelController.dispose();
    recording.dispose();
    _selectedAudioPath.dispose();
    _lastLinkedBoard.dispose();
    buttonController.dispose();
    super.dispose();
  }

  ///the last image set after opening the create screen, this will be null until the user sets an image, even if the board being edited already had an image
  File? lastSetTempImage;
  @override
  void initState() {
    buttonController = widget.buttonController;
    _lastLinkedBoard = ValueNotifier(buttonController.data.linkedBoard);
    buttonController.enableParrotActionModeIfDisabled();
    _selectedAudioPath = ValueNotifier(buttonController.data.sound?.path);
    _labelController.text = buttonController.data.label ?? "";
    _voclizationController.text = buttonController.data.voclization ?? "";
    _labelController.addListener(
      () {
        buttonController.setLabel(_labelController.text);
      },
    );
    _voclizationController.addListener(() {
      if (_voclizationController.text.trim() == "") {
        buttonController.data.voclization = null;
      } else {
        buttonController.data.voclization = _voclizationController.text;
      }
    });

    if (buttonController.data.linkedBoard != null) {
      startingMode = BoardLinkingActionMode.customSelection;
    } else if (buttonController.actions.contains(ParrotAction.home)) {
      startingMode = BoardLinkingActionMode.home;
    } else {
      startingMode = BoardLinkingActionMode.none;
    }

    startingAudioSource = widget.buttonController.data.preferredAudioSourceType;
    super.initState();
  }

  void changeBackgroundColor(Color color) {
    setState(() {
      buttonController
          .setBackgroundColor(ColorDataCovertor.fromColorToColorData(color));
    });
  }

  void changeBorderColor(Color color) {
    setState(() {
      buttonController
          .setBorderColor(ColorDataCovertor.fromColorToColorData(color));
    });
  }

  void _showColorChangeDialog(void Function(Color color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        title: Text("pick a color"),
        content: SingleChildScrollView(
          child: ColorPicker(
              pickerColor: buttonController.data.backgroundColor?.toColor() ??
                  Colors.white,
              onColorChanged: onColorChanged),
        ),
      ),
    );
  }

  Widget _actionConfig(ParrotButtonNotifier controller, double width) {
    return _subsection(
      "acions:",
      ActionConfig(
        controller: controller,
        width: width,
        totalHeight: 300,
        topBarHeight: 50,
      ),
    );
  }

  Widget _linkedBoard(double width) {
    Widget customSelectionContent = Row(
      children: [
        ValueListenableBuilder(
            valueListenable: _lastLinkedBoard,
            builder: (context, value, child) {
              return Text("${value?.name ?? "none"}: ");
            }),
        TextButton(
            onPressed: () async {
              if (widget.buttonController.project == null) {
                throw Exception("A project is needed to select a board");
              }

              Obf? newLinkedBoard = await Navigator.of(context).push<Obf?>(
                MaterialPageRoute(
                  builder: (_) => BoardSelectScreen(
                    project: buttonController.project!,
                    startingBoard: _lastLinkedBoard.value ??
                        buttonController.project!.root!,
                  ),
                ),
              );

              if (newLinkedBoard != null) {
                _lastLinkedBoard.value = newLinkedBoard;
                buttonController.data.linkedBoard = newLinkedBoard;
              }
            },
            style: TextButton.styleFrom(backgroundColor: Colors.orange),
            child: Text("select board"))
      ],
    );

    Widget customSelectionSpace = _space(maxHeight: 8);

    return _subsection(
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
        onChange: (selection) {
          if (selection == BoardLinkingActionMode.none) {
            buttonController.clearAllLinkActions();
          } else if (selection == BoardLinkingActionMode.home) {
            buttonController.setLinkActionToGoHome();
          }
        },
      ),
    );
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
            final String projectPath = buttonController.projectPath!;
            XFile? audio = await getAudioFile();
            if (audio == null) {
              return;
            }
            String? audioPath = _selectedAudioPath.value;
            File? file;
            if (audioPath != null) {
              file = File(p.join(projectPath, audioPath));
            }
            if (file != null && file.existsSync()) {
              file.deleteSync();
            }

            _selectedAudioPath.value = await writeTempAudio(
              Directory(buttonController.projectPath!),
              audio,
            );

            buttonController.setSound(
              SoundData(
                duration: 0, //TODO
                path: _selectedAudioPath.value,
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
                    buttonController.setSound(
                      SoundData(
                        duration: 0, //TODO:
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

    return _subsection(
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
            );
          }
        },
      ),
    );
  }

  Widget _ttsLabel(double width) {
    return ValueListenableBuilder(
        valueListenable: _labelController,
        builder: (context, value, child) {
          return _textInput(
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
          _textInput("label", _labelController, maxWidth),
          _space(),
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

                ImageData image = ImageData(path: path);
                setState(() {
                  buttonController.setImage(image);
                });
              },
              child: Text("select image")),
          _colorPicker(
            "background color",
            backgroundColor,
            () => _showColorChangeDialog(changeBackgroundColor),
          ),
          _space(),
          _colorPicker(
            "border color",
            borderColor,
            () => _showColorChangeDialog(changeBorderColor),
          ),
          _space(),
          _actionConfig(widget.buttonController, maxWidth),
          _space(),
          _linkedBoard(maxWidth),
          _space(),
          _audioTypeMenu(maxWidth),
          _space(),
          _previewButton("preview", buttonController, maxWidth),
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

Widget _space({double maxHeight = 20}) {
  return ConstrainedBox(
    constraints: BoxConstraints(minHeight: 0, maxHeight: maxHeight),
    child: Container(),
  );
}

Widget _textInput(
  String label,
  TextEditingController controller,
  double maxWidth, {
  String? hintOverride,
}) {
  return _subsection(
    "$label:",
    ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        width: maxWidth,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintOverride ?? "enter $label here",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    ),
  );
}

Widget _colorPicker(
  String label,
  Color color,
  VoidCallback showColorChangeDialog,
) {
  return _subsection(
      "$label:",
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: MaterialButton(
            onPressed: showColorChangeDialog,
            color: color,
          ),
        ),
      ));
}

Widget _previewButton(
  String label,
  ParrotButtonNotifier controller,
  double width,
) {
  //TODO: might be better if I preserve the size in the grid screen or do something based on the screen size
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _boldText("$label:"),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: width),
        child: SizedBox(
          width: width,
          height: 350,
          child: ParrotButton(controller: controller),
        ),
      ),
    ],
  );
}

Widget _boldText(String text) {
  return Text(
    text,
    textAlign: TextAlign.left,
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget _subsection(String text, Widget child) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _boldText(text),
      child,
    ],
  );
}
