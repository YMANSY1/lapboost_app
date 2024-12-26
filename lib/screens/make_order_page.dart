import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lapboost_app/models/sql_service.dart';
import 'package:mysql1/mysql1.dart';

class MakeOrderPage extends StatefulWidget {
  final ResultRow user, service;
  MakeOrderPage({super.key, required this.user, required this.service});

  @override
  State<MakeOrderPage> createState() => _MakeOrderPageState();
}

class _MakeOrderPageState extends State<MakeOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.user['Customer_Name'];
    addressController.text = widget.user['Address'] ?? '';
    emailController.text = widget.user['Email'] ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    if (_formKey.currentState!.validate()) {
      final conn = await SqlService.getConnection();

      // Check if address has been changed and update it
      if (addressController.text != widget.user['Address']) {
        await conn.query('''
          UPDATE customers
          SET Address = ?
          WHERE Customer_ID = ?
        ''', [addressController.text, widget.user['Customer_ID']]);
      }

      // Insert order into the database
      await conn.query('''
        INSERT INTO orders (Customer_ID, Date_Received, Order_Status, Service_ID, Total_Amount,Delivery_Required)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        widget.user['Customer_ID'],
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'Received',
        widget.service['Service_ID'],
        widget.service['Service_Cost'],
        1
      ]);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order successfully sent!')));

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Your Order'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Service Image and Type
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  child: Image.network(
                    widget.service['image_link'],
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 8.0,
                  left: 8.0,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      widget.service['Service_Type'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name Field (Read-Only)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: TextFormField(
                controller: nameController,
                enabled: false, // Disabled instead of IgnorePointer
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email Field (Read-Only)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: TextFormField(
                controller: emailController,
                enabled: false, // Disabled instead of IgnorePointer
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address Field
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Address',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please fill in an address';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Total Price Row
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Price:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.service['Service_Cost'] ?? 0.0} EGP',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Button
            ElevatedButton(
              onPressed: _confirmOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
