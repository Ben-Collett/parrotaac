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
        _LicenseOption(),
      ]),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (globalRestorationQuickstore.isTrue(appbarColorOpenKey)) {
        showAppbarColorPickerDialog(context, getAppbarColor(), (
          Color value,
        ) async {
          await setSetting(appbarColorSettingName, value.toARGB32());
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= _wideScreenSize;

    return Scaffold(
      appBar: SettingsThemedAppbar(title: Text("Settings")),
      body: isWideScreen ? _splitView() : _categoryListView(),
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
        Flexible(
          flex: 5,
          child: SettingsDetailNavigator(
            initialContent: selectedCategory.content,
          ),
        ),
      ],
    );
  }

  Future<void> setCategory(_Category category) async {
    await globalRestorationQuickstore.writeData(selectedCategoriesKey, [
      category.label,
    ]);
    setState(() {});
  }

  Widget _categoryListView() {
    return ListView(
      children: categories.map((category) {
        return ListTile(
          title: Text(category.label),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            await setCategory(category);
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      CategoryDetailScreen(category: category),
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }
}

class SettingsDetailNavigator extends StatefulWidget {
  final Widget initialContent;

  const SettingsDetailNavigator({super.key, required this.initialContent});

  @override
  State<SettingsDetailNavigator> createState() =>
      _SettingsDetailNavigatorState();
}

class _SettingsDetailNavigatorState extends State<SettingsDetailNavigator> {
  final List<Widget> _navigationStack = [];

  void push(Widget page) {
    setState(() {
      _navigationStack.add(page);
    });
  }

  void pop() {
    if (_navigationStack.isNotEmpty) {
      setState(() {
        _navigationStack.removeLast();
      });
    }
  }

  bool get canPop => _navigationStack.isNotEmpty;

  Widget get currentPage {
    if (_navigationStack.isNotEmpty) {
      return _navigationStack.last;
    }
    return widget.initialContent;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailNavigation(
      push: push,
      pop: pop,
      canPop: canPop,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: _SettingsDetailWrapper(
          key: ValueKey(_navigationStack.length),
          canPop: canPop,
          onBack: pop,
          child: currentPage,
        ),
      ),
    );
  }
}

class SettingsDetailNavigation extends InheritedWidget {
  final void Function(Widget) push;
  final VoidCallback pop;
  final bool canPop;

  const SettingsDetailNavigation({
    super.key,
    required this.push,
    required this.pop,
    required this.canPop,
    required super.child,
  });

  static SettingsDetailNavigation? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SettingsDetailNavigation>();
  }

  @override
  bool updateShouldNotify(SettingsDetailNavigation oldWidget) {
    return canPop != oldWidget.canPop;
  }
}

class _SettingsDetailWrapper extends StatelessWidget {
  final bool canPop;
  final VoidCallback onBack;
  final Widget child;

  const _SettingsDetailWrapper({
    super.key,
    required this.canPop,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (canPop)
          Container(
            height: 56,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(icon: Icon(Icons.arrow_back), onPressed: onBack),
          ),
        Expanded(child: child),
      ],
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final _Category category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SettingsThemedAppbar(
        title: Text(category.label),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: category.content,
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
        _ToggleTile(
          key: UniqueKey(),
          label: "Always Show Button Labels",
          onChange: (val) {
            project.settings?.writeShowButtonLabels(val);
          },
          initialValue: project.settings?.showButtonLabels ?? true,
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
  final Widget Function() destinationBuilder;

  _NavigatableOption(this.label, this.destinationBuilder);

  @override
  Widget get asWidget {
    return Builder(
      builder: (context) {
        return ListTile(
          title: Text(label),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            final detailNav = SettingsDetailNavigation.of(context);
            if (detailNav != null) {
              detailNav.push(destinationBuilder());
            } else {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => destinationBuilder()));
            }
          },
        );
      },
    );
  }
}

class _LicenseOption extends _SettingsOption {
  @override
  final String label = "License";

  @override
  Widget get asWidget {
    return Builder(
      builder: (context) {
        return ListTile(
          title: Text(label),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            final appbarColor = getAppbarColor();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Theme(
                  data: Theme.of(context).copyWith(
                    appBarTheme: AppBarTheme(
                      backgroundColor: appbarColor,
                      foregroundColor:
                          ThemeData.estimateBrightnessForColor(appbarColor) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  child: const LicensePage(
                    applicationName: "Parrot AAC",
                    applicationVersion: "1.0.0",
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
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
