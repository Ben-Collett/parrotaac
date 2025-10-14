import 'package:flutter/material.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_authentication_states.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_lock.dart';

Future<void> adminProtectedShowDialog({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
}) async {
  AdminAuthenticationState? state = await showAdminLockPopup(context: context);
  if (context.mounted && state == AdminAuthenticationState.accepted) {
    return showDialog(context: context, builder: builder);
  }
}
