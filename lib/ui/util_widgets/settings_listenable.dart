import 'package:flutter/material.dart';
import 'package:parrotaac/backend/settings_utils.dart' as settings;
import 'package:parrotaac/backend/simple_logger.dart';
typedef SettingsBuilder<T> = Widget Function(BuildContext context,T value);

class SettingsListenable<T> extends StatefulWidget {
  final String label;
  final SettingsBuilder<T> builder;
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
          final T value =
              settings.getSettingOr<T>(widget.label,widget.defaultValue);
            SimpleLogger().logDebug("logged");
          return widget.builder(context,value);
        });
  }

  @override
  void dispose() {
    settings.removeNotifier(widget.label);
    super.dispose();
  }
}
