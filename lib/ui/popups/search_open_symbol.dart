import 'dart:math';
import 'package:flutter/material.dart';
import 'package:parrotaac/backend/symbol_sets/open_symbol.dart';
import 'package:parrotaac/backend/symbol_sets/symbol_set.dart';
import 'package:parrotaac/ui/popups/attribution_popup.dart';
import 'package:parrotaac/ui/popups/skine_tone_picker.dart';
import 'package:parrotaac/ui/util_widgets/simple_future_builder.dart';

const _gridBackgroundColor = Colors.blue;
Future<OpenSymbolResult?> showOpenSymbolSearchDialog(
  BuildContext context, {
  String? initialSearch,
}) {
  return showDialog<OpenSymbolResult>(
    context: context,
    builder: (context) => _OpenSymbolSearchPopup(initialSearch ?? ""),
  );
}

class _OpenSymbolSearchPopup extends StatefulWidget {
  final String initialSearch;
  const _OpenSymbolSearchPopup(this.initialSearch);

  @override
  State<_OpenSymbolSearchPopup> createState() => _OpenSymbolSearchPopupState();
}

class _OpenSymbolSearchPopupState extends State<_OpenSymbolSearchPopup> {
  late final ValueNotifier<String> _searchNotifier;
  late final ValueNotifier<SymbolResult?> _selectedResultController;
  final Map<String, String> _changedSkinToneUrls = {};

  String get text => _searchNotifier.value;
  @override
  void initState() {
    _selectedResultController = ValueNotifier(null);
    _searchNotifier = ValueNotifier(widget.initialSearch);

    super.initState();
  }

  @override
  void dispose() {
    _selectedResultController.dispose();
    _searchNotifier.dispose();
    super.dispose();
  }

  Widget _buildGrid(List<SymbolResult> results, int crossAxisCount) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1,
      ),
      itemBuilder: (BuildContext context, int index) {
        if (index >= results.length) return null;

        String initialSkintone =
            _changedSkinToneUrls[results[index].originalImageUrl!] ?? 'default';

        return _SymbolGridEntry(
          result: results[index],
          initialSkintone: initialSkintone,
          onSkintonChange: (skinTone) {
            _changedSkinToneUrls[results[index].originalImageUrl!] = skinTone;
          },
          selectedResultController: _selectedResultController,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    const desieredImageWidth = 200;
    final int crossAxisCount = max((width / desieredImageWidth).truncate(), 1);

    final String searchHintText = widget.initialSearch.trim() != ""
        ? widget.initialSearch
        : "search open symbols...";

    return AlertDialog(
      title: TextField(
        onChanged: (text) {
          if (text.isNotEmpty) {
            _searchNotifier.value = text;
          } else {
            _searchNotifier.value = widget.initialSearch.trim();
          }
        },
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: searchHintText,
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder(
              valueListenable: _selectedResultController,
              builder: (context, value, child) {
                return ElevatedButton(
                  onPressed: value == null
                      ? null
                      : () {
                          showAttributionPopup(context, value.attributionData);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: const Color.fromARGB(255, 240, 240, 240),
                  ),
                  child: const Text("attribution"),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("cancel"),
                ),
                ValueListenableBuilder(
                  valueListenable: _selectedResultController,
                  builder: (context, value, child) {
                    return TextButton(
                      onPressed: value == null
                          ? null
                          : () {
                              Navigator.of(
                                context,
                              ).pop(_selectedResultController.value);
                            },
                      child: const Text("confirm"),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
      content: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        child: ValueListenableBuilder(
          valueListenable: _searchNotifier,
          builder: (context, value, child) {
            Future<List<SymbolResult>> results = OpenSymbolSet().search(value);
            return Material(
              color: _gridBackgroundColor,
              child: SizedBox(
                width: width * .8,
                height: height,
                child: SimpleFutureBuilder(
                  key: ValueKey(value),
                  future: results,
                  onData: (results) {
                    return _buildGrid(results, crossAxisCount);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SelectedBubble<T> extends StatelessWidget {
  final double radius;
  final bool selected;
  final double borderPreportion;
  final double checkMarckPreportion;
  const _SelectedBubble({
    required this.radius,
    required this.selected,
    required this.borderPreportion,
    required this.checkMarckPreportion,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: kThemeChangeDuration,
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.white,
        shape: BoxShape.circle,
        border: BoxBorder.all(width: radius * borderPreportion),
      ),

      width: radius,
      height: radius,

      child: selected
          ? Icon(
              Icons.check,
              size: radius * checkMarckPreportion,
              color: Colors.white,
            )
          : null,
    );
  }
}

class _TonesBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: const Text(
        'TONES',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SymbolGridEntry extends StatefulWidget {
  final SymbolResult result;
  final ValueNotifier<SymbolResult?> selectedResultController;
  final void Function(String skinTone) onSkintonChange;
  final String initialSkintone;
  const _SymbolGridEntry({
    required this.result,
    required this.selectedResultController,
    required this.initialSkintone,
    required this.onSkintonChange,
  });

  @override
  State<_SymbolGridEntry> createState() => _SymbolGridEntryState();
}

class _SymbolGridEntryState extends State<_SymbolGridEntry> {
  late final ValueNotifier<bool> isSelectedNotifier;
  bool get _isSelected =>
      widget.selectedResultController.value?.originalImageUrl ==
      widget.result.originalImageUrl;
  @override
  void initState() {
    isSelectedNotifier = ValueNotifier(_isSelected);
    widget.result.changeVariant(widget.initialSkintone);
    widget.selectedResultController.addListener(_updateIsSelectedNotifier);

    super.initState();
  }

  @override
  void dispose() {
    widget.selectedResultController.removeListener(_updateIsSelectedNotifier);
    isSelectedNotifier.dispose();
    super.dispose();
  }

  void _updateIsSelectedNotifier() {
    isSelectedNotifier.value = _isSelected;
  }

  @override
  Widget build(BuildContext context) {
    const radiusPreportion = .15;
    const borderPreportion = .07;
    const checkMarckPreportion = .85;

    const double imagePadding = 8;

    final theCurrentSymbolSupportsTones = widget.result.supportsTones;
    return ValueListenableBuilder(
      valueListenable: isSelectedNotifier,
      builder: (context, val, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final radius =
                radiusPreportion *
                min(constraints.maxWidth, constraints.maxHeight);

            return InkWell(
              onTap: () {
                widget.selectedResultController.value = widget.result;
              },
              onLongPress: () {
                if (theCurrentSymbolSupportsTones) {
                  showSkinToneDialog(context, widget.result, (tone) {
                    setState(() {
                      widget.onSkintonChange(tone);
                      widget.result.changeVariant(tone);
                    });
                  });
                }
              },
              child: Stack(
                children: [
                  _SizedImageButton(
                    key: ValueKey(widget.result.imageUrl),
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    image: widget.result.asImageWidget,
                    paddingSize: imagePadding,
                  ),
                  if (theCurrentSymbolSupportsTones)
                    Positioned(child: _TonesBanner()),
                  Positioned(
                    right: imagePadding,
                    top: imagePadding,
                    child: _SelectedBubble(
                      radius: radius,
                      selected: isSelectedNotifier.value,
                      borderPreportion: borderPreportion,
                      checkMarckPreportion: checkMarckPreportion,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SizedImageButton extends StatelessWidget {
  final double width;
  final double height;
  final Widget image;
  final double paddingSize;
  const _SizedImageButton({
    super.key,
    required this.width,
    required this.height,
    required this.image,
    required this.paddingSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Padding(padding: EdgeInsets.all(paddingSize), child: image),
    );
  }
}
