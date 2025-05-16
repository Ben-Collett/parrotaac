import 'package:flutter/material.dart';
import 'package:parrotaac/backend/project/authentication/math_problem_generator.dart';
import 'package:parrotaac/ui/popups/lock_popups/math_popup.dart';

//TODO: password/biometrics
enum LockType {
  none,
  mathProblem;

  @override
  String toString() {
    return name;
  }

  static LockType fromString(String string) {
    return LockType.values.firstWhere((v) => v.name == string);
  }
}

void showAdminLockPopup({
  required BuildContext context,
  LockType? lockType,
  VoidCallback? onAccept,
  VoidCallback? onReject,
}) {
  const LockType defaultLockType = LockType.none;
  final LockType realLockType = lockType ?? defaultLockType;

  if (realLockType == LockType.none && onAccept != null) {
    onAccept();
  } else if (realLockType == LockType.mathProblem) {
    showMathAuthenticationPopup(
      context,
      getMultiplicationProblem(),
      onAccept: onAccept,
      onReject: onReject,
    );
  }
}
