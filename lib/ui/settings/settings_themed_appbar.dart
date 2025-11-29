import 'package:flutter/material.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/restorative_navigator.dart';
import 'package:parrotaac/ui/appbar_widgets/compute_contrasting_color.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_lock.dart';
import 'package:parrotaac/ui/settings/defaults.dart';
import 'package:parrotaac/ui/settings/labels.dart';
import 'package:parrotaac/ui/util_widgets/settings_listenable.dart';

class SettingsThemedAppbar extends StatelessWidget
    implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final bool? centerTitle;
  final List<Widget>? actions;
  const SettingsThemedAppbar({
    super.key,
    this.title,
    this.leading,
    this.centerTitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    const leadingWidth = 32.0;
    Widget? leading = this.leading;
    if (leading == null && RestorativeNavigator().hasPreviousScreen) {
      leading = BackButton(onPressed: () {
        showAdminLockPopup(
          context: context,
          onAccept: () => RestorativeNavigator().pop(context),
        );
      });
    }
    
    return SettingsListenable<int>(
        label: appBarColorLabel,
        defaultValue: defaultAppbarColor,
        builder: (context, value) {
          final color = Color(value);
          return AppBar(
            title: title,
            centerTitle: centerTitle,
            leadingWidth: leadingWidth,
            foregroundColor: computeContrastingColor(color),
            actions: actions,
            leading: leading,
            backgroundColor: Color(value),
          );
        });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
