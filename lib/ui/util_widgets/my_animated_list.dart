import 'package:flutter/material.dart';

class MyAnimatedList extends StatelessWidget {
  const MyAnimatedList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class AnimatedListController<T> {
  final List<T> data = [];
  bool Function(T)? filter;
  List<T> get filteredData {
    if (filter == null) {
      return data;
    }
    return data.where(filter!).toList();
  }

  void removeElement(int index) {}
  void updateFilter(bool Function(T) filter) {}
}
