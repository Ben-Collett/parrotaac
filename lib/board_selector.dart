import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:parrotaac/parrot_project.dart';
import 'package:parrotaac/project_interface.dart';

final _viewTypeProvider = StateProvider((ref) => ViewType.list);
final _searchTextProvider = StateProvider((ref) => "");
final _projectDirProvider =
    FutureProvider((ref) async => ParrotProject.projectDirs());

List<DisplayEntry> _displayDataFromDirList(Iterable<Directory> dirs) =>
    dirs.map(DisplayEntry.entryFromOpenboardDir).toList();
List<DisplayEntry> filteredEntries(Iterable<Directory> dirs, String search) {
  bool match(Text text) => text.data?.startsWith(search) ?? true;
  return _displayDataFromDirList(dirs)
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
          children: [SearchBar()],
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
    return Column(
      //ensures that it looks normal when there is no data or a loading circle
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        top,
        Flexible(child: DisplayView()),
        bottom,
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
    Iterable<Directory> dirs = switch (ref.watch(_projectDirProvider)) {
      AsyncData(:final value) => value,
      _ => [],
    };

    List<String> filteredNames(String search) => _displayDataFromDirList(dirs)
        .map((data) => data.displayName.data ?? "")
        .where((name) => name.startsWith(search))
        .toList();
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
    DisplayEntry dirToDisplayEntry(Directory dir) =>
        DisplayEntry.entryFromOpenboardDir(
          dir,
          imageWidth: 65,
          imageHeight: 85,
          textStyle: TextStyle(fontSize: 45),
        );
    String search = ref.watch(_searchTextProvider);
    Widget listView(Iterable<Directory> data) {
      List<DisplayEntry> filtered = filteredEntries(data, search);
      return ListView.separated(
        key: ValueKey(0),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (_, index) => filtered[index],
      );
    }

    Widget gridView(Iterable<Directory> data) {
      List<DisplayEntry> filtered = filteredEntries(data, search);
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
  final SizedBox image;
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
      : displayName = Text(data.name, style: textStyle),
        image = SizedBox(
          width: imageWidth,
          height: imageHeight,
          child: data.image,
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> children = [image, displayName];
    void onTap() => print(dir?.path ?? "no directory was provided");
    Widget rowOrCol = ref.watch(_viewTypeProvider) == ViewType.list
        ? Row(children: children)
        : Column(children: children);
    return InkWell(
      onTap: onTap,
      child: rowOrCol,
    );
  }
}
