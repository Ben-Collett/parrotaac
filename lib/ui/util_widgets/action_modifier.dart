import 'package:flutter/material.dart';
import 'package:parrotaac/ui/actions/button_actions.dart';
import 'package:parrotaac/ui/parrot_button.dart';

const Map<ParrotAction, String> _actionToLabelMap = {
  ParrotAction.playButton: "play button",
  ParrotAction.addToSentenceBox: "add to sentence box",
  ParrotAction.speak: "play sentence box",
  ParrotAction.backspace: "backspace",
  ParrotAction.clear: "clear sentence box",
};

//TODO: optimize, switching the button to add shouldn't rebuild the whole thing and moving actions shoulding rebuild the header.
//TODO: colors need improved, and the reoderable list might look better if it was a animetedroderable list
class ActionConfig extends StatefulWidget {
  final ParrotButtonNotifier controller;
  final double width;
  final double totalHeight;
  final double topBarHeight;
  const ActionConfig(
      {super.key,
      required this.controller,
      required this.width,
      required this.totalHeight,
      required this.topBarHeight});

  @override
  State<ActionConfig> createState() => _ActionConfigState();
}

class _ActionConfigState extends State<ActionConfig> {
  ParrotAction selectedAction = ParrotAction.speak;
  ParrotButtonNotifier get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    List<ParrotAction> actions = controller.actions.nonNulls.toList();
    List<Widget> widgets = [];
    for (int i = 0; i < actions.length; i++) {
      widgets.add(
        ReorderableDragStartListener(
          index: i,
          key: UniqueKey(),
          child: ListTile(
            title: _actionToWidgetText(actions[i]),
            trailing: IconButton(
              onPressed: () {
                actions.removeAt(i);
                controller.updateActions(actions);
                setState(() {});
              },
              icon: Icon(Icons.close),
            ),
          ),
        ),
      );
    }
    DropdownMenuEntry<ParrotAction> toDropdownEntry(
            MapEntry<ParrotAction, String> entry) =>
        DropdownMenuEntry(value: entry.key, label: entry.value);

    List<DropdownMenuEntry<ParrotAction>> entries =
        _actionToLabelMap.entries.map(toDropdownEntry).toList();
    double topBarHeight = widget.topBarHeight;
    double totalHeight = widget.totalHeight;

    return Column(
      children: [
        Container(
          height: topBarHeight,
          color: Colors.greenAccent,
          child: Stack(
            children: [
              Center(
                child: DropdownMenu<ParrotAction>(
                  onSelected: (value) {
                    setState(() {
                      selectedAction = value!;
                    });
                  },
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (Set<WidgetState> states) {
                        if (states.isEmpty) {
                          return Colors.white;
                        }
                        return null;
                      },
                    ),
                  ),
                  requestFocusOnTap: false,
                  inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: Colors.white,
                      outlineBorder: BorderSide(color: Colors.black)),
                  initialSelection: selectedAction,
                  dropdownMenuEntries: entries,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  child: MaterialButton(
                    color: Colors.orange,
                    onPressed: () {
                      actions.add(selectedAction);
                      controller.updateActions(actions);
                      setState(() {});
                    },
                    textColor: Colors.lightBlue,
                    child: Text("add action"),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: totalHeight - topBarHeight,
          width: widget.width,
          child: Container(
            color: Colors.white,
            child: ReorderableListView(
                buildDefaultDragHandles: false,
                children: widgets,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) {
                    newIndex--;
                  }
                  final ParrotAction action = actions.removeAt(oldIndex);
                  actions.insert(newIndex, action);
                  controller.updateActions(actions);
                  setState(() {});
                }),
          ),
        ),
      ],
    );
  }
}

Widget _actionToWidgetText(ParrotAction action) {
  return Text(
    _actionToLabelMap[action] ?? "UNKNOWN ACTION",
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    key: UniqueKey(),
  );
}
