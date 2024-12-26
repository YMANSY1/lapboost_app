import 'package:flutter/material.dart';
import 'package:lapboost_app/models/sql_service.dart';
import 'package:lapboost_app/screens/buy_item_screen.dart';
import 'package:mysql1/mysql1.dart';

class MarketplacePage extends StatefulWidget {
  ResultRow user;

  MarketplacePage({super.key, required this.user});
  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  late MySqlConnection conn;
  late List<ResultRow> inventory;
  List<String> categories = [
    'All',
    'Battery',
    'Charger',
    'Screen',
    'Keyboard',
    'Cooling System',
    'RAM',
    'Storage',
    'Motherboard',
    'Input Device',
    'Accessory',
    'Audio',
    'Structural',
    'Networking',
    'Graphics',
    'Lighting',
    'Tool',
  ];

  String? selectedCategory;
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getInventory();
  }

  Future<void> _getInventory() async {
    try {
      // Establish connection (adjust the connection details as needed)
      conn = await SqlService.getConnection();

      // Fetch services from the database
      var results = await conn.query('SELECT * FROM inventory');

      // Store results in the inventory list
      setState(() {
        inventory = results.toList();
        isLoading = false; // Set loading to false after data is fetched
      });
    } catch (e) {
      print('Error fetching services: $e');
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }

  // Filter inventory based on selected category and search query
  List<ResultRow> getFilteredInventory() {
    // Filter by search query
    var filteredInventory = inventory.where((item) {
      var partName = item['Part_Name']?.toLowerCase() ?? '';
      return partName.contains(searchQuery.toLowerCase());
    }).toList();

    // Further filter by selected category
    if (selectedCategory != null &&
        selectedCategory!.isNotEmpty &&
        selectedCategory != 'All') {
      filteredInventory = filteredInventory
          .where((item) => item['Category'] == selectedCategory)
          .toList();
    }

    return filteredInventory;
  }

  @override
  void dispose() {
    conn.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar and filter button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value; // Update search query
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Select Category'),
                        content: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCategory,
                          hint: const Text('Select a category'),
                          items: categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                            Navigator.pop(context); // Close the dialog
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // Display inventory items
        isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator while data is being fetched
            : Expanded(
                child: GridView.builder(
                  addAutomaticKeepAlives: false,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: getFilteredInventory().length,
                  itemBuilder: (context, index) {
                    var item = getFilteredInventory()[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => BuyItemScreen(
                                user: widget.user, chosenItem: item)));
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Image.network(
                                  item['image_link'] ??
                                      'https://via.placeholder.com/150',
                                  fit: BoxFit.contain,
                                  height: 100,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Part Name with flexible text handling
                              Expanded(
                                child: Text(
                                  item['Part_Name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow:
                                      TextOverflow.ellipsis, // Handle overflow
                                  maxLines: 2, // Limit the number of lines
                                ),
                              ),
                              Text(
                                'EGP ${item['Market_Price'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}
