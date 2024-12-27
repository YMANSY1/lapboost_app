import 'package:mysql1/mysql1.dart';

class CartItem {
  final ResultRow? service;
  final ResultRow? item;
  int quantity;
  ResultRow? device;

  CartItem({
    this.service,
    this.item,
    required this.quantity,
    this.device,
  });

  double get totalPrice =>
      service?['Service_Cost'] ?? item?['Market_Price'] * quantity ?? 0.0;
}

class Cart {
  // Private static instance of Cart
  static final Cart _instance = Cart._internal();

  // Factory constructor to return the same instance
  factory Cart() {
    return _instance;
  }

  // Private named constructor
  Cart._internal();

  // Cart items list
  static List<CartItem> cartItems = [];

  // Add item to the cart
  void addItem(CartItem item) => cartItems.add(item);

  // Get the total amount of the cart
  double getTotalAmount(bool isDelivery) {
    double total = 0.0;
    for (var item in cartItems) {
      total += item.totalPrice;
    }
    return isDelivery ? total + 30 : total;
  }

  // Getter for cart length
  int get cartLength => cartItems.length;

  // Optionally, you can add a method to clear the cart
  void clearCart() {
    cartItems.clear();
    print(cartItems);
  }
}
