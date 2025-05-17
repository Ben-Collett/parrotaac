import 'package:flutter/material.dart';
import 'package:parrotaac/ui/board_screen_constants.dart';

void showRenameTitlePopup({
  required BuildContext context,
  required TextEditingController controller,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 300),
                child: Container(
                  color: Colors.white,
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    onSubmitted: Navigator.of(context).pop,
                    decoration: InputDecoration(hintText: untitledBoard),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).then((_) {
    if (controller.text.trim() == "") {
      controller.text = untitledBoard;
    }
  });
}
