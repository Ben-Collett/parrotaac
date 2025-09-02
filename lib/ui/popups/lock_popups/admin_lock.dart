import 'package:flutter/material.dart';
import 'package:parrotaac/backend/global_restoration_data.dart';
import 'package:parrotaac/backend/project/authentication/math_problem_generator.dart';
import 'package:parrotaac/backend/settings_utils.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_authentication_states.dart';
import 'package:parrotaac/ui/popups/lock_popups/math_popup.dart';
import 'package:parrotaac/ui/settings/labels.dart';

bool _alreadyAuthenticated = false;
set alreadyAuthenticated(bool value) {
  wasAuthenticated = value;
  _alreadyAuthenticated = value;
}

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

Future<AdminAuthenticationState> showAdminLockPopup({
  required BuildContext context,
  LockType? lockType,
  VoidCallback? onAccept,
  VoidCallback? onReject,
}) {
  lockType ??= LockType.fromString(
    getSetting<String>(adminLockLabel) ?? LockType.none.label,
  );

  myAccept() {
    alreadyAuthenticated = true;
    onAccept?.call();
  }

  if (lockType == LockType.none || alreadyAuthenticated) {
    myAccept();
    return Future.value(AdminAuthenticationState.accepted);
  } else if (lockType == LockType.mathProblem) {
    return showMathAuthenticationPopup(
      context,
      getMultiplicationProblem(),
      onAccept: myAccept,
      onReject: onReject,
    );
  } else {
    assert(false, "ended up in showAdminLockPopup guard clause somehow");
    return Future.value(AdminAuthenticationState.canceled);
  }
}
