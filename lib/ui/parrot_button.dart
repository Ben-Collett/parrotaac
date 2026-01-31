import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/audio/prefered_audio_source.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/image_extensions.dart';
import 'package:parrotaac/extensions/size_extensions.dart';
import 'package:parrotaac/ui/board_screen_popup_history.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/painters/button_shapes.dart';
import 'package:parrotaac/ui/popups/button_config.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';
import 'package:parrotaac/ui/util_widgets/ranged_padding.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';
import 'actions/button_actions.dart';
import 'restore_button_diff.dart';

void Function(Obf) _defaultGoToLinkedBoard = (_) {};
const parrotActionMode = "ext_parrot_action_mode";
const parrotButtonShapeKey = "ext_parrot_shape";
const defaultButtonShape = ParrotButtonShape.square;

class ParrotButtonNotifier extends ChangeNotifier {
  ButtonData _data;
  ButtonData get data => _data;
  ProjectEventHandler eventHandler;
  VoidCallback? onDelete;
  VoidCallback? onPressOverride;

  set preferredAudioSource(PreferredAudioSourceType preferredAudioSource) {
    _data.preferredAudioSourceType = preferredAudioSource;
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

  ParrotButtonShape get shape {
    return ParrotButtonShape.fromString(
          data.extendedProperties[parrotButtonShapeKey],
        ) ??
        defaultButtonShape;
  }

  set shape(ParrotButtonShape shape) {
    data.extendedProperties[parrotButtonShapeKey] = shape.label;
    notifyListeners();
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

  void updateActions(List<ParrotAction> actions) {
    _data.actions = actions.map((p) => p.toString()).toList();
  }

  void setButtonData(ButtonData buttonData) {
    _data = buttonData;
    notifyListeners();
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

  ///if false then won't show label when there is an image
  bool alwaysShowLabel;

  ///must have a buttonData or a project or both
  ParrotButtonNotifier({
    ButtonData? data,
    bool holdToConfig = false,
    void Function(Obf)? goToLinkedBoard,
    this.boxController,
    this.alwaysShowLabel = true,
    this.goHome,
    this.project,
    this.onPressOverride,
    required this.eventHandler,
    this.onDelete,
  }) : _data = data ?? ButtonData(id: Obz.generateButtonId(project)),
       goToLinkedBoard = goToLinkedBoard ?? _defaultGoToLinkedBoard;

  void setLabel(String label) {
    data.label = label;
    notifyListeners();
  }

  void setImage(ImageData? image) {
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

  void setSound(SoundData? sound) {
    data.sound = sound; //doesn't need to rebuild as change is not visual
  }
}

class ParrotButton extends StatelessWidget
    with SelectIndecatorStatusDimensions {
  final ParrotButtonNotifier controller;
  final bool holdToConfig;
  final BoardScreenPopupHistory? popupHistory;
  final Obf? currentBoard;
  final RestorableButtonDiff? restorableButtonDiff;
  static const _padding = .01;

  static const _borderWidthPreportion = .05;
  ButtonData get buttonData => controller.data;
  const ParrotButton({
    super.key,
    required this.controller,
    this.currentBoard,
    this.popupHistory,
    this.restorableButtonDiff,
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
          buttonData.linkedBoard = controller.eventHandler.project
              .findBoardById(id);
        }
      }
      if (buttonData.linkedBoard != null) {
        Obf linkedBoard = buttonData.linkedBoard!;
        controller.goToLinkedBoard(linkedBoard);
      }

      executeActions(controller, board: currentBoard);
    }
  }

  void onLongPress(BuildContext context) => showConfigExistingPopup(
    context: context,
    controller: controller,
    restorableButtonDiff: restorableButtonDiff,
    currentBoard: currentBoard,
    popupHistory: popupHistory,
  );

  @override
  Offset selectIndecatorOffset(Size size) {
    double shift = size.shortestSide * _padding;
    size = size.shrinkBy(shift);
    shift += size.shortestSide * _borderWidthPreportion;
    return Offset(shift, shift);
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
        return ProportionalPadding(
          proportion: _padding,
          child: StatelessParrotButton(
            onTap: onTap,
            onLongPress: onLongPress,
            projectPath: controller.projectPath,
            alwaysShowLabel: controller.alwaysShowLabel,
            buttonData: controller.data,
          ),
        );
      },
    );
  }
}

class StatelessParrotButton extends StatelessWidget {
  final ButtonData buttonData;
  final bool alwaysShowLabel;
  final String? projectPath;
  final VoidCallback? onTap;
  final void Function(BuildContext)? onLongPress;
  const StatelessParrotButton({
    super.key,
    required this.buttonData,
    this.alwaysShowLabel = true,
    this.onTap,
    this.onLongPress,
    this.projectPath,
  });

  ParrotButtonShape get _shape =>
      ParrotButtonShape.fromString(
        buttonData.extendedProperties[parrotButtonShapeKey],
      ) ??
      defaultButtonShape;

  @override
  Widget build(BuildContext context) {
    Widget? image = buttonData.image?.toImage(projectPath: projectPath);

    final bool showLabel = alwaysShowLabel || image == null;

    Widget? text;
    String font =
        Theme.of(context).textTheme.bodyMedium?.fontFamily ?? "Roboto";
    if (showLabel && buttonData.label != null) {
      //for some reason dragging changes the text style/decorations if everything is not explicitly set
      text = Center(
        child: Text(
          buttonData.label!,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            decoration: TextDecoration.none,
            fontFamily: font,
            fontWeight: FontWeight.normal,
            textBaseline: TextBaseline.alphabetic,
            wordSpacing: .5,
            letterSpacing: .25,
          ),
        ),
      );
    }

    VoidCallback? onLongPress;
    if (this.onLongPress != null) {
      onLongPress = () {
        this.onLongPress!(context);
      };
    }

    ParrotButtonShape shape = _shape;

    Color backgroundColor =
        buttonData.backgroundColor?.toColor() ?? Colors.white;
    Color borderColor = buttonData.borderColor?.toColor() ?? Colors.transparent;

    return ShapedButton(
      key: UniqueKey(),
      onPressed: onTap,
      onLongPress: onLongPress,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidthPreportion: ParrotButton._borderWidthPreportion,
      image: image,
      text: text,
      shape: shape,
    );
  }
}
