import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: <Widget>[
          _buildSettingsGroup(
            title: 'General Settings',
            children: [
              _buildSwitchListTile('Enable Notifications', true),
              _buildSwitchListTile('Enable Dark Mode', false),
            ],
          ),
          _buildSettingsGroup(
            title: 'Privacy & Security',
            children: [
              _buildSwitchListTile('Enable Face ID', false),
              _buildSwitchListTile('Location Services', true),
            ],
          ),
          _buildSettingsGroup(
            title: 'Account',
            children: [
              _buildSwitchListTile('Login with Email', false),
              _buildSwitchListTile('Enable Two-Factor Authentication', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
      {required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ),
          ...children, // Add the individual toggle switches
        ],
      ),
    );
  }

  Widget _buildSwitchListTile(String title, bool value) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (bool value) {
        // Handle the toggle value change here
        print('$title enabled: $value');
      },
      activeColor: Colors.blue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      tileColor: Colors.grey.shade100,
    );
  }
}
