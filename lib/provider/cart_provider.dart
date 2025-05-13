import 'package:flutter/material.dart';
import 'dart:developer' as developer show log;
import 'package:merchandiser_clone/model/cart_model.dart';
import 'package:merchandiser_clone/screens/marchandiser_screens/cart_details_screen.dart';

class CartProvider extends ChangeNotifier {
  List<CartDetailsItem> _itemList = [];
  List<CartDetailsItem> get items => _itemList;
  List<CartDetailsItem> get cartItems => _itemList;
  Item? cartItem;

  void addToCart(CartDetailsItem newList) {
    _itemList.add(newList);
    notifyListeners();
  }

  void setCartItem(Item newItem) {
    cartItem = newItem;
    notifyListeners();
  }

  int getCartQuantity() {
    int totalQuantity = 0;
    for (var item in _itemList) {
      totalQuantity += item.quantity;
    }
    return totalQuantity;
  }

  void updateItem(int index, CartDetailsItem item) {
    _itemList[index] = item;
    notifyListeners();
  }

  void removeFromCart(CartDetailsItem item) {
    _itemList.remove(item);
    notifyListeners();
  }

  // Add this method to clear the entire cart
  void clearCart() {
    _itemList.clear();
    notifyListeners();
  }

  // Add this method to get the total quantity of all products in the cart
  int getTotalProduct(CartDetailsItem product) {
    int totalProduct = 0;
    for (var product in _itemList) {
      totalProduct += product.quantity;
    }
    return totalProduct;
  }

  // Method to fetch all cart items by ID
  List<CartDetailsItem> getItemById(String itemId) {
    return _itemList.where((item) => item.itemId == itemId).toList();
  }

  // Modified method to get quantity against each UOM for a given itemId
  Map<dynamic, int> getQuantityByUomForItem(String itemId) {
    Map<dynamic, int> uomQuantities = {};
    final items =
        _itemList.where((item) => item.itemId.toString() == itemId).toList();

    for (var item in items) {
      if (uomQuantities.containsKey(item.uom)) {
        uomQuantities[item.uom] = uomQuantities[item.uom]! + item.quantity;
      } else {
        uomQuantities[item.uom] = item.quantity;
      }
    }

    developer.log('qty: ${items.length}');
    return uomQuantities;
  }

  void removeAllFromCart(List<CartDetailsItem> itemsToRemove) {
    _itemList.removeWhere((item) => itemsToRemove.contains(item));
    notifyListeners();
  }
}

// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:merchandiser_clone/model/cart_model.dart';
// import 'package:merchandiser_clone/screens/marchandiser_screens/cart_details_screen.dart';

// class CartProvider extends ChangeNotifier {
//   List<CartDetailsItem> _itemList = [];
//   List<CartDetailsItem> get items => _itemList;
//   Item? cartItem;

//   void addToCart(CartDetailsItem newList) {
//     _itemList.add(newList);
//     notifyListeners();
//   }

//   void setCartItem(Item newItem) {
//     cartItem = newItem;
//     notifyListeners();
//   }

//   int getCartQuantity() {
//     int totalQuantity = 0;
//     for (var item in _itemList) {
//       totalQuantity += item.quantity;
//     }
//     return totalQuantity;
//   }

//   void removeFromCart(CartDetailsItem item) {
//     _itemList.remove(item);
//     notifyListeners();
//   }

//   // Add this method to clear the entire cart
//   void clearCart() {
//     _itemList.clear();
//     notifyListeners();
//   }

//   // Add this method to get the total quantity of all products in the cart
//   int getTotalProduct(CartDetailsItem product) {
//     int totalProduct = 0;
//     for (var product in _itemList) {
//       totalProduct += product.quantity;
//     }
//     return totalProduct;
//   }

//   // New method to get quantity against each UOM for a given itemId

//   // Map<dynamic, int>
//   // Modified method to get quantity against each UOM for a given itemId as a formatted string
//   Map<dynamic, int> uomQuantities = {};
//   getQuantityByUomForItem(String itemId) {
//     uomQuantities.clear();
//     final items =
//         _itemList.where((item) => item.itemId.toString() == itemId).toList();

//     for (var item in items) {
//       if (uomQuantities.containsKey(item.uom)) {
//         uomQuantities[item.uom] = uomQuantities[item.uom]! + item.quantity;
//       } else {
//         uomQuantities[item.uom] = item.quantity;
//       }
//     }

//     log('qty: ${items.length}');

//     if (uomQuantities.isEmpty) {
//       return "No items found for itemId: $itemId";
//     }

//     // Format the output as a string
//     StringBuffer result = StringBuffer();
//     uomQuantities.forEach((uom, quantity) {
//       result.write('$uom/$quantity\n');
//     });
//     // notifyListeners();
//     return result.toString().trim();
//   }
// }
