import 'package:flutter/material.dart';
import 'package:lapboost_app/models/sql_service.dart';
import 'package:lapboost_app/screens/auth_screen.dart';
import 'package:mysql1/mysql1.dart';

class SettingsPage extends StatefulWidget {
  final ResultRow user;
  const SettingsPage({super.key, required this.user});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Controllers for TextFields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // For the dropdown menus
  String? _selectedTheme = 'Light';
  String? _selectedLanguage = 'English';

  // For the radio buttons
  String? _deviceOwnership = 'Laptop';

  @override
  void initState() {
    super.initState();
    // Initialize the controllers with current user values if needed
    _usernameController.text = widget.user['Social_Media_Handle'];
    _passwordController.text = widget.user['Password'];
    _addressController.text = widget.user['Address'] ?? '';
    _phoneController.text = widget.user['Mobile_Number'] ?? '';
  }

  @override
  void dispose() {
    // Dispose controllers when done
    _usernameController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final conn = await SqlService.getConnection();
    Map<String, dynamic> updates = {};

    // Check for changes in text fields
    if (_usernameController.text != widget.user['Social_Media_Handle']) {
      updates['Social_Media_Handle'] = _usernameController.text;
    }
    if (_passwordController.text != widget.user['Password']) {
      updates['Password'] = _passwordController.text;
    }
    if (_addressController.text != (widget.user['Address'] ?? '')) {
      updates['Address'] = _addressController.text;
    }
    if (_phoneController.text != (widget.user['Mobile_Number'] ?? '')) {
      updates['Mobile_Number'] = _phoneController.text;
    }

    // Check for changes in device ownership
    String currentDeviceOwnership = widget.user['Devices_Owned'] ?? '';
    String newDeviceOwnership = '';
    if (_deviceOwnership == 'Laptop') {
      newDeviceOwnership = 'Laptop';
    } else if (_deviceOwnership == 'PC') {
      newDeviceOwnership = 'PC';
    } else if (_deviceOwnership == 'Both') {
      newDeviceOwnership = 'Laptop and PC';
    }

    if (newDeviceOwnership != currentDeviceOwnership) {
      updates['Devices_Owned'] = newDeviceOwnership;
    }
    if (updates.isNotEmpty) {
      String setClause = updates.keys.map((key) => "$key = ?").join(", ");
      List<dynamic> values = updates.values.toList();
      values.add(widget.user['Customer_ID']);

      await conn.query(
        'UPDATE customers SET $setClause WHERE Customer_ID = ?',
        values,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Account updated successfully, log back in to verify your new credentials')),
      );
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes detected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // Section 1: Theme and Language
          Text(
            'Theme & Language',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
          ),
          const SizedBox(height: 16),
          // Theme selection
          ListTile(
            title: const Text('Theme'),
            trailing: DropdownButton<String>(
              value: _selectedTheme,
              items: const [
                DropdownMenuItem<String>(
                  value: 'Light',
                  child: Text('Light'),
                ),
                DropdownMenuItem<String>(
                  value: 'Dark',
                  child: Text('Dark'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value;
                });
              },
              hint: const Text('Select theme'),
            ),
          ),
          // Language selection
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              items: const [
                DropdownMenuItem<String>(
                  value: 'English',
                  child: Text('English'),
                ),
                DropdownMenuItem<String>(
                  value: 'Arabic',
                  child: Text('Arabic'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
              hint: const Text('Select language'),
            ),
          ),
          const Divider(),

          // Section 2: Account Settings
          Text(
            'Account Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
          ),
          const SizedBox(height: 16),
          // Username field
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
              hintText: 'Enter your username',
            ),
          ),
          const SizedBox(height: 16),
          // Password field
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              hintText: 'Enter your password',
            ),
          ),
          const SizedBox(height: 16),
          // Address field
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address (Optional)',
              border: OutlineInputBorder(),
              hintText: 'Enter your address',
            ),
          ),
          const SizedBox(height: 16),
          // Phone number field
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              hintText: 'Enter your phone number',
            ),
          ),
          const SizedBox(height: 16),
          // Device Ownership selection using Wrap
          const Text(
            'Device Ownership',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 12.0, // Horizontal space between the items
            runSpacing: 8.0, // Vertical space between the items
            children: [
              Row(
                children: [
                  Radio<String>(
                    value: 'Laptop',
                    groupValue: _deviceOwnership,
                    onChanged: (value) {
                      setState(() {
                        _deviceOwnership = value;
                      });
                    },
                  ),
                  const Text('Laptop'),
                ],
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'PC',
                    groupValue: _deviceOwnership,
                    onChanged: (value) {
                      setState(() {
                        _deviceOwnership = value;
                      });
                    },
                  ),
                  const Text('PC'),
                ],
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'Both',
                    groupValue: _deviceOwnership,
                    onChanged: (value) {
                      setState(() {
                        _deviceOwnership = value;
                      });
                    },
                  ),
                  const Text('Both'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Save Changes Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Save Account Data',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Logged out successfully')));
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const AuthScreen()),
                        (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                Widget yesButton = TextButton(
                  child: const Text("YES"),
                  onPressed: () async {
                    final conn = await SqlService.getConnection();
                    conn.query('''
                DELETE FROM customers
                WHERE Customer_ID= ?
                ''', [widget.user['Customer_ID']]);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Account deleted successfully')));
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const AuthScreen()),
                        (route) => false);
                  },
                );
                Widget cancelButton = TextButton(
                  child: const Text("CANCEL"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                );
                AlertDialog alert = AlertDialog(
                  title: const Text("Delete Account?"),
                  content: const Text(
                      "Are you sure you want to delete your account? This action is not reversible."),
                  actions: [
                    cancelButton,
                    yesButton,
                  ],
                );
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return alert;
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'DELETE ACCOUNT',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
