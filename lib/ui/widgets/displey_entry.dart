import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:parrotaac/file_utils.dart';
import 'package:parrotaac/shared_providers/future_providers.dart';
import 'package:parrotaac/ui/popups/loading.dart';
import 'package:parrotaac/utils.dart';

import '../../parrot_project.dart';
import '../../project_interface.dart';
import '../board_screen.dart';

enum ViewType { grid, list }

class DisplayEntry extends StatelessWidget {
  final Text displayName;
  final Directory? dir;
  final ViewType viewType;

  ///A sized box containing the image
  final Widget image;
  const DisplayEntry({
    super.key,
    required this.displayName,
    required this.image,
    required this.viewType,
    this.dir,
  });
  factory DisplayEntry.entryFromOpenboardDir(
    Directory dir, {
    required ViewType viewType,
    double? imageWidth,
    double? imageHeight,
    TextStyle? textStyle,
  }) {
    DisplayData data = ParrotProjectDisplayData.fromDir(dir);
    return DisplayEntry.fromDisplayData(
      dir: dir,
      data: data,
      viewType: viewType,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      textStyle: textStyle,
    );
  }
  DisplayEntry.fromDisplayData(
      {super.key,
      required DisplayData data,
      required this.viewType,
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
  Widget build(BuildContext context) {
    List<Widget> children = [image, displayName];
    void onTap() => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BoardScreen(
              obz: ParrotProject.fromDirectory(dir!),
              path: dir!.path,
            ),
          ),
        );
    Widget rowOrCol = viewType == ViewType.list
        ? Row(children: children)
        : Column(children: children);
    return Slidable(
      enabled: viewType == ViewType.list,
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (_) async {
              final String? exportDirPath = await getUserSelectedDirectory();
              if (exportDirPath != null && dir != null) {
                if (context.mounted) {
                  showLoadingDialog(context, "exporting");
                }
                await writeDirectoryAsObz(
                  sourceDirPath: dir!.path,
                  outputDirPath: exportDirPath,
                );
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: Icons.folder,
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
          ),
          SlidableAction(
            onPressed: (_) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            "are you sure you want to delete ${displayName.data}?:",
                          ),
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
                                  child: Text('no')),
                              Consumer(
                                builder: (context, ref, _) => TextButton(
                                  onPressed: () {
                                    showLoadingDialog(
                                      context,
                                      'deleting ${displayName.data}',
                                    );
                                    dir?.deleteSync(recursive: true);
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    ref.invalidate(projectDirProvider);
                                  },
                                  child: Text('yes'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            icon: Icons.delete,
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          )
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: rowOrCol,
      ),
    );
  }
}
