import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/audio/audio_source.dart';
import 'package:parrotaac/audio/prefered_audio_source.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/image_extensions.dart';
import 'package:parrotaac/extensions/map_extensions.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/popups/button_config.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';
import 'actions/button_actions.dart';

void Function(Obf) _defaultGoToLinkedBoard = (_) {};
const String parrotActionMode = "ext_parrot_action_mode";

class ParrotButtonNotifier extends ChangeNotifier {
  ButtonData _data;
  ButtonData get data => _data;
  VoidCallback? onDelete;
  VoidCallback? onPressOverride;

  set preferredAudioSource(PreferredAudioSourceType preferredAudioSource) {
    _data.extendedProperties[preferredAudioSourceKey] =
        preferredAudioSource.toString();
  }

  bool get parrottActionModeEnabled {
    if (!_data.extendedProperties.containsKey(parrotActionMode)) {
      return false;
    }
    return _data.extendedProperties[parrotActionMode];
  }

  void prependAction(ParrotAction action) {
    _data.actions.insert(0, action.toString());
  }

  Iterable<ParrotAction?> get actions {
    List<String> actionStrings = _data.actions;
    if (actionStrings.isEmpty && _data.action != null) {
      actionStrings.add(_data.action!);
    }
    return actionStrings.map(ParrotAction.fromString);
  }

  void setLinkActionToGoHome() {
    _data.linkedBoard = null;
    _data.loadBoardData = null;
    List<ParrotAction> actions = this.actions.nonNulls.toList();

    if (actions.contains(ParrotAction.home)) {
      return;
    }

    actions.add(ParrotAction.home);

    updateActions(actions);
  }

  void clearAllLinkActions() {
    _data.linkedBoard = null;
    _data.loadBoardData = null;
  }

  void setLinkActionGoToBoard(Obf board) {
    _data.linkedBoard = null;
    List<ParrotAction> actions = this.actions.nonNulls.toList();

    if (!actions.contains(ParrotAction.home)) {
      return;
    }

    actions.removeWhere((action) => action == ParrotAction.home);

    updateActions(actions);
  }

  void updateActions(List<ParrotAction> actions) {
    _data.actions = actions.map((p) => p.toString()).toList();
  }

  void update() {
    notifyListeners();
  }

  void enableParrotActionModeIfDisabled() {
    if (parrottActionModeEnabled) return;

    final bool noActionsInList = _data.actions.isEmpty;
    final bool actionIsNotNull = _data.action != null;
    final bool needToAppendActionToActions = actionIsNotNull && noActionsInList;

    prependAction(ParrotAction.playButton);
    prependAction(ParrotAction.addToSentenceBox);

    if (needToAppendActionToActions) {
      _data.actions.add(_data.action!);
    }
    _data.extendedProperties[parrotActionMode] = true;
  }

  set data(ButtonData data) {
    _data = data;
    notifyListeners();
  }

  void Function(Obf) goToLinkedBoard;
  VoidCallback? goHome;
  ParrotProject? project;
  String? get projectPath => project?.path;
  SentenceBoxController? boxController;

  ParrotButtonNotifier(
      {ButtonData? data,
      bool holdToConfig = false,
      void Function(Obf)? goToLinkedBoard,
      this.boxController,
      this.goHome,
      this.project,
      this.onPressOverride,
      this.onDelete})
      : _data = data ?? ButtonData(),
        goToLinkedBoard = goToLinkedBoard ?? _defaultGoToLinkedBoard;
  AudioSource get audioSource {
    return _data.getSource(projectPath: projectPath);
  }

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
  final bool holdToConfig;
  final ProjectEventHandler eventHandler;
  ButtonData get buttonData => controller.data;
  const ParrotButton({
    super.key,
    required this.controller,
    required this.eventHandler,
    this.holdToConfig = false,
  });
  void onTap() {
    if (controller.onPressOverride != null) {
      controller.onPressOverride!();
    } else {
      controller.enableParrotActionModeIfDisabled();

      if (buttonData.linkedBoard == null) {
        String? id = buttonData.loadBoardData?.id;
        if (id != null) {
          buttonData.linkedBoard = eventHandler.project.findBoardById(id);
        }
      }
      if (buttonData.linkedBoard != null) {
        Obf linkedBoard = buttonData.linkedBoard!;
        controller.goToLinkedBoard(linkedBoard);
      }

      executeActions(controller);
    }
  }

  void onLongPress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        ButtonData data = controller.data;
        Map<String, dynamic> originalJson = controller.data.toJson();
        final List<String> originalActions = List.of(data.actions);
        final SoundData? originalSound = data.sound;
        final ImageData? originalImage = data.image;
        final preferredSoundType = data.preferredAudioSourceType;
        //The sentence box controller has to be null in the config screen to avoid taps in the preview being added to the sentence box
        final sentenceBoxController = controller.boxController;
        controller.boxController = null;
        final goToLinkedBoard = controller.goToLinkedBoard;
        controller.goToLinkedBoard = (_) {};

        IconButton cancelButton = IconButton(
          color: Colors.red,
          icon: Icon(Icons.cancel_rounded),
          onPressed: () {
            data.actions = originalActions;
            controller.goToLinkedBoard = goToLinkedBoard;
            controller.data = data;
            controller.boxController = sentenceBoxController;
            data.sound = originalSound;
            data.preferredAudioSourceType = preferredSoundType;
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
              eventHandler.addConfigureButtonToHistory(
                controller.data.id,
                diff,
                undoDiff,
                originalSound: originalSound,
                originalImage: originalImage,
                newImage: data.image,
                newSound: data.sound,
              );
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
        //if (controller.onDelete != null) {
        // actions.add(deleteButton);
        // }
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

        return AlertDialog(
          content: ButtonConfigPopup(
            buttonController: controller,
            eventHandler: eventHandler,
          ),
          actions: [row],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    void Function(BuildContext)? onLongPress;

    bool holdToConfigIsEnabled = holdToConfig;
    if (holdToConfigIsEnabled) {
      onLongPress = this.onLongPress;
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return StatelessParrotButton(
          onTap: onTap,
          onLongPress: onLongPress,
          projectPath: controller.projectPath,
          buttonData: controller.data,
        );
      },
    );
  }
}

class StatelessParrotButton extends StatelessWidget {
  final ButtonData buttonData;
  final String? projectPath;
  final VoidCallback? onTap;
  final void Function(BuildContext)? onLongPress;
  const StatelessParrotButton({
    super.key,
    required this.buttonData,
    this.onTap,
    this.onLongPress,
    this.projectPath,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> column = [];
    if (buttonData.image != null) {
      column.add(
        Expanded(
          child: buttonData.image!.toImage(projectPath: projectPath),
        ),
      );
    }
    if (buttonData.label != null) {
      column.add(Text(buttonData.label!));
    }

    VoidCallback? onLongPress;
    if (this.onLongPress != null) {
      onLongPress = () {
        this.onLongPress!(context);
      };
    }

    return Material(
      key: UniqueKey(),
      color: buttonData.backgroundColor?.toColor() ?? Colors.white,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
  }
}
