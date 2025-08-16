import 'package:flutter/material.dart';

class MultiListenableBuilder extends StatefulWidget {
  final Iterable<Listenable> listenables;
  final TransitionBuilder builder;
  const MultiListenableBuilder(
      {super.key, required this.listenables, required this.builder});

  @override
  State<MultiListenableBuilder> createState() => _MultiListenableBuilderState();
}

class _MultiListenableBuilderState extends State<MultiListenableBuilder> {
  late final Listenable listenable;
  @override
  void initState() {
    listenable = Listenable.merge(List.of(widget.listenables));
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: widget.builder,
    );
  }
}
