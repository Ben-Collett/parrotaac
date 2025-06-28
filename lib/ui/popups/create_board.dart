import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openboard_wrapper/grid_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:parrotaac/ui/board_screen_constants.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/popups/cancable_dialog.dart';

import 'popup_utils.dart';

Future<void> showCreateBoardDialog(
  BuildContext context,
  ValueNotifier<Obf?> currentObf,
  ProjectEventHandler eventHandler,
) async {
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CreateBoardPopup(
          currentObf: currentObf,
          eventHandler: eventHandler,
        );
      });
}

class CreateBoardPopup extends StatefulWidget {
  ///The caller must make sure that the dialog is dismissed before the notfier is disposed
  final ValueNotifier<Obf?> currentObf;
  final ProjectEventHandler eventHandler;
  const CreateBoardPopup({
    super.key,
    required this.currentObf,
    required this.eventHandler,
  });

  @override
  State<CreateBoardPopup> createState() => _CreateBoardPopupState();
}

class _CreateBoardPopupState extends State<CreateBoardPopup> {
  static const defaultNumberOfRows = 3;
  static const defaultNumberOfCols = 3;
  static const defaultBoardName = untitledBoard;
  late final TextEditingController nameController;
  late final TextEditingController rowCountController;
  late final TextEditingController colCountController;

  int get rowCount {
    if (rowCountController.text.isNotEmpty) {
      return int.parse(rowCountController.text);
    }
    return defaultNumberOfRows;
  }

  int get colCount {
    if (colCountController.text.isNotEmpty) {
      return int.parse(colCountController.text);
    }
    return defaultNumberOfCols;
  }

  String get boardName {
    if (nameController.text.isNotEmpty) {
      return nameController.text;
    }
    return defaultBoardName;
  }

  @override
  void initState() {
    nameController = TextEditingController();
    rowCountController = TextEditingController();
    colCountController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    rowCountController.dispose();
    colCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double width = 300;
    return CancableDialog(
      content: SingleChildScrollView(
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textInput("board name", nameController, width,
                  hintOverride: "untitled board"),
              space(),
              textInput(
                "number of rows",
                rowCountController,
                width,
                hintOverride: "$defaultNumberOfRows",
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
              ),
              space(),
              textInput(
                "number of columns",
                TextEditingController(),
                width,
                hintOverride: "$defaultNumberOfCols",
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
              )
            ],
          ),
        ),
      ),
      onAccept: (context) {
        Obz project = widget.eventHandler.project;
        Obf obf = Obf(
          locale: 'en-us',
          name: boardName,
          id: project.generateGloballyUniqueId(prefix: 'bo'),
          grid: GridData.empty(rowCount: rowCount, colCount: colCount),
        );

        widget.eventHandler.addBoard(obf);

        widget.currentObf.value = obf;
        Navigator.of(context).pop();
      },
    );
  }
}
