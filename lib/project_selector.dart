import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project/project_interface.dart';
import 'package:parrotaac/restorative_navigator.dart';
import 'package:parrotaac/shared_providers/project_dir_controller.dart';
import 'package:parrotaac/state/application_state.dart';
import 'package:parrotaac/state/project_selector_state.dart';
import 'package:parrotaac/ui/settings/settings_themed_appbar.dart';
import 'package:parrotaac/ui/util_widgets/future_controller_builder.dart';
import 'package:parrotaac/ui/util_widgets/multi_listenable_builder.dart';
import 'package:parrotaac/utils.dart';

import 'backend/project/default_project.dart.dart';
import 'backend/project/import_utils.dart';
import 'backend/project/project_utils.dart';
import 'file_utils.dart';
import 'ui/popups/loading.dart';
import 'ui/widgets/displey_entry.dart';

List<DisplayData> _displayData(
  Iterable<Directory> dirs, {
  int Function(DisplayData, DisplayData)? sort,
}) {
  List<DisplayData> out = dirs.map(ParrotProjectDisplayData.fromDir).toList();
  if (sort != null) {
    out.sort(sort);
  }
  return out;
}

List<DisplayEntry> _displayDataFromDirList(
  Iterable<Directory> dirs, {
  required ViewType viewType,
  bool selectMode = false,
  double? imageWidth,
  double? imageHeight,
  int Function(DisplayData, DisplayData)? sort,
  TextStyle? textStyle,
}) =>
    _displayData(dirs, sort: sort)
        .map(
          (d) => DisplayEntry(
            key: UniqueKey(),
            data: d,
            viewType: viewType,
            imageWidth: imageWidth,
            selectMode: selectMode,
            imageHeight: imageHeight,
            textStyle: textStyle,
          ),
        )
        .toList();
List<Widget> filteredEntries(
  Iterable<Directory> dirs,
  String search, {
  double? imageWidth,
  bool selectMode = false,
  required ViewType viewType,
  int Function(DisplayData, DisplayData)? sort,
  double? imageHeight,
  TextStyle? textStyle,
}) {
  bool match(Text text) => text.data?.startsWith(search) ?? true;
  return _displayDataFromDirList(dirs,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          selectMode: selectMode,
          sort: sort,
          viewType: viewType,
          textStyle: textStyle)
      .where((entry) => match(entry.displayName))
      .toList();
}

class ProjectSelector extends StatefulWidget {
  const ProjectSelector({super.key});

  @override
  State<ProjectSelector> createState() => _ProjectSelectorState();
}

class _ProjectSelectorState extends State<ProjectSelector> {
  final _state = _selectorState;

  @override
  void dispose() {
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
        return IconButton(
          onPressed: outputOnPressed,
          icon: icon,
        );
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
            SearchBar(
              textController: _state.searchTextController,
            ),
            ValueListenableBuilder(
              valueListenable: _state.selectModeNotifier,
              builder: (context, selectMode, child) {
                String text = selectMode ? "done" : "select";
                List<Widget> children = [];
                void bulkDelete() {
                  showLoadingDialog(context,
                      "delete ${_selectorState.selectedNotifier.length}");
                  for (Directory dir
                      in _selectorState.selectedNotifier.values) {
                    dir.deleteSync(recursive: true);
                  }

                  _selectorState.selectedNotifier.clear();
                  projectDirController.refresh();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }

                if (selectMode) {
                  children.add(
                    _iconButtonThatIsDisabledWhenSelectedNotfierIsEmpty(
                      Icon(Icons.delete),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            List<String> toRemoveNames = _selectorState
                                .selectedNotifier.values
                                .map(ParrotProjectDisplayData.fromDir)
                                .map((d) => d.name)
                                .toList();

                            return AlertDialog(
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                        "are you sure you want to delete the following:"),
                                    SingleChildScrollView(
                                      child: Column(
                                        children: toRemoveNames
                                            .map(
                                              (n) => Text(n,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            )
                                            .map(
                                              (n) => ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: 220,
                                                ),
                                                child: n,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: bulkDelete,
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: Text("yes"),
                                        ),
                                        TextButton(
                                          onPressed: Navigator.of(context).pop,
                                          style: TextButton.styleFrom(
                                              backgroundColor: Colors.green),
                                          child: Text("no"),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                  children.add(
                    _iconButtonThatIsDisabledWhenSelectedNotfierIsEmpty(
                        Icon(Icons.folder), onPressed: () async {
                      final String? exportDirPath =
                          await getUserSelectedDirectory();
                      if (exportDirPath != null) {
                        if (context.mounted) {
                          showLoadingDialog(context, "exporting");
                        }
                        for (Directory dir
                            in _selectorState.selectedNotifier.values) {
                          await writeDirectoryAsObz(
                            sourceDirPath: dir.path,
                            outputDirPath: exportDirPath,
                          );
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    }),
                  );
                }

                children.addAll(
                  [
                    Container(
                      color: Colors.yellow,
                      child: TextButton(
                        child: Text(text),
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
                  ],
                );
                return Row(
                  children: children,
                );
              },
            )
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
            BoardCountText(textController: _state.searchTextController),
            ViewTypeSegmantedButton(),
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
                IconButton(
                  icon: Icon(Icons.file_download_outlined),
                  onPressed: () async {
                    final time = DateTime.now();
                    final toImport = await getFilesPaths(["obf", "obz"]);
                    if (context.mounted) {
                      showLoadingDialog(context, 'importing');
                    }
                    for (String path in toImport) {
                      await import(path, lastAccessedTime: time);
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }

                    projectDirController.refresh();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () => RestorativeNavigator().goToSettings(context),
                ),
              ],
            )
          ],
        ),
      ),
      body: Column(
        //ensures that it looks normal when there is no data or a loading circle
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          top,
          Flexible(
            child: DisplayView(
              searchController: _state.searchTextController,
              viewTypeController: _state.viewTypeNotifier,
            ),
          ),
          bottom,
        ],
      ),
    );
  }
}

void _showCreateProjectDialog(BuildContext context) {
  final TextEditingController controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) {
      return CreateProjectDialog(formKey: formKey, controller: controller);
    },
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
    setState(() {
      _image = image;
    });
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
                  child: ValueListenableBuilder(
                      valueListenable: _selectorState.viewTypeNotifier,
                      builder: (_, viewType, __) {
                        return FutureControllerBuilder(
                          controller: projectDirController,
                          onData: (dirs) {
                            List<String> displayNames = _displayDataFromDirList(
                                    dirs!,
                                    viewType: viewType)
                                .map((d) => d.displayName.data)
                                .whereType<String>()
                                .toList();
                            List<Widget> column = [
                              TextFormField(
                                controller: widget.controller,
                                validator: (text) =>
                                    validate(text, displayNames),
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
                                      constraints:
                                          BoxConstraints(maxHeight: 100),
                                      child: imageFromPath(data.path),
                                    );
                                  },
                                ),
                              );
                            }
                            column.add(TextButton(
                              child: Text("select project image"),
                              onPressed: () => setImage(getImage()),
                            ));

                            return Column(
                              children: column,
                            );
                          },
                        );
                      }),
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
              await writeDefaultProject(
                widget.controller.text,
                path: await determineValidProjectPath(widget.controller.text),
                projectImagePath: imagePath,
              );
              if (context.mounted) {
                Navigator.of(context).pop();
              }

              projectDirController.refresh();
            }
          },
        ),
      ],
    );
  }
}

class SearchBar extends StatelessWidget {
  final TextEditingController textController;
  const SearchBar({
    super.key,
    required this.textController,
  });

  @override
  Widget build(BuildContext context) {
    //TODO: I should fine a way to not have the width constant

    return Container(
      width: 200,
      color: Colors.white,
      //could add autocomplete but it looks bad and provides little advantage
      child: TextField(
        decoration: InputDecoration(
            prefixIcon: Icon(Icons.search), hintText: "search..."),
        controller: textController,
      ),
    );
  }
}

class BoardCountText extends StatelessWidget {
  final TextEditingController textController;
  const BoardCountText({super.key, required this.textController});
  @override
  Widget build(BuildContext context) {
    return FutureControllerBuilder(
      controller: projectDirController,
      onData: (value) => ValueListenableBuilder(
          valueListenable: _selectorState.searchTextController,
          builder: (context, search, child) {
            return Text('${filteredEntries(
              value!,
              search.text,
              viewType: ViewType.list,
            ).length} boards');
          }),
      onLoad: const Text('calculating #of boards'),
    );
  }
}

class ViewTypeSegmantedButton extends StatelessWidget {
  const ViewTypeSegmantedButton({super.key});

  @override
  Widget build(BuildContext context) {
    //TODO: it would be nice to replace the labels with icons
    final listSegment =
        ButtonSegment(value: ViewType.list, label: Text("list"));
    const gridSegment =
        ButtonSegment(value: ViewType.grid, label: Text("grid"));
    return ValueListenableBuilder(
        valueListenable: _selectorState.viewTypeNotifier,
        builder: (context, value, child) {
          return SegmentedButton(
              segments: [listSegment, gridSegment],
              selected: {value},
              onSelectionChanged: (selected) {
                _selectorState.viewTypeNotifier.value = selected.first;
              });
        });
  }
}

class DisplayView extends StatefulWidget {
  final TextEditingController searchController;
  final ValueNotifier<ViewType> viewTypeController;
  const DisplayView({
    super.key,
    required this.searchController,
    required this.viewTypeController,
  });

  @override
  State<DisplayView> createState() => _DisplayViewState();
}

class _DisplayViewState extends State<DisplayView> {
  late final Listenable listenable;
  @override
  void initState() {
    listenable = Listenable.merge([
      appState.getProjectSelectorState().searchTextController,
      appState.getProjectSelectorState().selectModeNotifier
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureControllerBuilder(
      controller: projectDirController,
      onData: (data) => ValueListenableBuilder(
        valueListenable: _selectorState.viewTypeNotifier,
        builder: (_, viewType, __) => viewType == ViewType.list
            ? SelectorListView(
                data: data!,
              )
            : SelectorGridView(
                data: data!,
              ),
      ),
    );
  }
}

class SelectorListView extends StatelessWidget {
  final Function(Directory?)? onSelect;
  final Function(Directory?)? onDeselect;
  final Iterable<Directory> data;

  const SelectorListView({
    super.key,
    this.onSelect,
    this.onDeselect,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return MultiListenableBuilder(
        listenables: [
          _selectorState.searchTextController,
          _selectorState.selectModeNotifier,
        ],
        builder: (context, _) {
          List<Widget> filtered = filteredEntries(
            data,
            _selectorState.searchText,
            viewType: ViewType.list,
            sort: _byLastAccessedThenAlphabeticalOrder,
            imageWidth: 75,
            imageHeight: 98,
            selectMode: _selectorState.selectMode,
            textStyle: TextStyle(
              fontSize: 50,
            ),
          );
          final Color borderColor = Colors.grey.withAlpha(127);
          final double borderWidth = 1;
          return ListView.separated(
            key: ValueKey(0),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => Container(),
            itemBuilder: (_, index) => Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: borderColor, width: borderWidth),
                  ),
                ),
                child: filtered[index]),
          );
        });
  }
}

class SelectorGridView extends StatelessWidget {
  final Iterable<Directory> data;

  const SelectorGridView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return MultiListenableBuilder(
      listenables: [
        _selectorState.selectModeNotifier,
        _selectorState.searchTextController
      ],
      builder: (context, _) {
        List<Widget> filtered = filteredEntries(data, _selectorState.searchText,
            viewType: ViewType.grid,
            selectMode: _selectorState.selectMode,
            textStyle: TextStyle(fontSize: 45),
            imageWidth: 170,
            imageHeight: 250);
        return GridView.count(
          key: ValueKey(1),
          crossAxisCount: 3,
          children: filtered,
        );
      },
    );
  }
}

int _byLastAccessedThenAlphabeticalOrder(DisplayData d1, DisplayData d2) {
  DateTime? t1 = d1.lastAccessed;
  DateTime? t2 = d2.lastAccessed;
  if (d1.lastAccessed == null && d2.lastAccessed == null) {
    return d1.name.compareTo(d2.name);
  } else if (t1 == null) {
    return 1;
  } else if (t2 == null) {
    return -1;
  } else if (t1.isBefore(t2)) {
    return 1;
  } else if (t1.isAfter(t2)) {
    return -1;
  }
  return d1.name.compareTo(d2.name);
}

ProjectSelectorState get _selectorState => appState.getProjectSelectorState();
