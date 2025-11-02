import 'dart:math';

import 'package:flutter/material.dart';

void showLoadingDialog(BuildContext context, String message) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      Size screenSize = MediaQuery.of(context).size;
      double containerSize = min(screenSize.width, screenSize.height) * .8;
      return AlertDialog(
        title: Text(message),
        content: SizedBox.square(
          dimension: containerSize,
          child: const CircularProgressIndicator(),
        ),
      );
    },
  );
}

void showLoadingDialogUntilCompleted({
  required BuildContext context,
  required String message,
  required Future future,
}) async {
  showLoadingDialog(context, message);
  await future;
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}
