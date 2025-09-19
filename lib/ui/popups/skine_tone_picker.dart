import 'package:flutter/material.dart';
import 'package:parrotaac/backend/symbol_sets/open_symbol.dart';
import 'package:parrotaac/backend/symbol_sets/symbol_set.dart';
import 'package:parrotaac/ui/util_widgets/simple_future_builder.dart';
import 'package:parrotaac/utils.dart';

void showSkinToneDialog(
  BuildContext context,
  SymbolResult result,
  Function(String tone) onSelected,
) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return SkintoneDialog(
        imageUrl: result.originalImageUrl!,
        startingTone: result.currentVariant as String,
        onSelect: onSelected,
      );
    },
  );
}

class SkintoneDialog extends StatefulWidget {
  final String imageUrl;
  final Function(String newUrl) onSelect;
  final String startingTone;
  const SkintoneDialog({
    super.key,
    required this.imageUrl,
    required this.startingTone,
    required this.onSelect,
  });

  @override
  State<SkintoneDialog> createState() => _SkintoneDialogState();
}

class _SkintoneDialogState extends State<SkintoneDialog> {
  late String selectedTone;
  //TODO: make this a future somhow and build the options based of of it? ca has the baby with no medium light
  late final Future<Map<String, Widget>> _widgetCache;
  @override
  void initState() {
    selectedTone = widget.startingTone;
    _widgetCache = _preloadImages();
    super.initState();
  }

  Future<Map<String, Widget>> _preloadImages() async {
    final Map<String, Widget> out = {};
    out['default'] = await futureImageFromUrl(widget.imageUrl, context);

    //in the future it might be nice to have a get vareints function instead of this approach, that way it's decoupled
    for (String toneName in OpenSymbolResult.skinTones.keys) {
      //TODO: handle this better maybe at the caching level, essintally the get single file can throw an http exception is how it is working but if I cached the response I wouldn't need to do this, will likely need  a custom caching solution though.
      try {
        out[toneName] = await futureImageFromUrl(
          OpenSymbolResult.getUpdatedUrl(toneName, widget.imageUrl),
          // ignore: use_build_context_synchronously
          context,
        );
      }
      // ignore: empty_catches
      catch (e) {}
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width * .6;
    final height = screenSize.height * .6;
    return AlertDialog(
      title: Text('Choose Skin Tone'),
      content: SizedBox(
        width: width,
        height: height,
        child: SimpleFutureBuilder(
          future: _widgetCache,
          onData: (cache) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: cache[selectedTone]!),
              ConstrainedBox(constraints: const BoxConstraints(maxHeight: 16)),
              SizedBox(
                width: width,
                child: Center(
                  child: Wrap(
                    spacing: 8,
                    children: cache.entries.map((entry) {
                      final toneName = entry.key;
                      final isSelected = selectedTone == toneName;

                      return SizedBox(
                        child: ChoiceChip(
                          label: Text(toneName),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              selectedTone = toneName;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSelect(selectedTone);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
