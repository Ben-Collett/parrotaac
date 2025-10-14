import 'package:parrotaac/backend/quick_store.dart';

import 'parrot_project.dart';

class ProjectSettings {
  static const _quickStoreName = "project_settings";
  static const _showSentenceBar = "show_bar";
  final QuickStoreHiveImp _quickStore;

  ProjectSettings._(this._quickStore);
  static Future<ProjectSettings> fromProject(ParrotProject project) async {
    QuickStoreHiveImp quickStore = QuickStoreHiveImp(
      _quickStoreName,
      path: project.path,
    );
    if (quickStore.isNotInitialized) await quickStore.initialize();
    return ProjectSettings._(quickStore);
  }

  bool get showSentenceBar => _quickStore[_showSentenceBar] ?? true;
  Future<void> close() => _quickStore.close();
  Future<void> writeShowSentenceBar(bool value) =>
      _quickStore.writeData(_showSentenceBar, value);
}
