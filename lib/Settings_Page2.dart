import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  final Function(Color) onAppBarColorChanged;

  SettingsPage({required this.onAppBarColorChanged});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Color _appBarColor = Colors.blue;
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  String _language = 'English';

  void _pickAppBarColor() {
    showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pick a color for the App Bar"),
          content: ColorPicker(
            pickerColor: _appBarColor,
            onColorChanged: (Color color) {
              setState(() {
                _appBarColor = color;
              });
              widget.onAppBarColorChanged(color);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  void _changeLanguage(String? value) {
    setState(() {
      _language = value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: _appBarColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: Text("Change App Bar Color"),
              trailing: Icon(Icons.color_lens),
              onTap: _pickAppBarColor,
            ),
            ListTile(
              title: Text("Enable Dark Mode"),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: _toggleTheme,
              ),
            ),
            ListTile(
              title: Text("Font Size"),
              subtitle: Text("Adjust the font size of text"),
              trailing: DropdownButton<double>(
                value: _fontSize,
                items: [14.0, 16.0, 18.0, 20.0]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text("$e"),
                        ))
                    .toList(),
                onChanged: (double? newValue) {
                  setState(() {
                    _fontSize = newValue!;
                  });
                },
              ),
            ),
            ListTile(
              title: Text("Language"),
              subtitle: Text("Change the app's language"),
              trailing: DropdownButton<String>(
                value: _language,
                items: ['English', 'Spanish', 'French', 'German']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: _changeLanguage,
              ),
            ),
            ListTile(
              title: Text("Enable Notifications"),
              trailing: Switch(
                value: true,
                onChanged: (bool value) {
                  
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
