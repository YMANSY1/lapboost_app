import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lapboost_app/models/sql_service.dart';
import 'package:mysql1/mysql1.dart';

class BuyItemScreen extends StatefulWidget {
  ResultRow user, chosenItem;

  BuyItemScreen({super.key, required this.user, required this.chosenItem});

  @override
  State<BuyItemScreen> createState() => _BuyItemScreenState();
}

class _BuyItemScreenState extends State<BuyItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final quantity = 1.obs;

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

      // Insert order into the database and get the Order_ID
      var result = await conn.query('''
      INSERT INTO orders (Customer_ID, Date_Received, Order_Status, Service_ID, Total_Amount, Delivery_Required)
      VALUES (?, ?, ?, ?, ?, ?)
    ''', [
        widget.user['Customer_ID'],
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'Received',
        19,
        widget.chosenItem['Market_Price'] * quantity.value + 30,
        1
      ]);
      print(result.insertId ?? 'empty');
      // Get the Order_ID (the last inserted ID)
      int orderId = result.insertId ?? 0;

      // Now update inventory
      await conn.query('''
      UPDATE inventory
      SET Quantity_in_Stock = ?
      WHERE Part_ID = ?
    ''', [
        widget.chosenItem['Quantity_in_Stock'] - quantity.value,
        widget.chosenItem['Part_ID']
      ]);

      // Insert into order_parts table
      await conn.query('''
      INSERT INTO order_parts (Order_ID, Part_ID, Quantity, Price_at_Order_Time)
      VALUES (?,?,?,?)
    ''', [
        orderId, // Use the Order_ID here
        widget.chosenItem['Part_ID'],
        quantity.value,
        widget.chosenItem['Market_Price'] * quantity.value + 30,
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
        title: const Text('Buy Item'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  child: Image.network(
                    widget.chosenItem['image_link'],
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
                      '${widget.chosenItem['Part_Name']} - ${widget.chosenItem['Quantity_in_Stock']} in Stock',
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

            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Item Price:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Obx(() {
                    return Text(
                      '${widget.chosenItem['Market_Price'] * quantity.value} EGP',
                      style: TextStyle(fontSize: 16),
                    );
                  })
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(left: 16.0, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delivery Price:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '30.0 EGP',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Price:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Obx(() {
                    return Text(
                      '${widget.chosenItem['Market_Price'] * quantity.value + 30 ?? 0.0} EGP',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Replace the Confirm Button section with the following Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quantity Counter UI
                  Container(
                    width: MediaQuery.of(context).size.width / 2 -
                        24, // Half of the screen width with padding
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() {
                          return IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: quantity.value >
                                    1 // Enable only if quantity is greater than 1
                                ? () {
                                    quantity.value--;
                                  }
                                : null,
                          );
                        }),
                        Obx(() {
                          return Text(
                            '${quantity.value}',
                            // Display the current quantity value
                            style: const TextStyle(fontSize: 16),
                          );
                        }),
                        Obx(() {
                          return IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: quantity.value <
                                    widget.chosenItem[
                                        'Quantity_in_Stock'] // Enable only if quantity is greater than 1
                                ? () {
                                    quantity.value++;
                                  }
                                : null,
                          );
                        }),
                      ],
                    ),
                  ),

                  // Confirm Button
                  Container(
                    width: MediaQuery.of(context).size.width / 2 -
                        24, // Half of the screen width with padding
                    child: ElevatedButton(
                      onPressed: _confirmOrder,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
