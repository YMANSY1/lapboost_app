import 'package:flutter/material.dart';
import 'package:lapboost_app/screens/new_order_page.dart';
import 'package:mysql1/src/results/row.dart';

class HomePage extends StatelessWidget {
  ResultRow user;
  HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Get started making a new order',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                print(user);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => NewOrderPage(user: user)));
              },
              splashColor: Colors.blue.withOpacity(0.3), // Wave effect color
              borderRadius: BorderRadius.circular(8.0),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Request a service',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => NewOrderPage(user: user)));
                        },
                        icon: const Icon(
                          Icons.add,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
