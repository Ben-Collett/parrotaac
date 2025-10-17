import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parrotaac/backend/global_restoration_data.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project/project_interface.dart';
import 'package:parrotaac/project_selector_constants.dart';
import 'package:parrotaac/restorative_navigator.dart';
import 'package:parrotaac/state/application_state.dart';
import 'package:parrotaac/state/project_dir_state.dart';
import 'package:parrotaac/state/project_selector_state.dart';
import 'package:parrotaac/ui/painters/heart.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_lock.dart';
import 'package:parrotaac/ui/popups/login_popup.dart';
import 'package:parrotaac/ui/popups/show_restorable_popup.dart';
import 'package:parrotaac/ui/popups/support_popup.dart';
import 'package:parrotaac/ui/settings/settings_themed_appbar.dart';
import 'package:parrotaac/ui/util_widgets/multi_listenable_builder.dart';
import 'package:parrotaac/utils.dart';

import 'backend/project/default_project.dart.dart';
import 'backend/project/import_utils.dart';
import 'backend/project/project_utils.dart';
import 'file_utils.dart';
import 'ui/popups/loading.dart';
import 'ui/widgets/displey_entry.dart';

List<DisplayEntry> unfilteredEntries({
  bool selectMode = false,
  double? imageWidth,
  double? imageHeight,
  TextStyle? textStyle,
}) => defaultProjectDirListener.data
    .map(
      (d) => DisplayEntry(
        key: ValueKey(d.name),
        data: d,
        imageWidth: imageWidth,
        selectMode: _selectorState.selectModeNotifier,
        imageHeight: imageHeight,
        textStyle: textStyle,
      ),
    )
    .toList();

List<DisplayEntry> filteredEntries(
  String search, {
  double? imageWidth,
  bool selectMode = false,
  double? imageHeight,
  TextStyle? textStyle,
}) {
  bool match(Text text) => text.data?.startsWith(search) ?? true;
  return unfilteredEntries(
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    selectMode: selectMode,
    textStyle: textStyle,
  ).where((entry) => match(entry.displayName)).toList();
}

class ProjectSelector extends StatefulWidget {
  const ProjectSelector({super.key});

  @override
  State<ProjectSelector> createState() => _ProjectSelectorState();
}

class _ProjectSelectorState extends State<ProjectSelector> {
  final _state = _selectorState;

  void onRefresh() => setState(() {});
  @override
  void initState() {
    defaultProjectDirListener.addOnRefreshListener(onRefresh);
    List<DisplayData> dataList = defaultProjectDirListener.data;

    Set<String>? selectedNames =
        globalRestorationQuickstore[selectedProjectNamesKey]?.toSet();

    if (selectedNames != null) {
      for (final data in dataList) {
        if (selectedNames.contains(data.name)) {
          _selectorState.selectedNotifier.addIfNotNull(data);
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      restorePopups();
    });

    super.initState();
  }

  void restorePopups() {
    List<DisplayData> dataList = defaultProjectDirListener.data;

    ProjectDialog? dialog = ProjectDialog.fromName(
      globalRestorationQuickstore[currentProjectSelectorDialogKey],
    );

    switch (dialog) {
      case ProjectDialog.loginDialog:
        showSigninPopup(context);
        break;
      case ProjectDialog.createProjectDialog:
        _showCreateProjectDialog(
          context,
          name: globalRestorationQuickstore[newProjectNameKey],
        );
        break;
      case ProjectDialog.bulkDeleteDialog:
        _showBulkDeleteDialog(context);
        break;
      case ProjectDialog.normalDeleteDialog:
        DisplayData? data = dataList
            .where(
              (data) =>
                  data.name == globalRestorationQuickstore[normalDeleteNameKey],
            )
            .firstOrNull;
        if (data != null) {
          showDeleteDisplayDataDialog(context, data);
        }
        break;
      case ProjectDialog.supportDialog:
        _showSupportPopup(context);
      case null:
        break;
    }
  }

  @override
  void dispose() {
    defaultProjectDirListener.clearListeners();
    appState.disposeOfProjectSelector();
    super.dispose();
  }

  Widget _iconButtonThatIsDisabledWhenSelectedNotfierIsEmpty(
    Icon icon, {
    required VoidCallback onPressed,
  }) {
    return ValueListenableBuilder(
      valueListenable: _selectorState.selectedNotifier.emptyNotifier,
      builder: (context, isEmpty, _) {
        VoidCallback? outputOnPressed;
        if (!isEmpty) {
          outputOnPressed = onPressed;
        }
        return IconButton(onPressed: outputOnPressed, icon: icon);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double topHeight = 50;
    const double bottomHeight = 25;
    Widget top = SizedBox(
      height: topHeight,
      child: Container(
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SearchBar(textController: _state.searchTextController),
            ValueListenableBuilder(
              valueListenable: _state.selectModeNotifier,
              builder: (context, selectMode, child) {
                String text = selectMode ? "done" : "select";
                List<Widget> children = [];

                if (selectMode) {
                  children.add(
                    _iconButtonThatIsDisabledWhenSelectedNotfierIsEmpty(
                      Icon(Icons.delete),
                      onPressed: () {
                        _showBulkDeleteDialog(context);
                      },
                    ),
                  );
                  children.add(
                    _iconButtonThatIsDisabledWhenSelectedNotfierIsEmpty(
                      Icon(Icons.folder),
                      onPressed: () {
                        showAdminLockPopup(
                          context: context,
                          onAccept: () => _bulkExport(context),
                        );
                      },
                    ),
                  );
                }

                children.addAll([
                  Container(
                    color: Colors.yellow,
                    child: TextButton(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(text, key: ValueKey(text)),
                      ),
                      onPressed: () {
                        _selectorState.selectedNotifier.clear();
                        _state.selectModeNotifier.value = !selectMode;
                      },
                    ),
                  ),
                  Container(
                    color: Colors.orangeAccent,
                    child: TextButton(
                      onPressed: () => _showCreateProjectDialog(context),
                      child: Text("create project"),
                    ),
                  ),
                ]);
                return Row(children: children);
              },
            ),
          ],
        ),
      ),
    );
    Widget bottom = SizedBox(
      height: bottomHeight,
      child: Container(
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BoardCountText(textController: _state.stringTextController),
            DonationButton(),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: SettingsThemedAppbar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ParrotAAC'),
            Row(
              children: [
                LoginButton(),
                IconButton(
                  icon: Icon(Icons.file_download_outlined),
                  onPressed: () async {
                    final time = DateTime.now();
                    final toImport = await getFilesPaths(["obf", "obz"]);
                    if (context.mounted) {
                      showLoadingDialog(context, 'importing');
                    }

                    List<String> importedPaths = await Future.wait(
                      toImport.map(
                        (path) => import(path, lastAccessedTime: time),
                      ),
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }

                    for (String path in importedPaths) {
                      defaultProjectDirListener.add(Directory(path));
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () => RestorativeNavigator().goToSettings(context),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        //ensures that it looks normal when there is no data or a loading circle
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          top,
          Flexible(child: SelectorListView()),
          bottom,
        ],
      ),
    );
  }
}

class DonationButton extends StatelessWidget {
  const DonationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ElevatedButton(
        onPressed: () => _showSupportPopup(context),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.only(left: 8, right: 8),
        ),
        child: const Row(
          children: [
            CustomPaint(painter: HeartPainter(), size: Size(20, 20)),
            Text("support", overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

Future<void> _showCreateProjectDialog(
  BuildContext context, {
  String? name,
}) async {
  final TextEditingController controller = TextEditingController(text: name);
  final formKey = GlobalKey<FormState>();

  controller.addListener(() async {
    await globalRestorationQuickstore.writeData(
      newProjectNameKey,
      controller.text,
    );
  });

  return showRestorableDialog(
    context: context,
    builder: (context) =>
        CreateProjectDialog(formKey: formKey, controller: controller),
    mainLabel: currentProjectSelectorDialogKey,
    fieldLabels: [newProjectNameKey, newProjectImagePathKey],
    mainLabelValue: ProjectDialog.createProjectDialog.name,
    adminLocked: true,
  );
}

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({
    super.key,
    required this.formKey,
    required this.controller,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  Future<XFile?>? _image;
  void setImage(Future<XFile?> image) {
    writeNewImagePath(image);
    setState(() {
      _image = image;
    });
  }

  @override
  void initState() {
    if (globalRestorationQuickstore[newProjectImagePathKey] != null) {
      _image = Future.value(
        XFile(globalRestorationQuickstore[newProjectImagePathKey]),
      );
    }
    super.initState();
  }

  Future<void> writeNewImagePath(Future<XFile?> fileFuture) async {
    XFile? file = await fileFuture;
    await globalRestorationQuickstore.writeData(
      newProjectImagePathKey,
      file?.path,
    );
  }

  @override
  Widget build(BuildContext context) {
    String? validate(String? text, List<String> names) {
      if (names.contains(text)) return "name already used";
      return null;
    }

    double maxWidth = 250;
    return AlertDialog(
      title: Text('Create Project'),
      content: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: 0, maxWidth: maxWidth),
                child: SizedBox(
                  width: maxWidth,
                  child: Builder(
                    builder: (context) {
                      List<String> displayNames = unfilteredEntries()
                          .map((d) => d.displayName.data)
                          .whereType<String>()
                          .toList();
                      List<Widget> column = [
                        TextFormField(
                          controller: widget.controller,
                          validator: (text) => validate(text, displayNames),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Project Name",
                          ),
                        ),
                      ];

                      if (_image != null) {
                        column.add(
                          FutureBuilder(
                            future: _image,
                            builder: (_, snapshot) {
                              if (snapshot.data == null) {
                                return SizedBox(width: 0, height: 0);
                              }
                              XFile data = snapshot.requireData!;
                              return ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: 100),
                                child: imageFromPath(data.path),
                              );
                            },
                          ),
                        );
                      }
                      column.add(
                        TextButton(
                          child: Text("select project image"),
                          onPressed: () => setImage(getImage()),
                        ),
                      );

                      return Column(children: column);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          color: Colors.red,
          icon: Icon(Icons.cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        IconButton(
          color: Colors.green,
          icon: Icon(Icons.check),
          onPressed: () async {
            // Trigger form validation
            if (widget.formKey.currentState!.validate()) {
              String? imagePath;
              if (_image != null) {
                XFile? image = await _image;
                imagePath = image?.path;
              }

              final path = await determineValidProjectPath(
                widget.controller.text,
              );
              await writeDefaultProject(
                widget.controller.text,
                path: path,
                projectImagePath: imagePath,
              );

              if (context.mounted) {
                Navigator.of(context).pop();
              }
              defaultProjectDirListener.add(Directory(path));
            }
          },
        ),
      ],
    );
  }
}

class SearchBar extends StatelessWidget {
  final TextEditingController textController;
  const SearchBar({super.key, required this.textController});

  @override
  Widget build(BuildContext context) {
    //TODO: I should fine a way to not have the width constant

    return Container(
      width: 200,
      color: Colors.white,
      //could add autocomplete but it looks bad and provides little advantage
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: "search...",
        ),
        controller: textController,
      ),
    );
  }
}

class BoardCountText extends StatelessWidget {
  final ValueNotifier<String> textController;
  const BoardCountText({super.key, required this.textController});
  @override
  Widget build(BuildContext context) {
    return MultiListenableBuilder(
      listenables: [
        _selectorState.searchTextController,
        defaultProjectDirListener,
      ],
      builder: (context, child) {
        return Text(
          '${filteredEntries(_selectorState.searchTextController.text).length} boards',
        );
      },
    );
  }
}

class DisplayView extends StatefulWidget {
  final TextEditingController searchController;
  const DisplayView({super.key, required this.searchController});

  @override
  State<DisplayView> createState() => _DisplayViewState();
}

class _DisplayViewState extends State<DisplayView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SelectorListView();
  }
}

class SelectorListView extends StatefulWidget {
  final Function(Directory?)? onSelect;
  final Function(Directory?)? onDeselect;

  const SelectorListView({super.key, this.onSelect, this.onDeselect});

  @override
  State<SelectorListView> createState() => _SelectorListViewState();
}

class _SelectorListViewState extends State<SelectorListView> {
  final listKey = GlobalKey<AnimatedListState>();
  late final List<DisplayEntry> entries;

  DisplayEntry makeDisplayEntry(DisplayData data) => DisplayEntry(
    data: data,
    imageWidth: 75,
    imageHeight: 98,
    selectMode: _selectorState.selectModeNotifier,
    textStyle: const TextStyle(fontSize: 50),
  );

  void addItem(DisplayData data) {
    insertItem(0, data);
  }

  void insertItem(int index, DisplayData data) {
    entries.insert(index, makeDisplayEntry(data));
    listKey.currentState!.insertItem(index);
  }

  void remove(DisplayData removedData) {
    int? removedIndex;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].data == removedData) {
        removedIndex = i;
        break;
      }
    }
    if (removedIndex != null) {
      final removedItem = entries.removeAt(removedIndex);

      listKey.currentState!.removeItem(
        removedIndex,
        _deleteBuilder(removedItem),
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Widget Function(BuildContext, Animation<double>) _deleteBuilder(
    Widget removed,
  ) =>
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: 0.0,
        child: FadeTransition(opacity: animation, child: removed),
      );

  @override
  void initState() {
    entries = unfilteredEntries(
      imageWidth: 75,
      imageHeight: 98,
      selectMode: _selectorState.selectMode,
      textStyle: const TextStyle(fontSize: 50),
    );

    defaultProjectDirListener.addOnDeleteListener(remove);
    defaultProjectDirListener.addOnAddListener(addItem);
    super.initState();
  }

  @override
  void dispose() {
    defaultProjectDirListener.removeOnDeleteListener(remove);
    defaultProjectDirListener.removeOnAddListener(addItem);
    super.dispose();
  }

  Widget itemBuilder(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) {
    if (index >= entries.length) {
      return const SizedBox.shrink();
    }

    final item = entries[index];
    final borderColor = Colors.grey.withAlpha(127);

    return ValueListenableBuilder(
      valueListenable: _selectorState.stringTextController,
      builder: (context, value, child) {
        final bool hasBorder =
            index < entries.length - 1 &&
            entries[index].data.name.startsWith(_selectorState.searchText);

        return SizeTransition(
          sizeFactor: animation,
          key: ValueKey(entries[index].data.name),
          axisAlignment: 0.0,
          child: FadeTransition(
            opacity: animation,
            child: Container(
              decoration: BoxDecoration(
                border: hasBorder
                    ? Border(bottom: BorderSide(color: borderColor, width: 1))
                    : null,
              ),
              child: item,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiListenableBuilder(
      listenables: [_selectorState.selectModeNotifier],
      builder: (context, _) {
        return AnimatedList(
          key: listKey,
          initialItemCount: entries.length,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}

ProjectSelectorState get _selectorState => appState.getProjectSelectorState();

Future<void> _showBulkDeleteDialog(BuildContext context) async {
  return showRestorableDialog(
    context: context,
    builder: (context) {
      List<String> toRemoveNames = _selectorState.selectedNotifier.dataAsDirs
          .map(ParrotProjectDisplayData.fromDir)
          .map((d) => d.name)
          .toList();

      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("are you sure you want to delete the following:"),
              SingleChildScrollView(
                child: Column(
                  children: toRemoveNames
                      .map(
                        (n) => Text(
                          n,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                      .map(
                        (n) => ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 220),
                          child: n,
                        ),
                      )
                      .toList(),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _bulkDelete(context);
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(backgroundColor: Colors.red),
                    child: Text("yes"),
                  ),
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    style: TextButton.styleFrom(backgroundColor: Colors.green),
                    child: Text("no"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
    mainLabel: currentProjectSelectorDialogKey,
    adminLocked: true,
    mainLabelValue: ProjectDialog.bulkDeleteDialog.name,
  );
}

Future<void> _showSupportPopup(BuildContext context) async {
  await globalRestorationQuickstore.writeData(
    currentProjectSelectorDialogKey,
    ProjectDialog.supportDialog.name,
  );
  if (context.mounted) {
    return showSupportDialog(
      context,
      quickStore: globalRestorationQuickstore,
    ).then((_) async {
      await globalRestorationQuickstore.removeFromKey(
        currentProjectSelectorDialogKey,
      );
    });
  }
}

Future<void> _bulkDelete(BuildContext context) async {
  showLoadingDialog(
    context,
    "delete ${_selectorState.selectedNotifier.length}",
  );
  final dataSet = Set.from(_selectorState.selectedNotifier.data);
  List<Future> deletions = [];
  for (DisplayData data in dataSet) {
    if (data.path != null) {
      deletions.add(Directory(data.path!).delete(recursive: true));
    }
    defaultProjectDirListener.delete(data);
  }
  await Future.wait(deletions);
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}

void _bulkExport(BuildContext context) async {
  final String? exportDirPath = await getUserSelectedDirectory();
  if (exportDirPath != null) {
    if (context.mounted) {
      showLoadingDialog(context, "exporting");
    }
    for (Directory dir in _selectorState.selectedNotifier.dataAsDirs) {
      await writeDirectoryAsObz(
        sourceDirPath: dir.path,
        outputDirPath: exportDirPath,
      );
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
