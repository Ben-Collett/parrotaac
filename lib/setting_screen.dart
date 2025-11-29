import 'package:flutter/material.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/global_restoration_data.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/settings_utils.dart';
import 'package:parrotaac/ui/settings/defaults.dart';
import 'package:parrotaac/ui/settings/settings_themed_appbar.dart';
import 'package:parrotaac/ui/util_widgets/setting_util_widgets.dart';

const _padding = 16.0;
const _wideScreenSize = 600;

const selectedCategoriesKey = "settings selected categories";
const appbarColorOpenKey = "appbar color open";

class SettingsScreen extends StatefulWidget {
  final Obf? board;
  final ParrotProject? project;
  const SettingsScreen({super.key, this.board, this.project});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _Category get selectedCategory {
    dynamic result = globalRestorationQuickstore[selectedCategoriesKey];
    _Category out = categories[0];
    if (result is List && result.isNotEmpty) {
      final selectedCategory = categories
          .where((category) => category.label == result.last)
          .firstOrNull;
      if (selectedCategory != null) {
        out = selectedCategory;
      }
    }
    return out;
  }

  late final List<_Category> categories;

  @override
  void initState() {
    const appbarColorSettingName = "Appbar Color";
    categories = [
      if (widget.project != null) _ProjectCategory(widget.project!),
      SettingsOptionsCategory("General", [
        _ToggleOption("Enable Feature X"),
        _DropdownOption("TTS Voice", ["english", "spanish", "french"]),
      ]),
      SettingsOptionsCategory("Admin", [
        _DropdownOption("Admin-Lock", ["None", "Math"]),
      ]),
      SettingsOptionsCategory("Appearance", [
        _ColorChangeOption(appbarColorSettingName, defaultAppbarColor),
      ]),
      SettingsOptionsCategory("About", [
        _SubtitleOption("Version", "1.0.0"),
        _NavigatableOption("License"),
      ]),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (globalRestorationQuickstore.isTrue(appbarColorOpenKey)) {
        showAppbarColorPickerDialog(
          context,
          getAppbarColor(),
          (Color value) async {
            await setSetting(appbarColorSettingName, value.toARGB32());
          },
        );
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= _wideScreenSize;

    return Scaffold(
      appBar: SettingsThemedAppbar(title: Text("Settings")),
      body: isWideScreen ? _splitView() : _expandableTilesView(),
    );
  }

  Widget _splitView() {
    return Row(
      children: [
        Flexible(
          flex: 2,
          child: ListView(
            children: categories.map((category) {
              return ListTile(
                selected: category == selectedCategory,
                title: Text(category.label),
                onTap: () async => await setCategory(category),
              );
            }).toList(),
          ),
        ),
        const VerticalDivider(width: 1),
        Flexible(flex: 5, child: selectedCategory.content),
      ],
    );
  }

  Future<void> setCategory(_Category category) async {
    await globalRestorationQuickstore.writeData(selectedCategoriesKey, [
      category.label,
    ]);
    setState(() {});
  }

  Widget _expandableTilesView() {
    return ListView(
      children: categories.map((category) {
        return ExpansionTile(
          title: Text(category.label),
          onExpansionChanged: (expanded) async {
            List<String> selectedCategories =
                globalRestorationQuickstore[selectedCategoriesKey] ?? [];

            if (expanded) {
              selectedCategories.add(category.label);
            } else {
              selectedCategories.remove(category.label);
            }

            await globalRestorationQuickstore.writeData(
              selectedCategoriesKey,
              selectedCategories,
            );
          },
          initiallyExpanded: globalRestorationQuickstore[selectedCategoriesKey]
              ?.contains(category.label),
          children: [category.content],
        );
      }).toList(),
    );
  }
}

class _Category {
  final String label;

  const _Category({required this.label});

  Widget get content => Placeholder();
}

class SettingsOptionsCategory extends _Category {
  final List<_SettingsOption> _settingOptions;
  SettingsOptionsCategory(String label, this._settingOptions)
    : super(label: label);

  @override
  Widget get content {
    Widget toWidget(_SettingsOption option) => option.asWidget;
    return Padding(
      padding: const EdgeInsets.all(_padding),
      child: Column(children: _settingOptions.map(toWidget).toList()),
    );
  }
}

class _ProjectCategory extends _Category {
  final ParrotProject project;
  _ProjectCategory(this.project)
    : assert(
        project.settings != null,
        "${project.name} settings are equal to null when entering the settings screen",
      ),
      super(label: "Project");

  @override
  Widget get content => Padding(
    padding: const EdgeInsets.all(_padding),
    child: Column(
      children: [
        _ToggleTile(
          key: UniqueKey(),
          label: "Show Sentence Bar",
          onChange: (val) {
            project.settings?.writeShowSentenceBar(val);
          },
          initialValue: project.settings?.showSentenceBar ?? true,
        ),
      ],
    ),
  );
}

class _ToggleTile extends StatefulWidget {
  final String label;
  final bool initialValue;
  final Function(bool) onChange;
  const _ToggleTile({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChange,
  });

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  late final ValueNotifier<bool> notifier;
  @override
  void initState() {
    notifier = ValueNotifier(widget.initialValue);
    super.initState();
  }

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, value, child) {
        return SwitchListTile(
          title: Text(widget.label),
          onChanged: (val) {
            notifier.value = val;
            widget.onChange(val);
          },
          value: value,
        );
      },
    );
  }
}

abstract class _SettingsOption {
  String get label;
  Widget get asWidget;
}

class _ToggleOption extends _SettingsOption {
  @override
  final String label;

  _ToggleOption(this.label);
  @override
  Widget get asWidget => SettingsSwitchTile(key: UniqueKey(), label: label);
}

class _DropdownOption extends _SettingsOption {
  @override
  final String label;
  final List<String> options;

  _DropdownOption(this.label, this.options);
  @override
  Widget get asWidget => SettingsDropDown(
    label: label,
    key: UniqueKey(),
    defaultValue: options.firstOrNull ?? "empty",
    options: options,
  );
}

class _NavigatableOption extends _SettingsOption {
  @override
  final String label;

  _NavigatableOption(this.label);
  @override
  Widget get asWidget =>
      ListTile(title: Text(label), trailing: Icon(Icons.arrow_forward_ios));
}

class _SubtitleOption extends _SettingsOption {
  @override
  final String label;
  final String subtitle;

  _SubtitleOption(this.label, this.subtitle);
  @override
  Widget get asWidget => ListTile(title: Text(label), subtitle: Text(subtitle));
}

class _ColorChangeOption extends _SettingsOption {
  @override
  final String label;
  final int defaultValue;
  _ColorChangeOption(this.label, this.defaultValue);
  @override
  Widget get asWidget =>
      SettingsColorChange(label: label, defaultValue: defaultValue);
}
