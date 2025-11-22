import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sms_message.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoFilterSpam = true;
  bool _notifyOnOTP = true;
  bool _notifyOnBankAlerts = true;
  bool _notifyOnImportant = true;

  final Map<SmsCategory, bool> _categoryNotifications = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoFilterSpam = prefs.getBool('autoFilterSpam') ?? true;
      _notifyOnOTP = prefs.getBool('notifyOnOTP') ?? true;
      _notifyOnBankAlerts = prefs.getBool('notifyOnBankAlerts') ?? true;
      _notifyOnImportant = prefs.getBool('notifyOnImportant') ?? true;

      // Load category notifications
      for (var category in SmsCategory.values) {
        _categoryNotifications[category] =
            prefs.getBool('notify_${category.name}') ?? true;
      }
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSection('General Settings', [
            SwitchListTile(
              title: const Text('Auto Filter Spam'),
              subtitle: const Text(
                'Automatically detect and filter spam messages',
              ),
              value: _autoFilterSpam,
              onChanged: (value) {
                setState(() => _autoFilterSpam = value);
                _saveSetting('autoFilterSpam', value);
              },
            ),
          ]),

          _buildSection('Notification Preferences', [
            SwitchListTile(
              title: const Text('Notify on OTP'),
              subtitle: const Text('Show notifications for OTP messages'),
              value: _notifyOnOTP,
              onChanged: (value) {
                setState(() => _notifyOnOTP = value);
                _saveSetting('notifyOnOTP', value);
              },
            ),
            SwitchListTile(
              title: const Text('Notify on Bank Alerts'),
              subtitle: const Text('Show notifications for bank transactions'),
              value: _notifyOnBankAlerts,
              onChanged: (value) {
                setState(() => _notifyOnBankAlerts = value);
                _saveSetting('notifyOnBankAlerts', value);
              },
            ),
            SwitchListTile(
              title: const Text('Notify on Important Messages'),
              subtitle: const Text('Show notifications for important messages'),
              value: _notifyOnImportant,
              onChanged: (value) {
                setState(() => _notifyOnImportant = value);
                _saveSetting('notifyOnImportant', value);
              },
            ),
          ]),

          _buildSection(
            'Category Notifications',
            SmsCategory.values.map((category) {
              return SwitchListTile(
                title: Row(
                  children: [
                    Text(category.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(category.displayName),
                  ],
                ),
                value: _categoryNotifications[category] ?? true,
                onChanged: (value) {
                  setState(() => _categoryNotifications[category] = value);
                  _saveSetting('notify_${category.name}', value);
                },
              );
            }).toList(),
          ),

          _buildSection('About', [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('App Version'),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Show privacy policy
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Show terms
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
}
