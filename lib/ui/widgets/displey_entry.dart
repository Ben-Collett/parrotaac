import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:parrotaac/backend/project/manifest_utils.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project/project_interface.dart';
import 'package:parrotaac/file_utils.dart';
import 'package:parrotaac/restorative_navigator.dart';
import 'package:parrotaac/shared_providers/project_dir_controller.dart';
import 'package:parrotaac/state/application_state.dart';
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
  final bool selectMode;

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
    required this.imageWidth,
    required this.imageHeight,
    this.textStyle,
    this.selectMode = false,
  });

  @override
  State<DisplayEntry> createState() => _DisplayEntryState();
}

class _DisplayEntryState extends State<DisplayEntry>
    with TickerProviderStateMixin {
  bool selected = false;
  late final SlidableController _slideController;
  @override
  void initState() {
    _slideController = SlidableController(this);
    super.initState();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Widget get _circleSelectedIndicator {
    const double radius = 11;
    const double padding = 2;
    if (selected) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: padding),
        child: CircleAvatar(
          backgroundColor: Colors.blue,
          radius: radius,
          child: Icon(Icons.check, size: 16, color: Colors.white),
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
  }

  void _openBoard() async {
    await RestorativeNavigator().openProject(
      context,
      ParrotProject.fromDirectory(widget.dir!),
    );
    updateAccessedTimeInManifest(widget.dir!);
    projectDirController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    //removes selections when exiting selectedMode
    if (!widget.selectMode) {
      selected = false;
    }
    final Color backgroundColor;
    if (widget.selectMode && selected) {
      backgroundColor = Colors.grey.withAlpha(127);
    } else {
      backgroundColor = Colors.white;
    }
    List<Widget> children = [widget.image, Expanded(child: widget.displayName)];
    void onTap() {
      if (widget.selectMode) {
        setState(() {
          selected = !selected;
        });

        if (selected) {
          appState.getProjectSelectorState().selectedNotifier.addIfNotNull(
            widget.dir,
          );
        } else if (!selected) {
          appState.getProjectSelectorState().selectedNotifier.remove(
            widget.dir,
          );
        }
      } else {
        _openBoard();
      }
    }

    Widget entry;
    if (widget.selectMode) {
      children.insert(0, _circleSelectedIndicator);
    }
    entry = Row(children: children);
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
                onAccept: () => showDeleteDialog(
                  context,
                  widget.displayName.data,
                  widget.dir,
                ),
              );
            },
            icon: Icons.delete,
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ],
      ),
      child: _button(backgroundColor, () {
        onTap();
      }, entry),
    );
  }

  Widget _button(Color bg, VoidCallback onTap, Widget child) {
    return Material(
      color: bg,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

Future<void> showDeleteDialog(
  BuildContext context,
  String? displayName,
  Directory? dir,
) => showDialog(
  context: context,
  builder: (context) {
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
                    projectDirController.refresh();
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
