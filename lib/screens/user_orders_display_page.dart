import 'package:flutter/material.dart';
import 'package:lapboost_app/models/sql_service.dart';
import 'package:lapboost_app/widgets/user_orders_card.dart';
import 'package:mysql1/mysql1.dart';

class UserOrdersDisplayPage extends StatefulWidget {
  final ResultRow user;

  const UserOrdersDisplayPage({Key? key, required this.user}) : super(key: key);

  @override
  State<UserOrdersDisplayPage> createState() => _UserOrdersDisplayPageState();
}

class _UserOrdersDisplayPageState extends State<UserOrdersDisplayPage> {
  late Future<List<Map<String, dynamic>>> userOrdersWithServices;

  @override
  void initState() {
    super.initState();
    userOrdersWithServices = fetchUserOrdersWithServicesAndParts();
  }

  Future<void> cancelOrder(ResultRow order) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cancel Order?"),
          content: const Text(
            "Are you sure you want to cancel this order? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("YES"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      try {
        final conn = await SqlService.getConnection();
        final int? orderQuantity;
        final ResultRow? orderPart;

        if (order['Service_ID'] == 19) {
          // Fetch the parts associated with the order
          final res = await conn.query('''
          SELECT * FROM order_parts
          WHERE Order_ID= ?
        ''', [order['Order_ID']]);

          if (res.isNotEmpty) {
            orderPart = res.first;
            orderQuantity = orderPart['Quantity'];

            // Delete the parts associated with the order
            await conn.query('''
            DELETE FROM order_parts
            WHERE Order_ID=?
          ''', [order['Order_ID']]);

            // Update inventory by adding back the quantity
            await conn.query('''
            UPDATE inventory
            SET Quantity_in_Stock=Quantity_in_Stock + ?
            WHERE Part_ID= ?
          ''', [orderQuantity, orderPart['Part_ID']]);
          }
        }

        // Delete the order
        await conn.query('''
        DELETE FROM orders
        WHERE Order_ID = ?
      ''', [order['Order_ID']]);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );

        // Refresh the data
        setState(() {
          userOrdersWithServices = fetchUserOrdersWithServicesAndParts();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>>
      fetchUserOrdersWithServicesAndParts() async {
    try {
      final conn = await SqlService.getConnection();

      // Fetch all orders for the user
      final orders = await conn.query(
        '''
      SELECT * FROM orders
      WHERE Customer_ID = ?
      ''',
        [widget.user['Customer_ID']],
      );

      // Fetch services, parts, and inventory images for the orders
      List<Map<String, dynamic>> ordersWithServicesAndParts = [];
      for (var order in orders) {
        // Fetch the associated service
        final serviceResult = await conn.query(
          '''
        SELECT * FROM services
        WHERE Service_ID = ?
        ''',
          [order['Service_ID']],
        );

        // Determine the service image link, if available
        String? serviceImageLink;
        if (serviceResult.isNotEmpty) {
          serviceImageLink = serviceResult.first['image_link'];
        }

        print(order['Order_ID']);

        // Fetch the associated parts
        final partsResult = await conn.query(
          '''
        SELECT * FROM order_parts
        WHERE Order_ID = ?
        ''',
          [order['Order_ID']],
        );

        // Fetch inventory details including Part_Name and image links if parts exist
        List<Map<String, dynamic>> parts = [];
        String? inventoryImageLink;
        List<String> partNames = [];
        if (partsResult.isNotEmpty) {
          for (var part in partsResult) {
            parts.add(part.fields);

            // Fetch the image link and Part_Name for each part from the inventory
            final inventoryResult = await conn.query(
              '''
            SELECT Part_Name, image_link FROM inventory
            WHERE Part_ID = ?
            ''',
              [part['Part_ID']],
            );

            if (inventoryResult.isNotEmpty) {
              partNames.add(inventoryResult.first['Part_Name'] as String);
              inventoryImageLink =
                  inventoryResult.first['image_link'] as String?;
            }
          }
        }

        // Aggregate part names into a single string
        String? partNamesString =
            partNames.isNotEmpty ? partNames.join(' ') : null;

        // Use the service image link if available, otherwise use the inventory image link
        String? finalImageLink = serviceImageLink ?? inventoryImageLink;

        // Add the order, service, parts, final image link, and part names to the result list
        ordersWithServicesAndParts.add({
          'order': order,
          'service': serviceResult.isNotEmpty ? serviceResult.first : null,
          'parts': partsResult.isNotEmpty ? partsResult.first.fields : null,
          'imageLink': finalImageLink,
          'partNames': partNamesString,
        });
      }

      return ordersWithServicesAndParts;
    } catch (e) {
      print('Error fetching user orders with services and parts: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: userOrdersWithServices,
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          final ordersWithServicesAndParts = snapshot.data!;
          return ListView.builder(
            itemCount: ordersWithServicesAndParts.length,
            itemBuilder: (BuildContext context, int index) {
              final orderData = ordersWithServicesAndParts[index];
              // final orderParts = orderData['parts'];
              return OrderCard(
                order: orderData['order'],
                orderService: orderData['service'],
                orderParts: orderData['parts'],
                imageLink: orderData['imageLink'],
                name: orderData['partNames'],
                cancelOnPressed: () => cancelOrder(orderData['order']),
              );
            },
          );
        },
      ),
    );
  }
}
