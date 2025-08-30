import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';
import 'package:parrotaac/backend/project_restore_write_stream.dart';
import 'package:parrotaac/backend/quick_store.dart';
import 'package:parrotaac/ui/board_modes.dart';
import 'package:parrotaac/ui/codgen/board_screen_popups.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';

import 'map_utils.dart';
import 'project/parrot_project.dart';

class ProjectRestorationData {
  final QuickStore _quickStore;
  static const _boardHistoryKey = "board_history";
  static const _sentenceBoxKey = "sentence_box";
  static const _undoStackKey = "undo_stack";
  static const _redoStackKey = "redo_stack";
  static const _popupHistoryKey = "popup_history";
  static const _openButtonDiffKey = "button_diff";
  static const _currentButtonBoardActionLinkKey = "board_link";
  static const _boardModeKey = "board_mode";
  static const _quickStoreName = "restore_data";
  static const _showSentenceBar = "show_sentence_bar";
  static const _showSideBar = "show_side_bar";

  ProjectRestorationData._(this._quickStore);
  static Future<ProjectRestorationData> fromPath(String path) async {
    QuickStore quickStore = QuickStore(_quickStoreName, path: path);
    if (quickStore.isNotInitialized) await quickStore.initialize();
    return ProjectRestorationData._(quickStore);
  }

  Future<void> writeNewBoardHistory(List<String> boardIds) {
    return _quickStore.writeData(_boardHistoryKey, boardIds);
  }

  Future<void> writeShowSentenceBar(bool value) =>
      _quickStore.writeData(_showSentenceBar, value);
  bool get showSentenceBar => _quickStore[_showSentenceBar] ?? true;

  Future<void> writeShowSideBar(bool value) =>
      _quickStore.writeData(_showSideBar, value);
  bool? get showSideBar => _quickStore[_showSideBar];

  Future<void> removeCurrentButtonData() => Future.wait([
        _quickStore.removeFromKey(_openButtonDiffKey),
        _quickStore.removeFromKey(_currentButtonBoardActionLinkKey)
      ]);

  Future<void> writeSentenceBoxHistory(List<BoardButtonPair> buttons) {
    return _quickStore.writeData(
      _sentenceBoxKey,
      buttons.map((b) => b.asMap).toList(),
    );
  }

  Future<void> writeBoardLinkingAction(String? action) {
    return _quickStore.writeData(_currentButtonBoardActionLinkKey, action);
  }

  Future<void> writeBoardMode(BoardMode mode) {
    return _quickStore.writeData(
      _boardModeKey,
      mode.asString,
    );
  }

  String? get boardLinkingActionMode =>
      _quickStore[_currentButtonBoardActionLinkKey];
  BoardMode get currentBoardMode {
    final currentBoardModeString = _quickStore[_boardModeKey];
    return BoardMode.values.firstWhere(
      (mode) => mode.asString == currentBoardModeString,
      orElse: () => BoardMode.normalMode,
    );
  }

  Future<void> writeUndoStack(List<ProjectEvent> events) => _quickStore
      .writeData(_undoStackKey, events.map((e) => e.encode()).toList());

  Future<void> writeRedoStack(List<ProjectEvent> events) => _quickStore
      .writeData(_redoStackKey, events.map((e) => e.encode()).toList());
  Future<void> writePopupHistory(List<BoardScreenPopup> popupHistory) =>
      _quickStore.writeData(
        _popupHistoryKey,
        popupHistory.map((p) => p.encode()).toList(),
      );

  Future<void> writeButtonDiff(Map<String, dynamic> buttonDiff) =>
      _quickStore.writeData(_openButtonDiffKey, buttonDiff);

  List<ProjectEvent> get currentUndoStack =>
      _convertToEvents(_quickStore[_undoStackKey]);

  List<ProjectEvent> get currentRedoStack =>
      _convertToEvents(_quickStore[_redoStackKey]);

  List<ProjectEvent> _convertToEvents(dynamic data) {
    List<dynamic> events = [];
    if (data is List) {
      events = data;
    }
    return events
        .map(castMapToJsonMap)
        .nonNulls
        .map<ProjectEvent?>(ProjectEvent.decode)
        .nonNulls
        .toList();
  }

  List<BoardScreenPopup> get currentPopupHistory {
    final history = _quickStore[_popupHistoryKey];
    if (history is List) {
      return history
          .map(castMapToJsonMap)
          .nonNulls
          .map<BoardScreenPopup?>(BoardScreenPopup.decode)
          .nonNulls
          .toList();
    }
    return [];
  }

  Map<String, dynamic> get openButtonDiff =>
      deepCastMapToJsonMap(_quickStore[_openButtonDiffKey]) ?? {};

  ///project.root should probably not be null when calling this
  BoardHistoryStack createBoardHistory(ParrotProject project, int historySize) {
    List<String?>? boardIds = _quickStore[_boardHistoryKey];
    if (boardIds == null) {
      return BoardHistoryStack(
        maxHistorySize: historySize,
        currentBoard: project.root!,
      );
    }

    Obf? toBoard(String? id) => id == null ? null : project.findBoardById(id);

    List<Obf> boards = boardIds.map(toBoard).nonNulls.toList();
    if (boards.isEmpty) {
      boards.add(project.root ??
          Obf(
            locale: "en",
            name: "defaultName",
            id: "defaultId",
          ));
    }

    return BoardHistoryStack.fromNonEmptyList(
      boards,
      maxHistorySize: historySize,
    );
  }

  Future<void> close() async {
    await _quickStore.close();
  }

  List<SenteceBoxDisplayEntry> getSentenceBoxData(ParrotProject project) {
    dynamic sentenceBoxData = _quickStore[_sentenceBoxKey];
    if (sentenceBoxData is List) {
      SenteceBoxDisplayEntry? toEntry(BoardButtonPair? pair) =>
          _pairToEntry(project, pair);

      return sentenceBoxData
          .whereType<Map>()
          .map(BoardButtonPair.fromMap)
          .map(toEntry)
          .nonNulls
          .toList();
    }
    return [];
  }

  SenteceBoxDisplayEntry? _pairToEntry(
    ParrotProject project,
    BoardButtonPair? pair,
  ) {
    if (pair == null) {
      return null;
    }

    Obf? board = project.findBoardById(pair.boardId);
    ButtonData? buttonData = board?.findButtonById(pair.buttonId);
    if (board == null || buttonData == null) {
      return null;
    }
    return SenteceBoxDisplayEntry(board: board, data: buttonData);
  }
}

enum ScreenName {
  grid("grid"),
  settings("settings"),
  projectSelector("project_selector");

  final String name;
  const ScreenName(this.name);
}
