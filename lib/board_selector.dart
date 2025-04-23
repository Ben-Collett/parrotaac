import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:parrotaac/parrot_project.dart';
import 'package:parrotaac/project_interface.dart';
import 'package:parrotaac/setting_screen.dart';
import 'package:parrotaac/ui/board_screen.dart';
import 'package:parrotaac/utils.dart';

final _viewTypeProvider = StateProvider((ref) => ViewType.list);
final _searchTextProvider = StateProvider((ref) => "");
final _projectDirProvider =
    FutureProvider((ref) async => ParrotProject.projectDirs());
List<DisplayEntry> _displayDataFromDirList(
  Iterable<Directory> dirs, {
  double? imageWidth,
  double? imageHeight,
  TextStyle? textStyle,
}) =>
    dirs
        .map(
          (dir) => DisplayEntry.entryFromOpenboardDir(
            dir,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            textStyle: textStyle,
          ),
        )
        .toList();
List<DisplayEntry> filteredEntries(
  Iterable<Directory> dirs,
  String search, {
  double? imageWidth,
  double? imageHeight,
  TextStyle? textStyle,
}) {
  bool match(Text text) => text.data?.startsWith(search) ?? true;
  return _displayDataFromDirList(dirs,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          textStyle: textStyle)
      .where((entry) => match(entry.displayName))
      .toList();
}

class BoardSelector extends StatelessWidget {
  const BoardSelector({super.key});

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
            Container(
              color: Colors.orangeAccent,
              child: TextButton(
                onPressed: () => _showBoardDialog(context),
                child: Text("create project"),
              ),
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
                        final toImport = await getFilesPaths(["obf", "obz"]);
                        if (context.mounted) {
                          _showLoadingDialog(context);
                        }
                        for (String path in toImport) {
                          await ParrotProject.import(path);
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }

                        ref.invalidate(_projectDirProvider);
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
          Flexible(child: DisplayView()),
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

void _showLoadingDialog(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      Size screenSize = MediaQuery.of(context).size;
      double containerSize = min(screenSize.width, screenSize.height) * .8;
      return AlertDialog(
        title: Text("importing"),
        content: SizedBox.square(
            dimension: containerSize, child: const CircularProgressIndicator()),
      );
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
                          switch (ref.watch(_projectDirProvider)) {
                        AsyncData(:final value) => value,
                        _ => [],
                      };
                      List<String> displayNames = _displayDataFromDirList(dirs)
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
                ref.invalidate(_projectDirProvider);
                String? imagePath;
                if (_image != null) {
                  XFile? image = await _image;
                  imagePath = image?.path;
                }
                await ParrotProject.writeDefaultProject(
                  widget.controller.text,
                  path: await ParrotProject.determineValidProjectPath(
                      widget.controller.text),
                  projectImagePath: imagePath,
                );
                if (context.mounted) Navigator.of(context).pop();
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
    return switch (ref.watch(_projectDirProvider)) {
      AsyncError(:final error) => Text('error $error'),
      AsyncData(:final value) =>
        Text('${filteredEntries(value, search).length} boards'),
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
  const DisplayView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String search = ref.watch(_searchTextProvider);
    Widget listView(Iterable<Directory> data) {
      List<DisplayEntry> filtered = filteredEntries(data, search,
          imageWidth: 65, imageHeight: 85, textStyle: TextStyle(fontSize: 45));
      return ListView.separated(
        key: ValueKey(0),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (_, index) => filtered[index],
      );
    }

    Widget gridView(Iterable<Directory> data) {
      List<DisplayEntry> filtered = filteredEntries(data, search,
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
    return switch (ref.watch(_projectDirProvider)) {
      AsyncError(:final error) => Text('error $error'),
      AsyncData(:final value) =>
        viewType == ViewType.list ? listView(value) : gridView(value),
      _ => const CircularProgressIndicator(),
    };
  }
}

enum ViewType { grid, list }

class DisplayEntry extends ConsumerWidget {
  final Text displayName;
  final Directory? dir;

  ///A sized box containing the image
  final Widget image;
  const DisplayEntry({
    super.key,
    required this.displayName,
    required this.image,
    this.dir,
  });
  factory DisplayEntry.entryFromOpenboardDir(
    Directory dir, {
    double? imageWidth,
    double? imageHeight,
    TextStyle? textStyle,
  }) {
    DisplayData data = ParrotProjectDisplayData.fromDir(dir);
    return DisplayEntry.fromDisplayData(
      dir: dir,
      data: data,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      textStyle: textStyle,
    );
  }
  DisplayEntry.fromDisplayData(
      {super.key,
      required DisplayData data,
      double? imageWidth,
      double? imageHeight,
      this.dir,
      TextStyle? textStyle})
      : displayName = Text(data.name,
            style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        image = ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: imageWidth ?? double.infinity,
              maxHeight: imageHeight ?? double.infinity),
          child: SizedBox(
            width: imageWidth,
            height: imageHeight,
            child: data.image,
          ),
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> children = [image, displayName];
    void onTap() => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BoardScreen(
              obz: ParrotProject.fromDirectory(dir!),
              path: dir!.path,
            ),
          ),
        );
    Widget rowOrCol = ref.watch(_viewTypeProvider) == ViewType.list
        ? Row(children: children)
        : Column(children: children);
    return InkWell(
      onTap: onTap,
      child: rowOrCol,
    );
  }
}
