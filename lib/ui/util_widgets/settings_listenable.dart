import 'package:flutter/material.dart';
import 'package:parrotaac/backend/settings_utils.dart' as settings;

//WARNING: have to keep generic using dynamic or I get an error for some reason, getSettingsOr will force the typing in the build will enforce the type anyways
typedef SettingsBuilder = Widget Function(BuildContext context, dynamic value);

class SettingsListenable<T> extends StatefulWidget {
  final String label;
  final SettingsBuilder builder;
  final T defaultValue;
  const SettingsListenable({
    super.key,
    required this.label,
    required this.defaultValue,
    required this.builder,
  });

  @override
  State<SettingsListenable> createState() => _SettingsListenableState();
}

class _SettingsListenableState<T> extends State<SettingsListenable<T>> {
  late final ChangeNotifier notifier;
  @override
  void initState() {
    notifier = settings.addNotifier(widget.label);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final value = settings.getSettingOr<T>(
          widget.label,
          widget.defaultValue,
        );
        return widget.builder(context, value);
      },
    );
  }

  @override
  void dispose() {
    settings.removeNotifier(widget.label);
    super.dispose();
  }
}
