import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lapboost_app/models/sql_service.dart';
import 'package:mysql1/mysql1.dart';

class OrderCard extends StatelessWidget {
  final ResultRow order, orderService;
  final Map<String, dynamic>? orderParts;
  String? imageLink, name;
  VoidCallback cancelOnPressed;
  OrderCard(
      {super.key,
      required this.order,
      required this.orderService,
      this.orderParts,
      this.name,
      this.imageLink,
      required this.cancelOnPressed});

  Future<ResultRow> getOrderService() async {
    final conn = await SqlService.getConnection();
    final result = await conn.query('''
    SELECT * FROM services
    WHERE Service_ID= ${order['Service_ID']}
    ''');
    return result.first;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Card(
        color: Colors.white,
        elevation: 16,
        child: Theme(
          data: Theme.of(context).copyWith(
            listTileTheme:
                ListTileTheme.of(context).copyWith(minVerticalPadding: 30),
          ),
          child: ExpansionTile(
            title: Text(name ?? orderService['Service_Type']),
            leading: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(imageLink ?? ''),
            ),
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Date:',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                        Text(
                          dateFormat.format(order['Date_Received']),
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        )
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Device:',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                        Text(
                          "Laptop",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Status:',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                        Text(
                          order['Order_Status'],
                          style: const TextStyle(
                            fontSize: 20,
                          ),
                        )
                      ],
                    ),
                  ),
                  orderService['Service_ID'] == 19
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Quantity:',
                                style: TextStyle(
                                    fontSize: 20, color: Colors.black),
                              ),
                              Text(
                                '${orderParts?['Quantity']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              )
                            ],
                          ),
                        )
                      : Container(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Price:',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        Text(
                          '${order['Total_Amount']} EGP',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
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
                        onPressed: cancelOnPressed,
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            backgroundColor: const Color(0xffffa7b5),
                            side:
                                const BorderSide(color: Colors.red, width: 2)),
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
            ],
          ),
        ),
      ),
    );
  }
}
