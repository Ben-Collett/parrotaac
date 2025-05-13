import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project/project_interface.dart';
import 'package:parrotaac/setting_screen.dart';
import 'package:parrotaac/utils.dart';

import 'backend/project/default_project.dart.dart';
import 'backend/project/import_utils.dart';
import 'backend/project/project_utils.dart';
import 'file_utils.dart';
import 'shared_providers/future_providers.dart';
import 'ui/popups/loading.dart';
import 'ui/widgets/displey_entry.dart';

final _viewTypeProvider = StateProvider((ref) => ViewType.list);
final _selectModeProvider = StateProvider((ref) => false);
final _searchTextProvider = StateProvider((ref) => "");

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
  Function(Directory?)? onSelect,
  Function(Directory?)? onDeselect,
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
            onSelect: onSelect,
            onDeselect: onDeselect,
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
  Function(Directory?)? onSelect,
  Function(Directory?)? onDeselect,
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
          onSelect: onSelect,
          onDeselect: onDeselect,
          viewType: viewType,
          textStyle: textStyle)
      .where((entry) => match(entry.displayName))
      .toList();
}

class BoardSelector extends StatefulWidget {
  const BoardSelector({super.key});

  @override
  State<BoardSelector> createState() => _BoardSelectorState();
}

class _BoardSelectorState extends State<BoardSelector> {
  final selectedNotifier = SelectedNotifier();
  @override
  void dispose() {
    selectedNotifier.dispose();
    super.dispose();
  }

  Widget _iconButtonThatIsDisabledWhenSelectedNotfierIsEmpty(
    Icon icon, {
    required VoidCallback onPressed,
  }) {
    return ListenableBuilder(
      listenable: selectedNotifier,
      builder: (context, _) {
        VoidCallback? outputOnPressed;
        if (selectedNotifier.isNotEmpty) {
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
            SearchBar(),
            Consumer(
              builder: (context, ref, _) {
                bool selectMode = ref.watch(_selectModeProvider);

                String text = selectMode ? "done" : "select";
                List<Widget> children = [];
                void bulkDelete() {
                  showLoadingDialog(
                      context, "delete ${selectedNotifier.length}");
                  for (Directory dir in selectedNotifier.values) {
                    dir.deleteSync(recursive: true);
                  }

                  selectedNotifier.clear();
                  ref.invalidate(projectDirProvider);
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
                            List<String> toRemoveNames = selectedNotifier.values
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
                        for (Directory dir in selectedNotifier.values) {
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
                          selectedNotifier.clear();
                          bool selectModeState = ref.read(_selectModeProvider);
                          final notfier = _selectModeProvider.notifier;
                          ref.read(notfier).state = !selectModeState;
                        },
                      ),
                    ),
                    Container(
                      color: Colors.orangeAccent,
                      child: TextButton(
                        onPressed: () => _showBoardDialog(context),
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
            BoardCountText(),
            ViewTypeSegmantedButton(),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ParrotAAC'),
            Row(
              children: [
                Consumer(
                  builder: (context, ref, __) {
                    return IconButton(
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

                        ref.invalidate(projectDirProvider);
                      },
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingsScreen()),
                  ),
                ),
              ],
            )
          ],
        ),
        backgroundColor: Color(0xFFAFABDF),
      ),
      body: Column(
        //ensures that it looks normal when there is no data or a loading circle
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          top,
          Flexible(
            child: DisplayView(
              onSelect: selectedNotifier.addIfNotNull,
              onDeselect: selectedNotifier.remove,
            ),
          ),
          bottom,
        ],
      ),
    );
  }
}

void _showBoardDialog(BuildContext context) {
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
                  child: Consumer(
                    builder: (_, ref, __) {
                      Iterable<Directory> dirs =
                          switch (ref.watch(projectDirProvider)) {
                        AsyncData(:final value) => value,
                        _ => [],
                      };
                      final ViewType viewType = ref.watch(_viewTypeProvider);
                      List<String> displayNames =
                          _displayDataFromDirList(dirs, viewType: viewType)
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
                      column.add(TextButton(
                        child: Text("select project image"),
                        onPressed: () => setImage(getImage()),
                      ));

                      return Column(
                        children: column,
                      );
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
        Consumer(builder: (_, ref, ___) {
          return IconButton(
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
                ref.invalidate(projectDirProvider);
              }
            },
          );
        }),
      ],
    );
  }
}

class SearchBar extends ConsumerWidget {
  const SearchBar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //TODO: I should fine a way to not have the width constant

    return Container(
      width: 200,
      color: Colors.white,
      //could add autocomplete but it looks bad and provides little advantage
      child: TextField(
          decoration: InputDecoration(
              prefixIcon: Icon(Icons.search), hintText: "search..."),
          onChanged: (text) {
            ref.read(_searchTextProvider.notifier).state = text;
          }),
    );
  }
}

class BoardCountText extends ConsumerWidget {
  const BoardCountText({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String search = ref.watch(_searchTextProvider);
    return switch (ref.watch(projectDirProvider)) {
      AsyncError(:final error) => Text('error $error'),
      AsyncData(:final value) => Text('${filteredEntries(
          value,
          search,
          viewType: ViewType.list,
        ).length} boards'),
      _ => const Text('calculating #of boards'),
    };
  }
}

class ViewTypeSegmantedButton extends ConsumerWidget {
  const ViewTypeSegmantedButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //TODO: it would be nice to replace the labels with icons
    final listSegment =
        ButtonSegment(value: ViewType.list, label: Text("list"));
    const gridSegment =
        ButtonSegment(value: ViewType.grid, label: Text("grid"));
    return SegmentedButton(
        segments: [listSegment, gridSegment],
        selected: {ref.watch(_viewTypeProvider)},
        onSelectionChanged: (selected) {
          ref.read(_viewTypeProvider.notifier).state = selected.first;
        });
  }
}

class DisplayView extends ConsumerWidget {
  final void Function(Directory?)? onSelect;
  final void Function(Directory?)? onDeselect;
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

  const DisplayView({
    super.key,
    this.onSelect,
    this.onDeselect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String search = ref.watch(_searchTextProvider);
    bool selectMode = ref.watch(_selectModeProvider);
    Widget listView(Iterable<Directory> data) {
      List<Widget> filtered = filteredEntries(data, search,
          viewType: ViewType.list,
          sort: _byLastAccessedThenAlphabeticalOrder,
          imageWidth: 75,
          imageHeight: 98,
          selectMode: selectMode,
          onSelect: onSelect,
          onDeselect: onDeselect,
          textStyle: TextStyle(fontSize: 50));
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
    }

    Widget gridView(Iterable<Directory> data) {
      List<Widget> filtered = filteredEntries(data, search,
          viewType: ViewType.grid,
          selectMode: selectMode,
          onSelect: onSelect,
          onDeselect: onDeselect,
          textStyle: TextStyle(fontSize: 45),
          imageWidth: 170,
          imageHeight: 250);
      return GridView.count(
        key: ValueKey(1),
        crossAxisCount: 3,
        children: filtered,
      );
    }

    final viewType = ref.watch(_viewTypeProvider);
    return switch (ref.watch(projectDirProvider)) {
      AsyncError(:final error) => Text('error $error'),
      AsyncData(:final value) =>
        viewType == ViewType.list ? listView(value) : gridView(value),
      _ => const CircularProgressIndicator(),
    };
  }
}

class SelectedNotifier extends ChangeNotifier {
  final Set<Directory> _values = {};
  UnmodifiableSetView<Directory> get values => UnmodifiableSetView(_values);
  bool get isNotEmpty => _values.isNotEmpty;
  int get length => _values.length;

  ///if dir is null it won't be added
  ///if [dir] is in the set or is null then listeners won't be notfied
  void addIfNotNull(Directory? dir) {
    if (dir != null) {
      final bool setChanged = _values.add(dir);
      if (setChanged) {
        notifyListeners();
      }
    }
  }

  void clear() {
    if (_values.isNotEmpty) {
      _values.clear();
      notifyListeners();
    }
  }

  void remove(Directory? dir) {
    final bool removedSomething = _values.remove(dir);
    if (removedSomething) {
      notifyListeners();
    }
  }
}
