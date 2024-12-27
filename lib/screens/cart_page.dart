import 'package:flutter/material.dart';
import 'package:lapboost_app/models/cart.dart';
import 'package:lapboost_app/models/sql_service.dart';
import 'package:lapboost_app/screens/checkout_page.dart';
import 'package:mysql1/mysql1.dart';

class CartPage extends StatefulWidget {
  ResultRow user;
  CartPage({super.key, required this.user});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cartInstance = Cart();
  late Results devices; // Initialize with empty Results
  bool isLoading = true; // Loading state

  double calculateTotal() {
    double total = 0;
    for (var cartItem in Cart.cartItems) {
      if (cartItem.item != null) {
        total += cartItem.item!['Market_Price'] * cartItem.quantity;
      } else if (cartItem.service != null) {
        total += cartItem.service!['Service_Cost'] * cartItem.quantity;
      }
    }
    return total;
  }

  Future<void> _fetchDevices() async {
    final conn = await SqlService.getConnection();
    final results = await conn.query(
        'SELECT * FROM devices WHERE Customer_ID= ?',
        [widget.user['Customer_ID']]);
    devices = results;
    setState(() {
      isLoading = false; // Mark loading as complete
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  @override
  Widget build(BuildContext context) {
    final isCartEmpty = Cart.cartItems.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          IconButton(
            onPressed: () {
              cartInstance.clearCart();
              setState(() {});
            },
            icon: const Icon(
              Icons.delete_forever,
              size: 30,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader
          : isCartEmpty
              ? const Center(
                  child: Text(
                    'Cart is empty',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartInstance.cartLength,
                        itemBuilder: (BuildContext context, int index) {
                          var cartItem = Cart.cartItems[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Display the service or item name
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cartItem.service != null
                                              ? cartItem
                                                  .service!['Service_Type']
                                              : cartItem.item!['Part_Name'],
                                          style: const TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${cartItem.service != null ? cartItem.service!['Service_Cost'] : cartItem.item!['Market_Price']} EGP',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // If it's a service, show a Dropdown for device selection
                                  if (cartItem.service != null)
                                    DropdownButton<ResultRow>(
                                      value: cartItem.device != null
                                          ? devices.firstWhere(
                                              (device) =>
                                                  device[
                                                      'Device_Serial_Number'] ==
                                                  cartItem.device?[
                                                      'Device_Serial_Number'],
                                              orElse: () => devices.first,
                                            )
                                          : null, // If no device is selected, set value to null
                                      hint: const Text('Select Device'),
                                      onChanged: (newDevice) {
                                        setState(() {
                                          cartItem.device = newDevice;
                                        });
                                      },
                                      items: devices
                                          .map<DropdownMenuItem<ResultRow>>(
                                              (deviceRow) {
                                        return DropdownMenuItem<ResultRow>(
                                          value:
                                              deviceRow, // Assign the device row directly
                                          child: Text(
                                            '${deviceRow['Device_Serial_Number']}- ${deviceRow['Device_Model']}',
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                  // If it's a device, show a quantity counter
                                  if (cartItem.item != null)
                                    Row(
                                      children: [
                                        // Minus button
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: cartItem.quantity > 1
                                              ? () {
                                                  setState(() {
                                                    cartItem.quantity--;
                                                  });
                                                }
                                              : null, // Disable if quantity is 1
                                        ),
                                        Text(
                                          '${cartItem.quantity}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        // Add button
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: cartItem.quantity <
                                                  cartItem.item![
                                                      'Quantity_in_Stock'] // Enable if less than stock
                                              ? () {
                                                  setState(() {
                                                    cartItem.quantity++;
                                                  });
                                                }
                                              : null, // Disable if quantity reaches stock limit
                                        ),
                                      ],
                                    ),
                                  // Delete icon
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        Cart.cartItems.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            for (var cartItem in Cart.cartItems) {
                              print(cartItem.device);
                              if (cartItem.device == null &&
                                  cartItem.service != null) {
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(const SnackBar(
                                      content: Text(
                                          'Please specify a device for all services in the cart')));

                                return;
                              }
                            }

                            // If no issues found, navigate to the checkout page once
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => CheckoutPage(
                                        user: widget.user,
                                      )),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Go to Checkout',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${calculateTotal()} EGP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
