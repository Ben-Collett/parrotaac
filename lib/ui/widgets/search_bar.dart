import 'package:flutter/material.dart';

class GlowingSearchBar extends StatefulWidget {
  final TextEditingController textController;
  final double padding;
  const GlowingSearchBar({
    super.key,
    required this.textController,
    required this.padding,
  });

  @override
  GlowingSearchBarState createState() => GlowingSearchBarState();
}

class GlowingSearchBarState extends State<GlowingSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(widget.padding),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: Colors.pinkAccent,
                    //blurRadius+spreadRadius = full radius, which should be equal to padding
                    blurRadius: widget.padding / 2,
                    spreadRadius: widget.padding / 2,
                  ),
                ]
              : [],
        ),
        child: TextField(
          focusNode: _focusNode,
          controller: widget.textController,
          decoration: InputDecoration(
            hintText: "Search…",
            prefixIcon: Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
