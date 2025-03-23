import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/audio_player.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/sound_extensions.dart';
import 'package:parrotaac/extensions/image_extensions.dart';
import 'package:parrotaac/parrot_project.dart';

//TODO: what if I used a uniquekey + riverpod
//if you want to have a chance at understanding this file read the comments below
//there is a ParrotButtonWidget, this is the actual widget that is ultmately drawn to the screen and has the actual button data
//the UnsafeParrotButton, is a wrapper around the ParrotButtonWidget that allows you to change the widgets state externally using a global key, this class cannot be constructed externally as it's only construcotr is private
//the ParrotButton class is what any external user should use, it takes a callback with an UnsafeParrotButton because having to remember to type to update state after every method is not a practical solution.
class ParrotButton extends StatelessWidget {
  final UnsafeParrotButton _button;
  final double dragWidth;
  final double dragHeight;
  //TODO: it would be nice if I could find a way to determine the size for dragging from the containing parent.
  ParrotButton({
    super.key,
    this.dragWidth = 150,
    this.dragHeight = 150,
    ButtonData? initialData,
  }) : _button = UnsafeParrotButton._(initialData);
  void update(Function(UnsafeParrotButton button) callBack) {
    callBack.call(_button);
    _button._updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<ButtonData>(
      feedback: SizedBox(
        width: dragWidth,
        height: dragHeight,
        child: this,
      ),
      childWhenDragging: Container(
        color: Colors.grey,
      ),
      data: _button._buttonData,
      child: _button,
    );
  }
}

///WARNING: this class should only be invoked in a callback from the ParrotButton class and has no constructor.
class UnsafeParrotButton extends StatelessWidget {
  final _key = GlobalKey<_ParrotButtonWidgetState>();
  final ButtonData? initialData;
  UnsafeParrotButton._(this.initialData);
  ButtonData? get _buttonData => _key.currentState?.buttonData;
  void _updateState() {
    _key.currentState?.updateState();
  }

  set image(ImageData imageData) {
    _buttonData?.image = imageData;
  }

  set sound(SoundData soundData) {
    _buttonData?.sound = soundData;
  }

  set backgroundColor(ColorData colorData) {
    _buttonData?.backgroundColor = colorData;
  }

  set borderColor(ColorData colorData) {
    _buttonData?.borderColor = colorData;
  }

  set label(String label) {
    _buttonData?.label = label;
  }

  @override
  Widget build(BuildContext context) {
    return _ParrotButtonWidget(initialData, key: _key);
  }
}

class _ParrotButtonWidget extends StatefulWidget {
  final ButtonData? initialData;
  const _ParrotButtonWidget(this.initialData, {super.key});

  @override
  State<_ParrotButtonWidget> createState() => _ParrotButtonWidgetState();
}

class _ParrotButtonWidgetState extends State<_ParrotButtonWidget> {
  late final ButtonData buttonData;
  _ParrotButtonWidgetState();

  @override
  void initState() {
    buttonData = widget.initialData ?? ButtonData();
    super.initState();
  }

  //passes up the setState method so callers can manually update the state
  void updateState() {
    setState(() {});
  }

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
    //TODO: I really need find a better way to handle scaling so the text doesn't get cut off if it's tiny and how to handle when an image has a defined width and height.
    List<Widget> column = [];
    if (buttonData.image != null) {
      column.add(buttonData.image!.toImage());
    }
    if (buttonData.label != null) {
      column.add(Flexible(child: Text(buttonData.label!)));
    }
    return Material(
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
  }
}
