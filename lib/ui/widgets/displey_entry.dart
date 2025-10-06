import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:parrotaac/backend/project/manifest_utils.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project/project_interface.dart';
import 'package:parrotaac/file_utils.dart';
import 'package:parrotaac/restorative_navigator.dart';
import 'package:parrotaac/state/application_state.dart';
import 'package:parrotaac/state/project_dir_state.dart';
import 'package:parrotaac/ui/animations/fade_shrink.dart';
import 'package:parrotaac/ui/popups/loading.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_lock.dart';
import 'package:parrotaac/utils.dart';

class DisplayEntry extends StatefulWidget {
  final TextStyle? textStyle;
  Text get displayName {
    return Text(
      data.name,
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Directory? get dir {
    if (data.path == null) {
      return null;
    }
    return Directory(data.path!);
  }

  final DisplayData data;
  final ValueNotifier<bool> selectMode;

  final double? imageWidth;
  final double? imageHeight;

  ///A sized box containing the image
  Widget get image => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: imageWidth ?? double.infinity,
      maxHeight: imageHeight ?? double.infinity,
    ),
    child: SizedBox(width: imageWidth, height: imageHeight, child: data.image),
  );

  const DisplayEntry({
    super.key,
    required this.data,
    required this.selectMode,
    this.imageWidth,
    this.imageHeight,
    this.textStyle,
  });

  @override
  State<DisplayEntry> createState() => _DisplayEntryState();
}

class _DisplayEntryState extends State<DisplayEntry>
    with TickerProviderStateMixin {
  bool get selected => appState
      .getProjectSelectorState()
      .selectedNotifier
      .data
      .contains(widget.data);
  late final SlidableController _slideController;

  late final ValueNotifier<String> _searchController;

  late bool isHidden;

  void _filter() {
    String searched = _searchController.value;
    bool shouldBeHidden = !widget.data.name.startsWith(searched);
    if (isHidden != shouldBeHidden) {
      setState(() {
        isHidden = shouldBeHidden;
      });
    }
  }

  @override
  void initState() {
    _slideController = SlidableController(this);
    _searchController = appState.getProjectSelectorState().stringTextController;
    _searchController.addListener(_filter);
    isHidden = !widget.data.name.startsWith(_searchController.value);

    super.initState();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _searchController.removeListener(_filter);
    super.dispose();
  }

  void _openBoard() async {
    await RestorativeNavigator().openProject(
      context,
      ParrotProject.fromDirectory(widget.dir!),
    );
    updateAccessedTimeInManifest(widget.dir!);
    defaultProjectDirListener.refresh();
  }

  void _onTap(bool selectMode) {
    if (selectMode) {
      if (selected) {
        appState.getProjectSelectorState().selectedNotifier.remove(widget.data);
      } else if (!selected) {
        appState.getProjectSelectorState().selectedNotifier.addIfNotNull(
          widget.data,
        );
      }

      setState(() {});
    } else {
      _openBoard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeAndShrink(
      visible: !isHidden,
      duration: const Duration(milliseconds: 450),
      child: ValueListenableBuilder(
        valueListenable: widget.selectMode,
        builder: (context, selectMode, child) {
          final Color backgroundColor = (selectMode && selected)
              ? Colors.grey.withAlpha(127)
              : Colors.white;

          return Slidable(
            controller: _slideController,
            endActionPane: ActionPane(
              motion: const StretchMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) {
                    showAdminLockPopup(
                      context: context,
                      onAccept: () => showExportDialog(
                        context,
                        widget.dir,
                      ).then((_) => _slideController.close()),
                    );
                  },
                  icon: Icons.folder,
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.white,
                ),
                SlidableAction(
                  autoClose: false,
                  onPressed: (_) {
                    showAdminLockPopup(
                      context: context,
                      onAccept: () => showDeleteDialog(context, widget.data),
                    );
                  },
                  icon: Icons.delete,
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
            child: _button(
              backgroundColor,
              () => _onTap(selectMode),
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: widget.selectMode.value ? 32 : 0,
                    height: widget.selectMode.value ? 32 : 0,
                    child: _CircleSelectionIndecator(selected),
                  ),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        children: [
                          widget.image,
                          Expanded(child: widget.displayName),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _button(Color bg, VoidCallback onTap, Widget child) {
    return Material(
      color: bg,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

class _CircleSelectionIndecator extends StatelessWidget {
  final bool selected;
  const _CircleSelectionIndecator(this.selected);
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double radius = constraints.maxWidth / 2;
        const double padding = 2;
        if (selected) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: padding),
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              radius: radius,
              child: Icon(Icons.check, size: radius, color: Colors.white),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: padding),
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 1.25),
              ),
            ),
          );
        }
      },
    );
  }
}

Future<void> showDeleteDialog(BuildContext context, DisplayData data) =>
    showDialog(
      context: context,
      builder: (context) {
        final displayName = data.name;
        final dir = data.path == null ? null : Directory(data.path!);
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text("are you sure you want to delete $displayName:"),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 35),
                  child: Container(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('no'),
                    ),
                    TextButton(
                      onPressed: () {
                        showLoadingDialog(context, 'deleting $displayName');
                        dir?.deleteSync(recursive: true);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        defaultProjectDirListener.delete(data);
                      },
                      child: Text('yes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

Future<void> showExportDialog(BuildContext context, Directory? dir) async {
  final String? exportDirPath = await getUserSelectedDirectory();
  if (exportDirPath != null && dir != null) {
    if (context.mounted) {
      showLoadingDialog(context, "exporting");
    }
    await writeDirectoryAsObz(
      sourceDirPath: dir.path,
      outputDirPath: exportDirPath,
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
