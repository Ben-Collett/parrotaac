import 'package:flutter/material.dart';
import 'package:parrotaac/backend/global_restoration_data.dart';
import 'package:parrotaac/backend/quick_store.dart';
import 'package:parrotaac/ui/popups/admin_protected_show_dialog.dart';

Future<void> showRestorableDialog({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  required String mainLabel,
  bool onlyShowIfMainLabelIsInTheQuickstore = false,
  bool adminLocked = false,
  dynamic mainLabelValue,
  Iterable<String>? fieldLabels,
  QuickStore? quickstore,
}) async {
  quickstore ??= globalRestorationQuickstore;

  if (onlyShowIfMainLabelIsInTheQuickstore &&
      !quickstore.containsKey(mainLabel)) {
    return;
  }
  await quickstore.writeData(mainLabel, mainLabelValue);

  if (context.mounted) {
    Future<void> removeLabels(_) async {
      List<Future> keysBeingRemoved = [];
      keysBeingRemoved.add(quickstore!.removeFromKey(mainLabel));
      if (fieldLabels != null) {
        for (String label in fieldLabels) {
          keysBeingRemoved.add(quickstore.removeFromKey(label));
        }
      }
      await Future.wait(keysBeingRemoved);
    }

    if (adminLocked) {
      return adminProtectedShowDialog(
        context: context,
        builder: builder,
      ).then(removeLabels);
    }

    return showDialog(context: context, builder: builder).then(removeLabels);
  }
}
