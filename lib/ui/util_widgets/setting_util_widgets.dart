import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:parrotaac/backend/settings_utils.dart';
import 'package:parrotaac/ui/util_widgets/settings_listenable.dart';

class SettingsSwitchTile extends StatelessWidget {
  final String label;
  const SettingsSwitchTile({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return SettingsListenable<bool>(
      label: label,
      defaultValue: false,
      builder: (val) => SwitchListTile(
        value: val,
        onChanged: (_) {
          setSetting(label, !val);
        },
        title: Text(label),
      ),
    );
  }
}

class SettingsDropDown extends StatelessWidget {
  final String label;
  final String defaultValue;
  final List<String> options;
  const SettingsDropDown({
    super.key,
    required this.label,
    required this.defaultValue,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsListenable<String>(
        label: label,
        defaultValue: defaultValue,
        builder: (val) {
          return ListTile(
            title: Text(label),
            trailing: DropdownButton<String>(
              value: val,
              items: options
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    ),
                  )
                  .toList(),
              onChanged: (selection) {
                setSetting(label, selection);
              },
            ),
          );
        });
  }
}

class SettingsColorChange extends StatelessWidget {
  final String label;
  final int defaultValue;
  const SettingsColorChange({
    super.key,
    required this.label,
    required this.defaultValue,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsListenable<int>(
      label: label,
      defaultValue: defaultValue,
      builder: (val) {
        return ListTile(
          title: Text(label),
          trailing: MaterialButton(
            color: Color(val),
            onPressed: () {
              _showColorPickerDialog(
                context,
                Color(val),
                (color) {
                  setSetting(label, color.toARGB32());
                },
              );
            },
          ),
        );
      },
    );
  }
}

void _showColorPickerDialog(
  BuildContext context,
  Color initialColor,
  Function(Color) onChange,
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Appbar Color"),
        content: SingleChildScrollView(
          child:
              ColorPicker(pickerColor: initialColor, onColorChanged: onChange),
        ),
      );
    },
  );
}
