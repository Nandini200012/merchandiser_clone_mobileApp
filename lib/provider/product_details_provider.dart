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

  // Getters for product details
  dynamic get productId => _productId;
  dynamic get productName => _productName;
  dynamic get UOM => _UOM;
  dynamic get UOMId => _UOMId;
  dynamic get Cost => _Cost;
  dynamic get ItemId => _ItemId;
  dynamic get barcode => _barcode;

  /// Set product details and notify listeners
  void setProductDetails(dynamic productId, dynamic productName, dynamic UOM,
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

  /// Update only the cost of the product
  void updateCost(dynamic cost) {
    _Cost = cost;
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
    notifyListeners();
  }

  // Vendor and Salesperson selection
  Vendors? _selectedVendor;
  SalesPerson? _selectedSalesPerson;

  Vendors? get selectedVendor => _selectedVendor;
  SalesPerson? get selectedSalesPerson => _selectedSalesPerson;

  // API service instance
  final MerchendiserApiService salesmanapiService = MerchendiserApiService();
  final MerchendiserApiService vendorapiService = MerchendiserApiService();

  // Salesperson data
  List<SalesPerson> allSalesPersons = [];
  List<SalesPerson> _filteredSalesPersons = [];

  String selectedCustomer = "";
  String selectedSalesManName = "";
  int? selectedSalesPersonId;
  bool _isExpanded = false;

  // Vendor data
  List<Vendors> vendorList = [];
  late Future<VendorAndSalesPersonModel> vendorData;
  Future<VendorAndSalesPersonModel>? salesmanData;

  // Pagination and loading state
  bool isLoading = false;
  int currentPage = 1;
  final int pageSize = 20;

  /// Set selected vendor and optionally fetch salespersons
  void setSelectedVendor(Vendors vendor, BuildContext context) {
    _selectedVendor = vendor;
    log("Vendor selected: ${vendor.vendorName}");
    // Uncomment the next line if you want to fetch salesmen immediately on selection
    // fetchSalesmanData(_selectedVendor!.vendorId, context);
    notifyListeners();
  }

  /// Set selected salesperson and notify listeners
  void setSelectedSalesPerson(SalesPerson person) {
    _selectedSalesPerson = person;
    notifyListeners();
  }

  /// Fetch vendors from API with pagination and optional search
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

  /// Fetch salesmen data based on selected vendor
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

  /// Internal helper to update loading state
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}

// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:merchandiser_clone/provider/create_request_vendor_detals.dart';
// import 'package:merchandiser_clone/screens/model/Vendors.dart';
// import 'package:merchandiser_clone/screens/model/vendor_and_salesperson_model.dart';
// import 'package:merchandiser_clone/screens/salesman_screens/model/merchendiser_api_service.dart';
// import 'package:provider/provider.dart';

// class ProductDetailsProvider with ChangeNotifier {
//   dynamic _productId;
//   dynamic _productName;
//   dynamic _UOM;
//   dynamic _UOMId;
//   dynamic _Cost;
//   dynamic _ItemId;
//   dynamic _barcode;

//   dynamic get productId => _productId;
//   dynamic get productName => _productName;
//   dynamic get UOM => _UOM;
//   dynamic get UOMId => _UOMId;
//   dynamic get Cost => _Cost;
//   dynamic get ItemId => _ItemId;
//   dynamic get barcode => _barcode;

//   setProductDetails(dynamic productId, dynamic productName, dynamic UOM,
//       dynamic UOMId, dynamic Cost, dynamic ItemID, dynamic barcode) {
//     _productId = productId;
//     _productName = productName;
//     _UOM = UOM;
//     _UOMId = UOMId;
//     _Cost = Cost;
//     _ItemId = ItemID;
//     _barcode = barcode;

//     notifyListeners();
//   }

//   void updateCost(dynamic cost) {
//     _Cost = cost;
//     notifyListeners();
//   }

//   clearProductDetails() {
//     _productId = null;
//     _productName = null;
//     _UOM = null;
//     _ItemId = null;
//     _UOMId = null;
//     _Cost = null;
//     _barcode = null;
//     notifyListeners();
//   }

//   // selected vendor and salesman
//   Vendors? _selectedVendor;
//   SalesPerson? _selectedSalesPerson;

//   Vendors? get selectedVendor => _selectedVendor;
//   SalesPerson? get selectedSalesPerson => _selectedSalesPerson;
//   final MerchendiserApiService salesmanapiService = MerchendiserApiService();
//   List<SalesPerson> allSalesPersons = [];
//   List<SalesPerson> _filteredSalesPersons = [];
//   String selectedCustomer = "";
//   bool _isExpanded = false;
//   String selectedSalesManName = "";
//   int? selectedSalesPersonId;
//   Future<VendorAndSalesPersonModel>? salesmanData;
//   void setSelectedVendor(Vendors vendor, BuildContext context) {
//     _selectedVendor = vendor;
//     log("vendor--->..");
//     // fetchSalesmanData(_selectedVendor!.vendorId, context);
//     notifyListeners();
//   }

//   void setSelectedSalesPerson(SalesPerson person) {
//     _selectedSalesPerson = person;
//     notifyListeners();
//   }

//   late Future<VendorAndSalesPersonModel> vendorData;
//   List<Vendors> vendorList = [];
//   final MerchendiserApiService vendorapiService = MerchendiserApiService();
//   bool isLoading = false;
//   int currentPage = 1;
//   final int pageSize = 20;
//   Future<void> fetchVendors({String query = '', int page = 1}) async {
//     if (isLoading) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final newVendors = await vendorapiService.fetchVendors(
//         query: query,
//         page: page,
//         pageSize: pageSize,
//       );
//       setState(() {
//         if (page == 1) {
//           vendorList = newVendors;
//         } else {
//           vendorList.addAll(newVendors);
//         }
//         currentPage = page;
//       });
//     } catch (error) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $error')));
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> fetchSalesmanData(int? vendorID, BuildContext context) async {
//     try {
//       // Show a loading indicator while the data is being fetched
//       // (Consider using a loading state in your UI or an appropriate state management solution)
//       final data =
//           await salesmanapiService.getVendorAndSalesPersonData(vendorID);

//       if (data != null && data.data.salesPersons.isNotEmpty) {
//         allSalesPersons = data.data.salesPersons;
//         _filteredSalesPersons = allSalesPersons;

//         final vendorDetailsProvider =
//             Provider.of<CreateRequestVendorDetailsProvider>(context,
//                 listen: false);

//         // Default selection or use the vendor details if available
//         selectedSalesManName = vendorDetailsProvider.salesPersonName ??
//             allSalesPersons.first.salesPersonName;
//         selectedSalesPersonId = vendorDetailsProvider.salesPerson ??
//             allSalesPersons.first.salesPerson;

//         // Set the first salesman as selected if the list is not empty
//         _selectedSalesPerson = allSalesPersons.first;

//         // Update the selected salesperson
//         setSelectedSalesPerson(_selectedSalesPerson!);

//         selectedCustomer = selectedSalesManName;

//         // Log to confirm that the salesperson is set
//         log('Salesperson: ${_selectedSalesPerson!.salesPersonName}');
//         notifyListeners();
//       } else {
//         // Handle case when no data is fetched (e.g., show an error message)
//         log('No salespersons found.');
//       }
//     } catch (e) {
//       // Handle any errors in fetching data
//       print("Error fetching salesman data: $e");
//     }
//   }
// }
