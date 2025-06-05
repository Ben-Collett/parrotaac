import 'package:flutter/material.dart';

class SegmentedButtonMenu<T> extends StatefulWidget {
  final List<T> values;
  final T initialValue;
  final void Function(dynamic)? onChange;
  final List<Widget> Function(dynamic) getContent;
  final ButtonSegment<T> Function<T>(dynamic)? toSegment;
  final double? maxWidth;

  ///[values] are the possible values for the segmented button
  ///[getContent] defines which widgets should be displayed in the content section depending on the current value
  ///[toSegment] converts an object of type T to a widget, if it is null then the segments will contain a Text with the contents of value.toString() for each of the values
  const SegmentedButtonMenu({
    super.key,
    required this.values,
    required this.initialValue,
    required this.getContent,
    this.maxWidth,
    this.onChange,
    this.toSegment,
  });

  @override
  State<SegmentedButtonMenu> createState() => _SegmentedButtonMenuState<T>();
}

class _SegmentedButtonMenuState<T> extends State<SegmentedButtonMenu> {
  late T value;
  @override
  void initState() {
    this.value = widget.initialValue;
    super.initState();
  }

  ButtonSegment<T> _toSegment(T value) {
    if (widget.toSegment != null) {
      return widget.toSegment!(value);
    }
    return ButtonSegment(value: value, label: Text(value.toString()));
  }

  //takes a set because that is required by SegmentedButton's onChange
  void _onChange(Set<T> input) {
    assert(input.length == 1);
    setState(() {
      value = input.first;
    });
    if (widget.onChange != null) {
      widget.onChange!(value);
    }
  }

  SegmentedButton _createSegmentedButton() {
    Iterable<ButtonSegment<T>> segmants =
        widget.values.whereType<T>().map(_toSegment);

    assert(widget.values.length == segmants.length);
    return SegmentedButton<T>(
      segments: segmants.toList(),
      selected: {value},
      onSelectionChanged: _onChange,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> content = widget.getContent(value);
    return Column(
      children: [
        ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: widget.maxWidth ?? double.infinity),
          child: SizedBox(
            width: widget.maxWidth,
            child: _createSegmentedButton(),
          ),
        ),
        ...content
      ],
    );
  }
}
