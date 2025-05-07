import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:merchandiser_clone/provider/create_request_vendor_detals.dart';
import 'package:merchandiser_clone/screens/model/Vendors.dart';
import 'package:merchandiser_clone/screens/model/vendor_and_salesperson_model.dart';
import 'package:merchandiser_clone/screens/salesman_screens/model/merchendiser_api_service.dart';
import 'package:provider/provider.dart';

/// Provider to manage product details, vendor selection, and salesperson logic.
class ProductDetailsProvider with ChangeNotifier {
  // Product-related properties
  dynamic _productId;
  dynamic _productName;
  dynamic _UOM;
  dynamic _UOMId;
  dynamic _Cost;
  dynamic _ItemId;
  dynamic _barcode;
  double _uomcost = 0.00;
  // Getters for product details
  dynamic get productId => _productId;
  dynamic get productName => _productName;
  dynamic get UOM => _UOM;
  dynamic get UOMId => _UOMId;
  dynamic get Cost => _Cost;
  dynamic get ItemId => _ItemId;
  dynamic get barcode => _barcode;
  double get uomcost => _uomcost;

  /// Set product details and notify listeners
  void setProductDetails(
      dynamic productId,
      dynamic productName,
      dynamic UOM,
      dynamic UOMId,
      dynamic Cost,
      dynamic ItemID,
      dynamic barcode,
      dynamic uomCost) {
    _productId = productId;
    _productName = productName;
    _UOM = UOM;
    _UOMId = UOMId;
    _Cost = Cost;
    _ItemId = ItemID;
    _barcode = barcode;
    // _uomcost = uomCost??0.00;

    notifyListeners();
  }

  /// Update only the cost of the product
  void updateCost(dynamic cost) {
    _uomcost = cost;
    notifyListeners();
  }

  /// Clear all stored product details
  void clearProductDetails() {
    _productId = null;
    _productName = null;
    _UOM = null;
    _ItemId = null;
    _UOMId = null;
    _Cost = null;
    _barcode = null;
    _salesPriceList = [];
    notifyListeners();
  }

  // -------------------------------------
  // ✅ Last Sales Price Handling
  // -------------------------------------

  List<Map<String, dynamic>> _salesPriceList = [];
  List<Map<String, dynamic>> get salesPriceList => _salesPriceList;

  void setSalesPriceList(List<Map<String, dynamic>> list) {
    _salesPriceList = list;
    notifyListeners();
  }

  void updateCostByUom(dynamic selectedUomId) {
    final match = _salesPriceList.firstWhere(
      (item) => item['uomId'] == selectedUomId,
      orElse: () => {},
    );
    if (match.isNotEmpty) {
      _Cost = match['uomCost'] ?? 0;
      notifyListeners();
    }
  }

  fetchcostbyUom(String selectedUomId) {
    final match = _salesPriceList.firstWhere(
      (item) => item['uomId'] == int.parse(selectedUomId.toString()),
      orElse: () => {},
    );
    if (match.isNotEmpty) {
      _uomcost = match['uomCost'] ?? 0;
      notifyListeners();
    }
    log("id:$selectedUomId UOM Cost: $_uomcost");
  }
  // -------------------------------------
  // ✅ Vendor and Salesperson selection
  // -------------------------------------

  Vendors? _selectedVendor;
  SalesPerson? _selectedSalesPerson;

  Vendors? get selectedVendor => _selectedVendor;
  SalesPerson? get selectedSalesPerson => _selectedSalesPerson;

  final MerchendiserApiService salesmanapiService = MerchendiserApiService();
  final MerchendiserApiService vendorapiService = MerchendiserApiService();

  List<SalesPerson> allSalesPersons = [];
  List<SalesPerson> _filteredSalesPersons = [];

  String selectedCustomer = "";
  String selectedSalesManName = "";
  int? selectedSalesPersonId;
  bool _isExpanded = false;

  List<Vendors> vendorList = [];
  late Future<VendorAndSalesPersonModel> vendorData;
  Future<VendorAndSalesPersonModel>? salesmanData;

  bool isLoading = false;
  int currentPage = 1;
  final int pageSize = 20;

  void setSelectedVendor(Vendors vendor, BuildContext context) {
    _selectedVendor = vendor;
    log("Vendor selected: ${vendor.vendorName}");
    notifyListeners();
  }

  void setSelectedSalesPerson(SalesPerson person) {
    _selectedSalesPerson = person;
    notifyListeners();
  }

  Future<void> fetchVendors({String query = '', int page = 1}) async {
    if (isLoading) return;

    _setLoading(true);

    try {
      final newVendors = await vendorapiService.fetchVendors(
        query: query,
        page: page,
        pageSize: pageSize,
      );

      _setLoading(false);

      if (page == 1) {
        vendorList = newVendors;
      } else {
        vendorList.addAll(newVendors);
      }
      currentPage = page;
      notifyListeners();
    } catch (error) {
      _setLoading(false);
      debugPrint("Error fetching vendors: $error");
    }
  }

  Future<void> fetchSalesmanData(int? vendorID, BuildContext context) async {
    try {
      final data =
          await salesmanapiService.getVendorAndSalesPersonData(vendorID);

      if (data != null && data.data.salesPersons.isNotEmpty) {
        allSalesPersons = data.data.salesPersons;
        _filteredSalesPersons = allSalesPersons;

        final vendorDetailsProvider =
            Provider.of<CreateRequestVendorDetailsProvider>(context,
                listen: false);

        selectedSalesManName = vendorDetailsProvider.salesPersonName ??
            allSalesPersons.first.salesPersonName;

        selectedSalesPersonId = vendorDetailsProvider.salesPerson ??
            allSalesPersons.first.salesPerson;

        _selectedSalesPerson = allSalesPersons.first;

        setSelectedSalesPerson(_selectedSalesPerson!);

        selectedCustomer = selectedSalesManName;

        log('Selected Salesperson: ${_selectedSalesPerson!.salesPersonName}');
        notifyListeners();
      } else {
        log('No salespersons found for vendor $vendorID.');
      }
    } catch (e) {
      debugPrint("Error fetching salesman data: $e");
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
