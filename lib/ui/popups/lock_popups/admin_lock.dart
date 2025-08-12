import 'package:flutter/material.dart';
import 'package:parrotaac/backend/project/authentication/math_problem_generator.dart';
import 'package:parrotaac/backend/settings_utils.dart';
import 'package:parrotaac/ui/popups/lock_popups/math_popup.dart';
import 'package:parrotaac/ui/settings/labels.dart';

bool _alreadyAuthenticated = false;
set alreadyAuthenticated(bool value) => _alreadyAuthenticated = value;
bool get alreadyAuthenticated => _alreadyAuthenticated;

//TODO: password/biometrics
enum LockType {
  none("None"),
  mathProblem("Math");

  final String label;
  const LockType(this.label);

  @override
  String toString() {
    return label;
  }

  static LockType fromString(String string) {
    return LockType.values.firstWhere((v) => v.label == string);
  }
}

void showAdminLockPopup({
  required BuildContext context,
  LockType? lockType,
  VoidCallback? onAccept,
  VoidCallback? onReject,
}) {
  lockType ??= LockType.fromString(
    getSetting<String>(adminLockLabel) ?? LockType.none.label,
  );

  if ((lockType == LockType.none || alreadyAuthenticated) && onAccept != null) {
    onAccept();
  } else if (lockType == LockType.mathProblem) {
    showMathAuthenticationPopup(
      context,
      getMultiplicationProblem(),
      onAccept: onAccept,
      onReject: onReject,
    );
  }
}
