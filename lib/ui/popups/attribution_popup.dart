import 'package:flutter/material.dart';
import 'package:parrotaac/backend/attribution_data.dart';
import 'package:parrotaac/ui/util_widgets/simple_future_builder.dart';
import 'package:parrotaac/ui/util_widgets/url_text.dart';

Future<void> showAttributionPopup(
  BuildContext context,
  Future<AttributionData> data,
) => showDialog(
  context: context,
  builder: (context) => _AttributionDialog(data),
);

class _AttributionDialog extends StatelessWidget {
  final Future<AttributionData> data;
  const _AttributionDialog(this.data);

  Widget propertyToWidget(AttributionProperty property) {
    const double fontSize = 28;
    final bool isHyperlink = property.url != null;
    final Widget text = isHyperlink
        ? UrlText(text: property.value!, url: property.url!, fontSize: fontSize)
        : Text(
            property.value!,
            style: TextStyle(fontSize: fontSize),
            maxLines: 1,
          );

    return Row(
      children: [
        Text("${property.label}: ", style: TextStyle(fontSize: fontSize)),
        text,
      ],
    );
  }

  Widget _buildColumn(AttributionData data) {
    return Column(
      children: data.properties
          .where((property) => property.value != null)
          .map((property) => propertyToWidget(property))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: SimpleFutureBuilder(future: data, onData: _buildColumn),
      ),
    );
  }
}
