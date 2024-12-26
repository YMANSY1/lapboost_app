import 'package:flutter/material.dart';
import 'package:lapboost_app/models/sql_service.dart';
import 'package:lapboost_app/screens/make_order_page.dart';
import 'package:mysql1/mysql1.dart';

class NewOrderPage extends StatefulWidget {
  final ResultRow user;

  NewOrderPage({super.key, required this.user});

  @override
  State<NewOrderPage> createState() => NewOrderPageState();
}

class NewOrderPageState extends State<NewOrderPage> {
  late MySqlConnection conn;
  late List<ResultRow> services;
  bool isLoading = true; // Add a flag to track the loading state

  @override
  void initState() {
    super.initState();
    _getServices();
  }

  Future<void> _getServices() async {
    try {
      // Establish connection (adjust the connection details as needed)
      conn = await SqlService.getConnection();

      // Fetch services from the database
      var results = await conn.query('SELECT * FROM services');

      // Store results in the services list
      setState(() {
        services = results.toList();
        isLoading = false; // Set loading to false after data is fetched
      });
    } catch (e) {
      print('Error fetching services: $e');
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }

  @override
  void dispose() {
    conn.close(); // Don't forget to close the connection when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick the service you need'),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading spinner until data is fetched
          : services.isEmpty
              ? const Center(
                  child: Text(
                      'No services found.')) // Show message if no services are found
              : ListView.builder(
                  addAutomaticKeepAlives: false,
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    var service = services[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MakeOrderPage(
                                user: widget.user, service: service)));
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 4.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Placeholder image on the left
                              Container(
                                width: 60.0,
                                height: 60.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(12.0),
                                  image: DecorationImage(
                                    image: NetworkImage(service['image_link'] ??
                                        'https://via.placeholder.com/150'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              // Name of the service
                              Expanded(
                                child: Text(
                                  service['Service_Type'],
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              // Price to the far right, colored green
                              Text(
                                '${service['Service_Cost'].toString()} EGP',
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
