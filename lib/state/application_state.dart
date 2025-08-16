import 'package:parrotaac/state/has_state.dart';
import 'package:parrotaac/state/project_selector_state.dart';

ApplicationState _appState = ApplicationState();

ApplicationState get appState =>_appState;

void newAppstate(){
    _appState.dispose();
    _appState = ApplicationState();
}



//TODO: add open project state
class ApplicationState with HasState {
  ProjectSelectorState? _projectSelectorState;
  ProjectSelectorState getProjectSelectorState() {
    _projectSelectorState ??= ProjectSelectorState();
    return _projectSelectorState!;
  }

  void disposeOfProjectSelector() {
    _projectSelectorState?.dispose();
    _projectSelectorState = null;
  }

  @override
  void dispose() {
    _projectSelectorState?.dispose();
  }
}
