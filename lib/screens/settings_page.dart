import 'package:flutter/material.dart';
import 'package:lapboost_app/models/cart.dart';
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

  // List to store the fetched devices
  late List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _fetchDevices(); // Fetch devices when the screen is initialized
    // Initialize text controllers with current user values if needed
    _usernameController.text = widget.user['Social_Media_Handle'];
    _passwordController.text = widget.user['Password'];
    _addressController.text = widget.user['Address'] ?? '';
    _phoneController.text = widget.user['Mobile_Number'] ?? '';
  }

  // Fetch device data from the database
  Future<void> _fetchDevices() async {
    final conn = await SqlService.getConnection();

    try {
      // Query the 'devices' table (adjust the query as per your schema)
      var results = await conn.query(
          'SELECT * FROM devices WHERE Customer_ID = ?',
          [widget.user['Customer_ID']]);

      // Map the results into a list of maps for easier access
      setState(() {
        _devices = results.map((row) {
          return {
            'deviceSerial': row['Device_Serial_Number'],
            'deviceType': row['Device_Type'],
            'deviceName':
                row['Device_Manufacturer'] + ' ' + row['Device_Model'],
          };
        }).toList();
      });
    } catch (e) {
      // Handle database fetch error
      print('Error fetching devices: $e');
    }
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

          // Section 2: Devices
          Text(
            'Your Devices',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return fillDeviceDialog(context); // Show the dialog
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: const Icon(
                  Icons.add,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List of devices or no devices message
          _devices.isEmpty
              ? Container()
              : ListView.builder(
                  shrinkWrap: true, // To avoid overflow error
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable scrolling
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      title: Text(device['deviceName']),
                      subtitle: Text('Type: ${device['deviceType']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              print('Edit clicked');
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return fillDeviceDialog(context,
                                      device:
                                          device); // Show the dialog for adding
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              AlertDialog alert = AlertDialog(
                                title: const Text('Delete device?'),
                                content: const Text(
                                    'Are you sure you want this device deleted. This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                      onPressed: () async {
                                        print(device);
                                        _deleteDevice(device);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Device deleted successfully')));
                                        Navigator.of(context).pop();
                                        await _fetchDevices();
                                      },
                                      child: const Text('Yes')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('No')),
                                ],
                              );
                              showDialog(
                                  context: context,
                                  builder: (context) => alert);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
          const Divider(),

          // Section 3: Account Settings
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
                    final cartInstance = Cart();
                    cartInstance.clearCart();
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
                    conn.query(
                        '''DELETE FROM customers WHERE Customer_ID= ? ''',
                        [widget.user['Customer_ID']]);
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

  Widget fillDeviceDialog(BuildContext context,
      {Map<String, dynamic>? device}) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final deviceManufacturerController = TextEditingController();
    final deviceModelController = TextEditingController();
    final deviceTypeController = TextEditingController();

    // Available device types for the dropdown menu
    List<String> deviceTypes = ['Laptop', 'PC', 'Other'];
    String? selectedDeviceType;

    // If the device is passed (i.e., we're updating), pre-fill the fields
    if (device != null) {
      deviceManufacturerController.text =
          device['deviceName']?.split(' ').first ?? '';
      deviceModelController.text = device['deviceName']?.split(' ').last ?? '';
      selectedDeviceType = device['deviceType'];
    }

    return AlertDialog(
      title: Text(
          device == null ? 'Fill Device Details' : 'Update Device Details'),
      content: Form(
        key: _formKey, // Attach form key for validation
        child: SizedBox(
          width: double.infinity,
          height: 250, // Adjust height as needed
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Manufacturer Field
              TextFormField(
                controller: deviceManufacturerController,
                decoration: const InputDecoration(
                  labelText: 'Manufacturer',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Manufacturer is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Model Field
              TextFormField(
                controller: deviceModelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Model is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Device Type Field
              DropdownButtonFormField<String>(
                value: selectedDeviceType,
                decoration: const InputDecoration(
                  labelText: 'Device Type',
                  border: OutlineInputBorder(),
                ),
                onChanged: (newValue) {
                  setState(() {
                    selectedDeviceType = newValue;
                  });
                },
                items: deviceTypes
                    .map((type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Device Type is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (device == null) {
                // Submit new device details to the database
                _addDeviceToDatabase(
                  deviceManufacturerController.text,
                  deviceModelController.text,
                  selectedDeviceType!,
                );
              } else {
                // Update existing device
                _updateDeviceInDatabase(
                  '${device['deviceSerial']}',
                  deviceManufacturerController.text,
                  deviceModelController.text,
                  selectedDeviceType!,
                );
              }
              Navigator.pop(context);
            }
          },
          child: Text(device == null ? 'Submit' : 'Update'),
        ),
      ],
    );
  }

  Future<void> _updateDeviceInDatabase(String deviceSerial, String manufacturer,
      String model, String type) async {
    final conn = await SqlService.getConnection();
    await conn.query(
      'UPDATE devices SET Device_Manufacturer = ?, Device_Model = ?, Device_Type = ? WHERE Device_Serial_Number = ?',
      [
        manufacturer,
        model,
        type,
        deviceSerial,
      ],
    );
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device updated successfully')));
    _fetchDevices();
  }

  // Method to insert the device into the database
  Future<void> _addDeviceToDatabase(
      String manufacturer, String model, String type) async {
    final conn = await SqlService.getConnection();
    await conn.query(
      'INSERT INTO devices (Customer_ID, Device_Manufacturer, Device_Model, Device_Type) VALUES (?, ?, ?, ?)',
      [
        widget.user['Customer_ID'],
        manufacturer,
        model,
        type,
      ],
    );
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device added successfully')));
    _fetchDevices();
  }

  Future<void> _deleteDevice(Map<String, dynamic> device) async {
    final conn = await SqlService.getConnection();
    await conn.query('''
    DELETE FROM devices
    WHERE Device_Serial_Number= ?
    ''', [device['deviceSerial']]);
  }
}
