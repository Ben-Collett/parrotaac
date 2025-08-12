import 'package:flutter/material.dart';
import 'package:parrotaac/backend/settings_utils.dart' as settings;

class SettingsListenable<T> extends StatefulWidget {
  final String label;
  final Widget Function(dynamic) builder;
  final dynamic defaultValue;
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
          final dynamic value =
              settings.getSetting<T>(widget.label) ?? widget.defaultValue;
          return widget.builder(value);
        });
  }

  @override
  void dispose() {
    settings.removeNotifier(widget.label);
    super.dispose();
  }
}
