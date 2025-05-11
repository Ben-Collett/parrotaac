import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:parrotaac/backend/project/temp_files.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/image_extensions.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import 'package:parrotaac/utils.dart';
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

  late final ParrotButtonNotifier buttonController;

  ///the last image set after opening the create screen, this will be null until the user sets an image, even if the board being edited already had an image
  File? lastSetTempImage;
  @override
  void initState() {
    buttonController = widget.buttonController;
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

  @override
  Widget build(BuildContext context) {
    ButtonData buttonData = buttonController.data;
    ColorData? backGroundColorData = buttonData.backgroundColor;
    Color backgroundColor = backGroundColorData?.toColor() ?? Colors.white;
    Color borderColor = buttonData.borderColor?.toColor() ?? Colors.white;
    Widget image = Container();
    if (buttonData.image != null) {
      image = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 100, maxHeight: 100),
        child: SizedBox.expand(
            child: buttonData.image!
                .toImage(projectPath: buttonController.projectPath)),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textInput("label", _labelController),
          _space(),
          _textInput("voclization", _voclizationController),
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
          _previewButton("preview", buttonController),
        ],
      ),
    );
  }
}

Widget _space({double maxHeight = 20}) {
  return ConstrainedBox(
    constraints: BoxConstraints(minHeight: 0, maxHeight: maxHeight),
    child: Container(),
  );
}

Widget _textInput(String label, TextEditingController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _boldText("$label:"),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 300),
        child: SizedBox(
          width: 300,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "enter $label here",
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _colorPicker(
  String label,
  Color color,
  VoidCallback showColorChangeDialog,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _boldText("$label:"),
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
      )
    ],
  );
}

Widget _previewButton(String label, ParrotButtonNotifier controller) {
  //TODO: might be better if I preserve the size in the grid screen or do something based on the screen size
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _boldText("$label:"),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 300, maxHeight: 300),
        child: SizedBox(
          width: 300,
          height: 300,
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
