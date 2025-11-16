import 'package:openboard_wrapper/button_data.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project_restore_write_stream.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';
import 'package:parrotaac/ui/popups/button_config.dart';

class RestorableButtonDiff {
  final Map<String, dynamic> _changes;
  final ProjectRestoreStream? _restoreStream;
  BoardLinkingActionMode?
  _boardLinkingActionMode; //TODO: this is not a very nice approach

  RestorableButtonDiff({
    Map<String, dynamic>? changes,
    BoardLinkingActionMode? boardLinkingAction,
    ProjectRestoreStream? restoreStream,
  }) : _changes = changes ?? {},
       _restoreStream = restoreStream,
       _boardLinkingActionMode = boardLinkingAction;

  void update(String key, dynamic value) {
    _changes[key] = value;

    _restoreStream?.updateCurrentButtonDiff(_changes);
  }

  set boardLinkingActionMode(BoardLinkingActionMode? boardLinkingAction) {
    _boardLinkingActionMode = boardLinkingAction;
    _restoreStream?.updateCurrentButtonBoardLinkingAction(
      _boardLinkingActionMode?.label,
    );
  }

  BoardLinkingActionMode? get boardLinkingActionMode => _boardLinkingActionMode;

  void clear() {
    _changes.clear();
    _boardLinkingActionMode = null;
    _restoreStream?.removeCurrentButtonData();
  }

  void apply(ButtonData bd, {ParrotProject? project}) {
    bd.merge(_changes, project: project);
  }
}
