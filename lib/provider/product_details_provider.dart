import 'package:flutter/material.dart';

class ProductDetailsProvider with ChangeNotifier {
  dynamic? _productId;
  dynamic? _productName;
  dynamic? _UOM;
  dynamic? _UOMId;
  dynamic? _Cost;
  dynamic? _ItemId;
  dynamic? _barcode;

  dynamic? get productId => _productId;
  dynamic? get productName => _productName;
  dynamic? get UOM => _UOM;
  dynamic? get UOMId => _UOMId;
  dynamic? get Cost => _Cost;
  dynamic? get ItemId => _ItemId;
  dynamic? get barcode => _barcode;

  setProductDetails(dynamic productId, dynamic productName, dynamic UOM,
      dynamic UOMId, dynamic Cost, dynamic ItemID, dynamic barcode) {
    _productId = productId;
    _productName = productName;
    _UOM = UOM;
    _UOMId = UOMId;
    _Cost = Cost;
    _ItemId = ItemID;
    _barcode = barcode;

    notifyListeners();
  }

  void updateCost(dynamic cost) {
    _Cost = cost;
    notifyListeners();
  }

  clearProductDetails() {
    _productId = null;
    _productName = null;
    _UOM = null;
    _ItemId = null;
    _UOMId = null;
    _Cost = null;
    _barcode = null;
    notifyListeners();
  }
}
