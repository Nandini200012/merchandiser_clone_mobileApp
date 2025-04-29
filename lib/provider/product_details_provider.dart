import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:merchandiser_clone/provider/create_request_vendor_detals.dart';
import 'package:merchandiser_clone/screens/model/Vendors.dart';
import 'package:merchandiser_clone/screens/model/vendor_and_salesperson_model.dart';
import 'package:merchandiser_clone/screens/salesman_screens/model/merchendiser_api_service.dart';
import 'package:provider/provider.dart';

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

  // selected vendor and salesman
  Vendors? _selectedVendor;
  SalesPerson? _selectedSalesPerson;

  Vendors? get selectedVendor => _selectedVendor;
  SalesPerson? get selectedSalesPerson => _selectedSalesPerson;
  final MerchendiserApiService salesmanapiService = MerchendiserApiService();
  List<SalesPerson> allSalesPersons = [];
  List<SalesPerson> _filteredSalesPersons = [];
  String selectedCustomer = "";
  bool _isExpanded = false;
  String selectedSalesManName = "";
  int? selectedSalesPersonId;
  Future<VendorAndSalesPersonModel>? salesmanData;
  void setSelectedVendor(Vendors vendor, BuildContext context) {
    _selectedVendor = vendor;
    log("vendor--->..");
    // fetchSalesmanData(_selectedVendor!.vendorId, context);
    notifyListeners();
  }

  void setSelectedSalesPerson(SalesPerson person) {
    _selectedSalesPerson = person;
    notifyListeners();
  }

  Future<void> fetchSalesmanData(int? vendorID, BuildContext context) async {
    try {
      // Show a loading indicator while the data is being fetched
      // (Consider using a loading state in your UI or an appropriate state management solution)
      final data =
          await salesmanapiService.getVendorAndSalesPersonData(vendorID);

      if (data != null && data.data.salesPersons.isNotEmpty) {
        allSalesPersons = data.data.salesPersons;
        _filteredSalesPersons = allSalesPersons;

        final vendorDetailsProvider =
            Provider.of<CreateRequestVendorDetailsProvider>(context,
                listen: false);

        // Default selection or use the vendor details if available
        selectedSalesManName = vendorDetailsProvider.salesPersonName ??
            allSalesPersons.first.salesPersonName;
        selectedSalesPersonId = vendorDetailsProvider.salesPerson ??
            allSalesPersons.first.salesPerson;

        // Set the first salesman as selected if the list is not empty
        _selectedSalesPerson = allSalesPersons.first;

        // Update the selected salesperson
        setSelectedSalesPerson(_selectedSalesPerson!);

        selectedCustomer = selectedSalesManName;

        // Log to confirm that the salesperson is set
        log('Salesperson: ${_selectedSalesPerson!.salesPersonName}');
        notifyListeners();
      } else {
        // Handle case when no data is fetched (e.g., show an error message)
        log('No salespersons found.');
      }
    } catch (e) {
      // Handle any errors in fetching data
      print("Error fetching salesman data: $e");
    }
  }

  // Future<void> fetchSalesmanData(int? vendorID, BuildContext context) async {
  //   try {
  //     final data =
  //         await salesmanapiService.getVendorAndSalesPersonData(vendorID);
  //     allSalesPersons = data.data.salesPersons;
  //     _filteredSalesPersons = allSalesPersons;

  //     final vendorDetailsProvider =
  //         Provider.of<CreateRequestVendorDetailsProvider>(context,
  //             listen: false);

  //     selectedSalesManName = vendorDetailsProvider.salesPersonName ??
  //         allSalesPersons.first.salesPersonName;
  //     selectedSalesPersonId = vendorDetailsProvider.salesPerson ??
  //         allSalesPersons.first.salesPerson;

  //     // 🟢 Add this: Automatically set the selectedSalesPerson
  //     if (allSalesPersons.isNotEmpty) {
  //       _selectedSalesPerson = allSalesPersons.first;
  //     }
  //     setSelectedSalesPerson(_selectedSalesPerson!);
  //     selectedCustomer = selectedSalesManName;
  //     log('sealesperson: ${_selectedSalesPerson!.salesPersonName}');
  //     notifyListeners();
  //   } catch (e) {
  //     print("Error fetching salesman data: $e");
  //   }
  // }
}
