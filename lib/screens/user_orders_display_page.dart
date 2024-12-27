import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ensure you import this for date formatting.
import 'package:lapboost_app/models/sql_service.dart';
import 'package:mysql1/mysql1.dart';

class UserOrdersDisplayPage extends StatefulWidget {
  final ResultRow user;

  UserOrdersDisplayPage({super.key, required this.user});

  @override
  State<UserOrdersDisplayPage> createState() => _UserOrdersDisplayPageState();
}

class _UserOrdersDisplayPageState extends State<UserOrdersDisplayPage> {
  Future<List<Map<String, dynamic>>> _fetchOrdersAndDetails() async {
    final conn = await SqlService.getConnection();
    try {
      // Fetch all orders for the user
      final orders = await conn.query('''
        SELECT * FROM orders
        WHERE Customer_ID = ?
      ''', [widget.user['Customer_ID']]);

      List<Map<String, dynamic>> ordersWithDetails = [];

      // For each order, fetch its details
      for (var order in orders) {
        final orderDetails = await conn.query('''
          SELECT od.Order_ID, od.Order_Part_ID, od.Device_Serial_Number, 
                 op.Quantity, op.Part_ID, s.Service_Type, 
                 d.Device_Model, d.Device_Manufacturer,
                 stk.Part_Name
          FROM order_details od
          LEFT JOIN ordered_parts op ON od.Order_Part_ID = op.Order_Part_ID
          LEFT JOIN services s ON od.Service_ID = s.Service_ID
          LEFT JOIN devices d ON od.Device_Serial_Number = d.Device_Serial_Number
          LEFT JOIN stock stk ON op.Part_ID = stk.Part_ID
          LEFT JOIN orders ord ON ord.Order_ID= od.Order_ID
          WHERE od.Order_ID = ?
        ''', [order['Order_ID']]);

        ordersWithDetails.add({
          'order': order,
          'details': orderDetails
              .toList(), // Convert to a list for easier manipulation
        });
      }

      return ordersWithDetails;
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchOrdersAndDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index]['order'];
              final orderDetails = orders[index]['details'];

              // Map statuses to display names and colors
              final Map<String, dynamic> statusMapping = {
                'To Be Scheduled': {'label': 'Pending', 'color': Colors.orange},
                'Scheduled': {'label': 'Under Repair', 'color': Colors.blue},
                'Received': {'label': 'Delivered', 'color': Colors.green},
                'Lost': {'label': 'Lost', 'color': Colors.red},
              };

              final orderStatus = order['Order_Status'];
              final displayStatus = statusMapping[orderStatus] ??
                  {'label': orderStatus, 'color': Colors.grey};

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Card(
                  elevation: 8,
                  child: ExpansionTile(
                    title: Text(
                      'Order #${order['Order_ID']}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Received on ${DateFormat('MMMM dd, yyyy').format(order['Date_Received'])}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: displayStatus['color'],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Add spacing between the container and the text
                            Text(
                              displayStatus['label'],
                              style: TextStyle(
                                color: displayStatus[
                                    'color'], // Adjust text color for visibility
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    children: [
                      for (var detail in orderDetails)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: detail['Service_Type'] != null
                                ? const Icon(Icons.design_services,
                                    color: Colors.blue)
                                : const Icon(Icons.memory,
                                    color: Colors.orange),
                          ),
                          title: Text(
                            detail['Service_Type'] ?? '${detail['Part_Name']}',
                          ),
                          subtitle: Text(
                            detail['Service_Type'] != null
                                ? 'Device: ${detail['Device_Manufacturer']} ${detail['Device_Model']}, Serial No. ${detail['Device_Serial_Number']}'
                                : 'Part Name: ${detail['Part_Name']}, Quantity: ${detail['Quantity']}',
                          ),
                          trailing: Text(
                            detail['Service_Type'] != null ? 'Service' : 'Part',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${order['Total_Amount']} EGP',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: SizedBox(
                          height: 33,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              bool confirmCancel = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Cancelation'),
                                    content: const Text(
                                        'Are you sure you want to cancel this order? This action cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(
                                              false); // Return false when canceled
                                        },
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(
                                              true); // Return true when confirmed
                                        },
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmCancel == true) {
                                try {
                                  final conn = await SqlService.getConnection();

                                  // Begin a transaction
                                  await conn.query('START TRANSACTION');

                                  // Retrieve all parts associated with the order
                                  final parts = await conn.query('''
          SELECT op.Part_ID, op.Quantity
          FROM ordered_parts op
          JOIN order_details od ON op.Order_Part_ID = od.Order_Part_ID
          WHERE od.Order_ID = ?
        ''', [order['Order_ID']]);

                                  // Update stock quantities
                                  for (var part in parts) {
                                    await conn.query('''
            UPDATE stock
            SET Quantity_in_Stock = Quantity_in_Stock + ?
            WHERE Part_ID = ?
          ''', [part['Quantity'], part['Part_ID']]);
                                  }

                                  // Delete the order (cascades other entries automatically)
                                  await conn.query('''
          DELETE FROM orders
          WHERE Order_ID = ?
        ''', [order['Order_ID']]);

                                  // Commit the transaction
                                  await conn.query('COMMIT');

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Order canceled successfully!')),
                                  );

                                  setState(
                                      () {}); // Refresh UI after cancelation
                                } catch (e) {
                                  // Rollback in case of error
                                  final conn = await SqlService.getConnection();
                                  await conn.query('ROLLBACK');

                                  // Handle errors and notify the user
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Error canceling order: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              backgroundColor: const Color(0xffffa7b5),
                              side:
                                  const BorderSide(color: Colors.red, width: 1),
                            ),
                            child: const Text(
                              'CANCEL ORDER',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
