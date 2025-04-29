import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parrotaac/parrot_project.dart';
import 'package:parrotaac/setting_screen.dart';
import 'package:parrotaac/utils.dart';

import 'shared_providers/future_providers.dart';
import 'ui/popups/loading.dart';
import 'ui/widgets/displey_entry.dart';

final _viewTypeProvider = StateProvider((ref) => ViewType.list);
final _searchTextProvider = StateProvider((ref) => "");

List<DisplayEntry> _displayDataFromDirList(
  Iterable<Directory> dirs, {
  required ViewType viewType,
  double? imageWidth,
  double? imageHeight,
  TextStyle? textStyle,
}) =>
    dirs
        .map(
          (dir) => DisplayEntry.entryFromOpenboardDir(
            dir,
            viewType: viewType,
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
  required ViewType viewType,
  double? imageHeight,
  TextStyle? textStyle,
}) {
  bool match(Text text) => text.data?.startsWith(search) ?? true;
  return _displayDataFromDirList(dirs,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          viewType: viewType,
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
            Row(children: [
              Container(
                color: Colors.yellow,
                child: TextButton(
                  child: Text("select mode"),
                  onPressed: () {},
                ),
              ),
              Container(
                color: Colors.orangeAccent,
                child: TextButton(
                  onPressed: () => _showBoardDialog(context),
                  child: Text("create project"),
                ),
              ),
            ])
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
                          showLoadingDialog(context, 'importing');
                        }
                        for (String path in toImport) {
                          await ParrotProject.import(path);
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
                ref.invalidate(projectDirProvider);
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
    return switch (ref.watch(projectDirProvider)) {
      AsyncError(:final error) => Text('error $error'),
      AsyncData(:final value) => Text(
          '${filteredEntries(value, search, viewType: ViewType.list).length} boards'),
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
          viewType: ViewType.list,
          imageWidth: 65,
          imageHeight: 85,
          textStyle: TextStyle(fontSize: 45));
      return ListView.separated(
        key: ValueKey(0),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (_, index) => filtered[index],
      );
    }

    Widget gridView(Iterable<Directory> data) {
      List<DisplayEntry> filtered = filteredEntries(data, search,
          viewType: ViewType.grid,
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
    //print(viewType);
    return switch (ref.watch(projectDirProvider)) {
      AsyncError(:final error) => Text('error $error'),
      AsyncData(:final value) =>
        viewType == ViewType.list ? listView(value) : gridView(value),
      _ => const CircularProgressIndicator(),
    };
  }
}
