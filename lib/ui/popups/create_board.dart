import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openboard_wrapper/grid_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/ui/board_screen_constants.dart';
import 'package:parrotaac/ui/board_screen_popup_history.dart';
import 'package:parrotaac/ui/codgen/board_screen_popups.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/popups/cancable_dialog.dart';

import 'popup_utils.dart';

Future<void> showCreateBoardDialog(
  BuildContext context,
  BoardHistoryStack boardHistory,
  ProjectEventHandler eventHandler, {
  BoardScreenPopupHistory? history,
  int? rowCount,
  int? colCount,
  String? name,
}) async {
  history?.pushScreen(
    CreateBoard(rowCount: rowCount, colCount: colCount, name: name),
  );
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CreateBoardPopup(
          boardHistory: boardHistory,
          eventHandler: eventHandler,
          history: history,
          initialRowCount: rowCount,
          initialColCount: colCount,
          initialName: name,
        );
      }).then((_) => history?.popScreen());
}

class CreateBoardPopup extends StatefulWidget {
  ///The caller must make sure that the dialog is dismissed before the notfier is disposed
  final BoardHistoryStack boardHistory;
  final ProjectEventHandler eventHandler;
  final BoardScreenPopupHistory? history;
  final int? initialRowCount;
  final int? initialColCount;
  final String? initialName;
  const CreateBoardPopup({
    super.key,
    required this.boardHistory,
    required this.eventHandler,
    this.initialName,
    this.initialColCount,
    this.initialRowCount,
    this.history,
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
    nameController = TextEditingController(text: widget.initialName);
    rowCountController =
        TextEditingController(text: widget.initialRowCount?.toString());
    colCountController =
        TextEditingController(text: widget.initialColCount?.toString());

    nameController.addListener(_updateName);
    rowCountController.addListener(_updateRowCount);
    colCountController.addListener(_updateColCount);
    super.initState();
  }

  void _updateName() {
    CreateBoard? popup = widget.history?.topScreen as CreateBoard?;
    if (nameController.text.isNotEmpty) {
      popup?.name = boardName;
    } else {
      popup?.name = null;
    }
    if (popup != null) widget.history?.write();
  }

  void _updateRowCount() {
    CreateBoard? popup = widget.history?.topScreen as CreateBoard?;
    if (rowCountController.text.isNotEmpty) {
      popup?.rowCount = rowCount;
    } else {
      popup?.rowCount = null;
    }
    if (popup != null) widget.history?.write();
  }

  void _updateColCount() {
    CreateBoard? popup = widget.history?.topScreen as CreateBoard?;
    if (colCountController.text.isNotEmpty) {
      popup?.colCount = colCount;
    } else {
      popup?.colCount = null;
    }
    if (popup != null) widget.history?.write();
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
                colCountController,
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
          id: Obz.generateRandomBoardId(project),
          grid: GridData.empty(rowCount: rowCount, colCount: colCount),
        );

        widget.eventHandler.addBoard(obf);

        widget.boardHistory.push(obf);
        Navigator.of(context).pop();
      },
    );
  }
}
