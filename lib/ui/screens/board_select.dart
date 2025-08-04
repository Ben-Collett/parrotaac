import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/ui/board_screen_popup_history.dart';
import 'package:parrotaac/ui/codgen/board_screen_popups.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/popups/create_board.dart';
import 'package:parrotaac/ui/util_widgets/board.dart';

class BoardSelectScreen extends StatefulWidget {
  final ParrotProject project;
  final Obf startingBoard;
  final ProjectEventHandler eventHandler;
  final BoardScreenPopupHistory? popupHistory;
  //WARNING: storing the path will only work if I wait to rename a project somehow
  const BoardSelectScreen({
    super.key,
    required this.project,
    required this.startingBoard,
    required this.eventHandler,
    this.popupHistory,
  });

  @override
  State<BoardSelectScreen> createState() => _BoardSelectScreenState();
}

class _BoardSelectScreenState extends State<BoardSelectScreen> {
  late final ValueNotifier<Obf> _currentObfNotfier;
  set _currentObf(Obf obf) => _currentObfNotfier.value = obf;
  Obf get _currentObf => _currentObfNotfier.value;
  @override
  void initState() {
    _currentObfNotfier = ValueNotifier(widget.startingBoard);
    _currentObfNotfier.addListener(() {
      BoardScreenPopup? popup = widget.popupHistory?.topScreen;
      if (popup is SelectBoardScreen) {
        popup.boardId = _currentObfNotfier.value.id;
        widget.popupHistory?.write();
      }
    });

    BoardScreenPopup? popup = widget.popupHistory?.removeNextToRecover();
    if (popup is CreateBoard) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => showCreateBoardDialog(
          context,
          _currentObfNotfier,
          widget.eventHandler,
          history: widget.popupHistory,
          rowCount: popup.rowCount,
          colCount: popup.colCount,
          name: popup.name,
        ),
      );
    }

    super.initState();
  }

  void _changeObf(Obf obf) {
    _currentObf = obf;
  }

  void goToRootBoard() {
    Obf? root = widget.project.root;
    if (root != null) {
      _changeObf(root);
    }
  }

  @override
  void dispose() {
    _currentObfNotfier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //TODO: i should probably replace the back arrow with something
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {
              showCreateBoardDialog(
                context,
                _currentObfNotfier,
                widget.eventHandler,
                history: widget.popupHistory,
              );
            }, //TODO: board createtion process
            child: Text("add board"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_currentObf);
            },
            child: Text("select board"),
          ),
        ],
        centerTitle: true,
        title: ValueListenableBuilder(
          valueListenable: _currentObfNotfier,
          builder: (context, value, child) {
            return DropdownSearch<Obf>(
              compareFn: (item1, item2) => item1.hashCode == item2.hashCode,
              popupProps: PopupProps.menu(
                showSearchBox: true, // Enable search
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: 'Search boards...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              selectedItem: _currentObfNotfier.value,
              items: (f, cs) => widget.project.boards.toList(),
              itemAsString: (obf) => obf.name,
              onChanged: (obf) {
                if (obf != null) {
                  _changeObf(obf);
                }
              },
            );
          },
        ),
      ),
      body: BoardWidget(
        project: widget.project,
        eventHandler: widget.eventHandler,
        showSentenceBar: false,
        currentObfNotfier: _currentObfNotfier,
      ),
    );
  }
}
