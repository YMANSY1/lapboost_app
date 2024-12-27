import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lapboost_app/models/cart.dart';
import 'package:lapboost_app/models/sql_service.dart';
import 'package:lapboost_app/screens/main_page.dart';
import 'package:mysql1/mysql1.dart';

class CheckoutPage extends StatefulWidget {
  ResultRow user;

  CheckoutPage({
    super.key,
    required this.user,
  });

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Track the value of the Switch
  final isDelivery = false.obs;
  final addressController = TextEditingController();

  // Function to handle the change in Switch state
  void onChanged(bool newValue) {
    setState(() {
      addressController.text = widget.user['Address'] ?? '';
      isDelivery.value = newValue;
    });
  }

  // Function to calculate total price
  double calculateTotalPrice() {
    double totalPrice = 0;

    // Calculate price of cart items
    for (var item in Cart.cartItems) {
      final isService = item.service != null;
      totalPrice += isService
          ? item.service!['Service_Cost'] as double
          : item.item!['Market_Price'] * item.quantity as double;
    }

    // Add delivery price if applicable
    if (isDelivery.value) {
      totalPrice += 30.0; // Assuming delivery cost is 30.0 EGP
    }

    return totalPrice;
  }

  @override
  void initState() {
    addressController.text = widget.user['Address'] ?? '';
    super.initState();
  }

  Future<void> _confirmOrder() async {
    final conn = await SqlService.getConnection();
    try {
      // Update customer's address if delivery is required
      if (isDelivery.value &&
          addressController.text != widget.user['Address']) {
        await conn.query('''
        UPDATE customers
        SET Address = ?
        WHERE Customer_ID = ?
      ''', [
          addressController.text,
          widget.user['Customer_ID'],
        ]);
      }

      // Insert the new order
      final orderResult = await conn.query('''
      INSERT INTO orders (Customer_ID, Date_Received, Order_Status, Total_Amount, Delivery_Required)
      VALUES (?, ?, ?, ?, ?)
    ''', [
        widget.user['Customer_ID'],
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'To Be Scheduled',
        calculateTotalPrice(),
        isDelivery.value ? 1 : 0
      ]);

      // Get the Order_ID (the last inserted ID)
      int orderId = orderResult.insertId ?? 0;
      print('Inserted Order ID: $orderId');

      // Loop through the cart items and handle services and parts
      for (var receiptItem in Cart.cartItems) {
        if (receiptItem.service != null) {
          // Inserting service into order_details
          await conn.query('''
          INSERT INTO order_details (Order_ID, Service_ID, Device_Serial_Number)
          VALUES (?, ?, ?)
        ''', [
            orderId,
            receiptItem.service!['Service_ID'],
            receiptItem.device!['Device_Serial_Number'],
          ]);
        } else {
          // Update stock quantities
          await conn.query('''
          UPDATE stock
          SET Quantity_in_Stock = ?
          WHERE Part_ID = ?
        ''', [
            receiptItem.item!['Quantity_in_Stock'] - receiptItem.quantity,
            receiptItem.item!['Part_ID'],
          ]);

          // Insert into ordered_parts table
          final orderPartResult = await conn.query('''
          INSERT INTO ordered_parts (Order_ID, Part_ID, Quantity)
          VALUES (?, ?, ?)
        ''', [
            orderId, // Use the Order_ID here
            receiptItem.item!['Part_ID'],
            receiptItem.quantity,
          ]);

          // Get the Order_Part_ID (the last inserted ID)
          int orderPartId = orderPartResult.insertId ?? 0;
          print('Inserted Order Part ID: $orderPartId');

          // Insert into order_details
          await conn.query('''
          INSERT INTO order_details (Order_ID, Order_Part_ID)
          VALUES (?, ?)
        ''', [
            orderId,
            orderPartId,
          ]);
        }
      }
    } catch (e) {
      print('Error during order confirmation: $e');
      // Handle error gracefully (e.g., show an error message to the user)
    } finally {
      // Make sure to close the database connection after operations
      await conn.close();
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Order Complete!')));
    Cart().clearCart();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainPage(user: widget.user)),
        (a) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cartInstance = Cart();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Receipt',
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const Divider(),
            SizedBox(
              height: 320,
              child: Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  // Ensures the ListView takes up only as much space as needed
                  itemCount: cartInstance.cartLength * 2,
                  // Add 1 for each divider
                  itemBuilder: (BuildContext context, int index) {
                    if (index.isOdd) {
                      // Display divider for every odd index
                      return const Divider();
                    } else {
                      final realIndex = index ~/ 2; // Get the real item index
                      final receiptItem = Cart.cartItems[realIndex];
                      final isService = receiptItem.service != null;
                      return ListTile(
                        title: Text(isService
                            ? receiptItem.service!['Service_Type']
                            : receiptItem.item!['Part_Name']),
                        subtitle: Text(isService
                            ? 'Device: ${receiptItem.device!['Device_Manufacturer']} ${receiptItem.device!['Device_Model']}, ${receiptItem.device!['Device_Type']}'
                            : 'Quantity: ${receiptItem.quantity}'),
                        trailing: Text(
                          'EGP ${isService ? receiptItem.service!['Service_Cost'] : receiptItem.item!['Market_Price'] * receiptItem.quantity}',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 16),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(
                height: 16), // Add some space between the list and the text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Do You Want This Order Delivered',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isDelivery.value,
                    onChanged: onChanged,
                    activeColor: Colors.green,
                    // Active state color
                    inactiveThumbColor: Colors.white,
                    // Inactive thumb color
                    inactiveTrackColor: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              return TextFormField(
                enabled: isDelivery.value,
                controller: addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Address',
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items Price:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${calculateTotalPrice() - (isDelivery.value ? 30.0 : 0.0)} EGP',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            isDelivery.value
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery Price:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '30.0 EGP',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : Container(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Price:',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                Obx(() {
                  return Text(
                    '${calculateTotalPrice()} EGP',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
