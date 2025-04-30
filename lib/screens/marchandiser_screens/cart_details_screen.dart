// ignore_for_file: unnecessary_string_interpolations

import 'dart:convert';
import 'dart:developer';
import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:merchandiser_clone/provider/create_request_vendor_detals.dart';
import 'package:merchandiser_clone/provider/salesperson_provider.dart';
import 'package:merchandiser_clone/screens/common_widget/toast.dart';
import 'package:merchandiser_clone/screens/model/Vendors.dart';
import 'package:merchandiser_clone/screens/model/vendor_and_salesperson_model.dart';
import 'package:merchandiser_clone/screens/salesman_screens/model/merchendiser_api_service.dart';
import 'package:merchandiser_clone/utils/constants.dart';
import 'package:merchandiser_clone/utils/urls.dart';
import 'package:provider/provider.dart';
import 'package:merchandiser_clone/provider/product_details_provider.dart';
import 'package:merchandiser_clone/screens/splash_screen.dart';
import 'package:merchandiser_clone/utils/dynamic_alert_box.dart';
import 'package:merchandiser_clone/utils/willpop.dart';
import 'package:merchandiser_clone/provider/cart_provider.dart';
import 'package:http/http.dart' as http;

// Model class for cart items
class CartDetailsItem {
  final String productName;
  final String productIndex;
  final int quantity;
  final DateTime selectedDate;
  final String note;
  final String reason;
  final dynamic itemId;
  final dynamic uomId;
  dynamic uom;
  final dynamic cost;
  final dynamic barcode;

  CartDetailsItem(
    this.productName,
    this.productIndex,
    this.quantity,
    this.selectedDate,
    this.note,
    this.reason,
    this.itemId,
    this.uomId,
    this.uom,
    this.cost,
    this.barcode,
  );
}

class CartDetailsScreen extends StatefulWidget {
  final int? vendorId;
  final String? vendorName;
  final String? salesManName;
  final String? salesManId;
  const CartDetailsScreen(
      {super.key,
      required this.salesManId,
      required this.salesManName,
      required this.vendorId,
      required this.vendorName});

  @override
  State<CartDetailsScreen> createState() => _CartDetailsScreenState();
}

class _CartDetailsScreenState extends State<CartDetailsScreen> {
  // Controllers
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _reasonTextController = TextEditingController();

  // State variables
  List<CartDetailsItem> itemList = [];
  DateTime? _selectedDate;
  late Willpop willpop;
  bool _isQuantityValid = true;
  bool _isExpiryDateValid = true;
  String? _selectedReason;
  bool _showReasonText = false;
  List<Vendors> vendorList = [];
  late Future<VendorAndSalesPersonModel> vendorData;
  final MerchendiserApiService vendorapiService = MerchendiserApiService();

  final MerchendiserApiService salesmanapiService = MerchendiserApiService();

  List<SalesPerson> _allSalesPersons = [];
  List<SalesPerson> _filteredSalesPersons = [];
  String selectedCustomer = "";
  bool _isExpanded = false;
  String selectedSalesManName = "";
  int? selectedSalesPersonId;
  // Vendors? selectedVendor;
  String selectedUOM = "";
  late Future<VendorAndSalesPersonModel> salesmanData;
  @override
  void initState() {
    super.initState();
    willpop = Willpop(context);
    _fetchLastSalesPrice();

    fetchVendors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var vendorDetailsProvider =
          Provider.of<CreateRequestVendorDetailsProvider>(
        context,
        listen: false,
      );
      var productdetailsprovider = Provider.of<ProductDetailsProvider>(
        context,
        listen: false,
      );
      productdetailsprovider.setSelectedVendor(
          vendorDetailsProvider.getVendor(), context);
    });
  }

  bool isLoading = false;
  int currentPage = 1;
  final int pageSize = 20;
  Future<void> fetchVendors({String query = '', int page = 1}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final newVendors = await vendorapiService.fetchVendors(
        query: query,
        page: page,
        pageSize: pageSize,
      );
      setState(() {
        if (page == 1) {
          vendorList = newVendors;
        } else {
          vendorList.addAll(newVendors);
        }
        currentPage = page;
      });
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _expiryDateController.dispose();
    _notesController.dispose();
    _reasonTextController.dispose();
    super.dispose();
  }

  // Fetch last sales price from API
  Future<void> _fetchLastSalesPrice() async {
    final productDetailsProvider =
        Provider.of<ProductDetailsProvider>(context, listen: false);
    final vendorDetailsProvider =
        Provider.of<CreateRequestVendorDetailsProvider>(context, listen: false);

    final barcode = productDetailsProvider.barcode ?? '';
    final customerId = vendorDetailsProvider.vendorId?.toString() ?? '';

    try {
      final response = await http.get(
        Uri.parse(Urls.getLastSalesPrice),
        headers: {'barcode': barcode, 'customerId': customerId},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'];
        if (data.isNotEmpty) {
          productDetailsProvider.updateCost(data[0]['UnitPrice']);
        }
      } else {
        showTopToast('Failed to fetch price: ${response.statusCode}');
      }
    } catch (e) {
      showTopToast('Error fetching price: $e');
    }
  }

  // Select expiry date
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(DateTime.now().year + 10),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _expiryDateController.text = picked.toLocal().toString().split(' ')[0];
        _isExpiryDateValid = true;
        if (picked.isBefore(DateTime.now())) {
          _selectedReason = "EXPIRED GOODS";
          _showReasonText = false;
        } else {
          _selectedReason = null;
          _showReasonText = false;
        }
      });
    }
  }

  // Add item to the list
  void _addItemToList() {
    final productDetailsProvider =
        Provider.of<ProductDetailsProvider>(context, listen: false);
    bool isValid = true;

    if (_quantityController.text.isEmpty) {
      _isQuantityValid = false;
      isValid = false;
    }
    if (_selectedDate == null) {
      _isExpiryDateValid = false;
      isValid = false;
    }

    if (!isValid) {
      setState(() {});
      return;
    }

    final quantity = int.parse(_quantityController.text);
    final newItem = CartDetailsItem(
      productDetailsProvider.productName ?? '',
      productDetailsProvider.productId?.toString() ?? '',
      quantity,
      _selectedDate!,
      _notesController.text,
      _selectedReason ?? (_showReasonText ? _reasonTextController.text : ''),
      productDetailsProvider.ItemId,
      productDetailsProvider.UOMId,
      productDetailsProvider.UOM,
      productDetailsProvider.Cost,
      productDetailsProvider.barcode,
    );

    setState(() {
      itemList.add(newItem);
      _quantityController.clear();
      _selectedDate = null;
      _notesController.clear();
      _reasonTextController.clear();
      _selectedReason = null;
      _showReasonText = false;
      _isQuantityValid = true;
      _isExpiryDateValid = true;
    });
  }

  // Remove item from the list
  void _removeItemFromList(int index) {
    setState(() {
      itemList.removeAt(index);
    });
  }

  // Add items to cart
  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    for (final item in itemList) {
      if (selectedUOM.isNotEmpty) {
        item.uom = selectedUOM;
      }
      cartProvider.addToCart(item);
    }
    showTopToast('Item added to bin');
  }

  // Show add-to-cart confirmation dialog
  void _showAddToCartDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Do you want to add to bin?",
            style: GoogleFonts.poppins(fontSize: screenWidth * 0.045),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    _addToCart();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    side: MaterialStateProperty.all(
                        const BorderSide(color: Colors.blue)),
                  ),
                  child: Text(
                    "Yes",
                    style: GoogleFonts.poppins(fontSize: screenWidth * 0.04),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ButtonStyle(
                    side: MaterialStateProperty.all(
                        const BorderSide(color: Colors.blue)),
                  ),
                  child: Text(
                    "No",
                    style: GoogleFonts.poppins(fontSize: screenWidth * 0.04),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productDetailsProvider = Provider.of<ProductDetailsProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    var salesPersonDetailsProvider = Provider.of<SalesPersonDetailsProvider>(
      context,
    );
    var vendorDetailsProvider = Provider.of<CreateRequestVendorDetailsProvider>(
      context,
    );
    return WillPopScope(
      onWillPop: () async => Future.value(willpop.onWillPop()),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(context, screenWidth),
        body: _buildBody(
            context,
            screenWidth,
            screenHeight,
            productDetailsProvider,
            vendorDetailsProvider,
            salesPersonDetailsProvider),
      ),
    );
  }

  // Build AppBar
  AppBar _buildAppBar(BuildContext context, double screenWidth) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: screenWidth * 0.06,
        ),
      ),
      title: Text(
        "Product Expiry Details",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: screenWidth * 0.04,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: screenWidth * 0.04, bottom: 10.h),
          child: GestureDetector(
            onTap: () {
              DynamicAlertBox().logOut(
                context,
                "Do you want to logout?",
                () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                ),
              );
            },
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: screenWidth * 0.06,
              child: const Text("MR"),
            ),
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(color: Constants.primaryColor
            // gradient: LinearGradient(
            //   colors: [Constants.primaryColor],
            //   begin: Alignment.topCenter,
            //   end: Alignment.bottomCenter,
            // ),
            ),
      ),
    );
  }

  // Build Body
  Widget _buildBody(
      BuildContext context,
      double screenWidth,
      double screenHeight,
      ProductDetailsProvider productDetailsProvider,
      CreateRequestVendorDetailsProvider vendorDetailsProvider,
      SalesPersonDetailsProvider salesPersonDetailsProvider) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductCard(screenWidth, screenHeight, productDetailsProvider,
                vendorDetailsProvider, salesPersonDetailsProvider),
            SizedBox(height: screenHeight * 0.001),
            _buildAddedItemsSection(
                screenWidth, screenHeight, productDetailsProvider),
            SizedBox(height: screenHeight * 0.02),
            _buildQuantityAndDateInputs(screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.02),
            _buildReasonSection(screenWidth, screenHeight),
            if (_showReasonText) SizedBox(height: screenHeight * 0.02),
            if (_showReasonText)
              _buildCustomReasonInput(screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.02),
            _buildNotesSection(screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.02),
            _buildAddToBinButton(screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  Future<void> showAlternativeUnits(
    BuildContext context,
    dynamic itemID,
  ) async {
    try {
      List<dynamic> data = await vendorapiService.fetchAlternativeUnits(itemID);
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        backgroundColor: Colors.white,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.9, // Adjust the height as needed
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Alternative Units',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(thickness: 1.0),
                  data.isEmpty
                      ? Column(
                          children: [
                            SizedBox(
                              height: 50.h,
                            ),
                            Text(
                              'No data found!',
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView.builder(
                            shrinkWrap:
                                true, // Ensure ListView takes minimal space
                            physics:
                                const NeverScrollableScrollPhysics(), // Disable scrolling in ListView
                            itemCount: data.length,
                            itemBuilder: (context, itemIndex) {
                              var item = data[itemIndex];
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                elevation: 3,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16.0),
                                  title: Text(
                                    item['productName'],
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8.0),
                                      Text(
                                        'Barcode : ${item['productId']}',
                                        style:
                                            TextStyle(color: Colors.grey[700]),
                                      ),
                                      Text(
                                        'UOM : ${item['UOM']}',
                                        style: const TextStyle(
                                            color: Colors.green),
                                      ),
                                      Text(
                                        'Price : ${item['Cost'].toStringAsFixed(2)}',
                                        style:
                                            TextStyle(color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      // selectedProductName = item['productName'];
                                      // selectedProductId = item['productId'];
                                      selectedUOM = item['UOM'];
                                      // selectedUOMId = item['UOMId'];
                                      // selectedCost = item['Cost'];
                                      // selectedItemID = item['ItemID'];
                                      // selectedbarcode = item['Barcode'];
                                      // infoButtonClickedIndex = index;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  // Product Details Card
  Widget _buildProductCard(
      double screenWidth,
      double screenHeight,
      ProductDetailsProvider productDetailsProvider,
      CreateRequestVendorDetailsProvider vendorDetailsProvider,
      SalesPersonDetailsProvider salesPersonDetailsProvider) {
    return Column(
      children: [
        Row(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 0.4, color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0.4,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.024),
                child: Container(
                  width: screenWidth * 0.85,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SizedBox(height: screenHeight * 0.01),
                          Row(
                            children: [
                              Text(
                                'Customer : ',
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  // decoration: TextDecoration.underline,
                                  // decorationColor: Colors.blue, // Underline color
                                  // decorationThickness: 2,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  showVendorSelectionSheet(
                                      context,
                                      productDetailsProvider,
                                      vendorDetailsProvider,
                                      salesPersonDetailsProvider);
                                },
                                child: SizedBox(
                                  width: screenWidth * .6,
                                  child: Text(
                                    '${productDetailsProvider.selectedVendor == null ? vendorDetailsProvider.vendorName : productDetailsProvider.selectedVendor!.vendorName ?? 'Unknown'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          Colors.blue, // Underline color
                                      decorationThickness: 2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 2.h),
                          Text(
                            selectedSalesManName.isEmpty
                                ? 'Sales person:  ${salesPersonDetailsProvider.salesManName ?? "Unknown"}'
                                : 'Sales person:  ${selectedSalesManName}',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            showAlternativeUnits(
              context,
              productDetailsProvider.ItemId,
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 0.4, color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0.4,
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.024),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productDetailsProvider.productName ?? "Unknown Product",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.037,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'BarCode: ${productDetailsProvider.barcode ?? "N/A"}',
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.1),
                              Row(
                                children: [
                                  Text(
                                    'UOM: ',
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    selectedUOM.isEmpty
                                        ? '${productDetailsProvider.UOM ?? "N/A"}'
                                        : '${selectedUOM ?? "N/A"}',
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          Colors.blue, // Underline color
                                      decorationThickness: 2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.005),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Text(
                              //   'UOM: ${productDetailsProvider.UOM ?? "N/A"}',
                              //   style: GoogleFonts.poppins(
                              //     fontSize: screenWidth * 0.035,
                              //     fontWeight: FontWeight.w500,
                              //     color: Colors.grey[600],
                              //   ),
                              // ),
                              // SizedBox(width: screenWidth * 0.1),
                              Text(
                                'Price: ${productDetailsProvider.Cost != null ? productDetailsProvider.Cost.toStringAsFixed(3) : "0.000"}',
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          // SizedBox(height: screenHeight * 0.005),
                          // Text(
                          //   'Price: ${productDetailsProvider.Cost != null ? productDetailsProvider.Cost.toStringAsFixed(3) : "0.000"}',
                          //   style: GoogleFonts.poppins(
                          //     fontSize: screenWidth * 0.035,
                          //     fontWeight: FontWeight.w600,
                          //     color: Colors.green,
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  showVendorSelectionSheet(
      BuildContext context,
      ProductDetailsProvider productDetailsProvider,
      CreateRequestVendorDetailsProvider vendorprovider,
      SalesPersonDetailsProvider salesmanprovider) {
    TextEditingController searchController = TextEditingController();
    List<Vendors> filteredVendors = List.from(vendorList);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        filteredVendors = vendorList
                            .where((vendor) => vendor.vendorName
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search vendor...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  // List
                  Expanded(
                    child: filteredVendors.isNotEmpty
                        ? ListView.builder(
                            itemCount: filteredVendors.length,
                            itemBuilder: (context, index) {
                              final vendor = filteredVendors[index];
                              final isSelected = vendor ==
                                  productDetailsProvider.selectedVendor;

                              return GestureDetector(
                                onTap: () {
                                  salesmanprovider.setSalesPersonDetails(
                                      vendor.salesPersonName,
                                      vendor.salesPerson,
                                      "");

                                  vendorprovider.setVendorDetails(
                                      vendor.vendorId,
                                      vendor.vendorName,
                                      vendor.salesPerson,
                                      vendor.salesPersonName,
                                      vendor.mobileNo);
                                  productDetailsProvider.setSelectedVendor(
                                      vendor, context);
                                  selectedSalesManName =
                                      vendor.salesPersonName.toString();
                                  // _fetchSalesmanData(vendor.vendorId);
                                  Navigator.pop(
                                      context, vendor); // Return on tap
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 6.h),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue.shade100
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey.shade300),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Constants.primaryColor,
                                        child: Text(
                                          vendor.vendorName.isNotEmpty
                                              ? vendor.vendorName[0]
                                              : '',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vendor.vendorName,
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Code: ${vendor.vendorCode}',
                                              style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.grey.shade600),
                                            ),
                                            Text(
                                              'Mobile: ${vendor.mobileNo}',
                                              style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(Icons.check_circle,
                                            color: Colors.blue),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(child: Text('No vendors found')),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((selected) {
      if (selected != null) {
        // Use the selected vendor
        print("Selected Vendor: ${selected.vendorName}");
      }
    });
  }

  // Added Items Section
  Widget _buildAddedItemsSection(
    double screenWidth,
    double screenHeight,
    ProductDetailsProvider productDetailsProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (itemList.isNotEmpty)
          Text(
            "Added Items",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.034,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        if (itemList.isNotEmpty) SizedBox(height: screenHeight * 0.01),
        if (itemList.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent),
            ),
            child: DynamicHeightGridView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: itemList.length,
              crossAxisCount: 2,
              crossAxisSpacing: screenWidth * 0.03,
              mainAxisSpacing: screenWidth * 0.03,
              builder: (ctx, index) {
                final item = itemList[index];
                final pickedDate =
                    DateFormat('dd/MM/yyyy').format(item.selectedDate);

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${item.quantity} ${productDetailsProvider.UOM ?? "N/A"} $pickedDate",
                          style:
                              GoogleFonts.poppins(fontSize: screenWidth * 0.03),
                        ),
                        InkWell(
                          onTap: () => _removeItemFromList(index),
                          child: Icon(Icons.close, size: screenWidth * 0.04),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Quantity and Expiry Date Inputs
  Widget _buildQuantityAndDateInputs(double screenWidth, double screenHeight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Qty",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.034,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(width: 10.w),
        SizedBox(
          height: 40.h,
          width: screenWidth * 0.25,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _isQuantityValid ? Colors.grey : Colors.red),
            ),
            child: TextFormField(
              style: GoogleFonts.poppins(
                color: Colors.grey.shade900,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
              keyboardType: TextInputType.number,
              controller: _quantityController,
              decoration: InputDecoration(
                hintText: "qty",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 10.sp,
                ),
                border: InputBorder.none,
              ),
              onEditingComplete: () {
                if (_isQuantityValid && _selectedDate == null) {
                  try {
                    // if (quantity > 0 && _selectedDate == null) {
                    // Automatically open date picker if quantity is valid and no date is selected
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _selectDate(context);
                    });
                    // }
                  } catch (e) {
                    _isQuantityValid = false;
                  }
                }
              },
              onChanged: (value) {
                setState(() {
                  _isQuantityValid = value.isNotEmpty;
                  // Check if the input is a valid positive integer
                });
              },
            ),
          ),
        ),
        SizedBox(width: 15.w),
        Text(
          "Exp\nDate",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.034,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(width: 10.w),
        SizedBox(
          width: screenWidth * 0.42,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _isExpiryDateValid ? Colors.grey : Colors.red),
            ),
            child: TextButton(
              onPressed: () => _selectDate(context),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedDate == null
                      ? "Select Date"
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                  style: GoogleFonts.poppins(
                    fontWeight: _selectedDate == null
                        ? FontWeight.w500
                        : FontWeight.w600,
                    color: _selectedDate == null
                        ? Colors.grey.shade700
                        : Colors.grey.shade900,
                    fontSize: _selectedDate == null ? 10.sp : 12.sp,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Reason Selection
  Widget _buildReasonSection(double screenWidth, double screenHeight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Reason",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.034,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: screenWidth * 0.74,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: InputBorder.none),
              hint: Text(
                "Select Reason",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
              ),
              value: _selectedReason,
              items: const [
                DropdownMenuItem(
                    value: "EXCESS STOCK", child: Text("Excess Stock")),
                DropdownMenuItem(
                    value: "EXPIRED GOODS", child: Text("Expired Goods")),
                DropdownMenuItem(
                    value: "NEAR EXPIRY GOODS",
                    child: Text("Near Expiry Goods")),
                DropdownMenuItem(value: "DAMAGE", child: Text("Damage")),
                DropdownMenuItem(
                    value: "PROMO RETURNS", child: Text("Promo Returns")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
              ],
              onChanged: (
                      // _selectedReason == "EXPIRED GOODS" ||
                      _quantityController.text.isEmpty || _selectedDate == null)
                  ? null
                  : (value) {
                      setState(() {
                        _selectedReason = value;
                        _showReasonText = value == "Other";
                      });
                    },

              // onChanged: _selectedReason == "EXPIRED GOODS"
              //     ? null
              //     : (value) {
              //         setState(() {
              //           _selectedReason = value;
              //           _showReasonText = value == "Other";
              //         });
              //       },
            ),
          ),
        ),
      ],
    );
  }

  // Custom Reason Input
  Widget _buildCustomReasonInput(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Please specify reason",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: TextFormField(
            controller: _reasonTextController,
            decoration: const InputDecoration(
              hintText: "Reason here...",
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // Notes Section with Add Button
  Widget _buildNotesSection(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Notes",
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.034,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _addItemToList,
              child: Container(
                decoration: BoxDecoration(
                  color: Constants.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 25),
                  child: Row(
                    children: [
                      Text(
                        'Add',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Icon(Icons.add, size: 16.sp, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.016),
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: TextFormField(
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            controller: _notesController,
            decoration: InputDecoration(
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
              ),
              hintText: "Write some notes about the product",
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // Add to Bin Button
  Widget _buildAddToBinButton(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.01, vertical: screenHeight * 0.012),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              itemList.isEmpty ? null : () => _showAddToCartDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                itemList.isEmpty ? Colors.grey.shade700 : Constants.buttonColor,
            // const Color.fromARGB(255, 132, 23, 152),
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Add to Bin",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// // ignore_for_file: sort_child_properties_last

// import 'dart:convert';
// import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:merchandiser_clone/provider/create_request_vendor_detals.dart';
// import 'package:merchandiser_clone/screens/common_widget/toast.dart';
// import 'package:merchandiser_clone/utils/constants.dart';
// import 'package:merchandiser_clone/utils/urls.dart';
// import 'package:provider/provider.dart';
// import 'package:merchandiser_clone/provider/product_details_provider.dart';
// import 'package:merchandiser_clone/screens/splash_screen.dart';
// import 'package:merchandiser_clone/utils/dynamic_alert_box.dart';
// import 'package:merchandiser_clone/utils/willpop.dart';
// import 'package:merchandiser_clone/provider/cart_provider.dart';
// import 'package:http/http.dart' as http;

// class CartDetailsScreen extends StatefulWidget {
//   const CartDetailsScreen({super.key});

//   @override
//   State<CartDetailsScreen> createState() => _CartDetailsScreenState();
// }

// class _CartDetailsScreenState extends State<CartDetailsScreen> {
//   final TextEditingController _expiryDateController = TextEditingController();
//   final TextEditingController _quantityController = TextEditingController();
//   final TextEditingController _notesController = TextEditingController();
//   final TextEditingController _reasonTextController = TextEditingController();
//   List<CartDetailsItem> itemList = [];
//   DateTime? _selectedDate;
//   late Willpop willpop;
//   bool _isQuantityValid = true;
//   bool _isExpiryDateValid = true;
//   String? _selectedReason;
//   bool _showReasonText = false;

//   @override
//   void initState() {
//     _fetchLastSalesPrice();
//     super.initState();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     willpop = Willpop(context);
//     _quantityController.dispose();
//     _expiryDateController.dispose();
//     _reasonTextController.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     var productDetailsProvider = Provider.of<ProductDetailsProvider>(context);
//     dynamic? productId = productDetailsProvider.productId;
//     dynamic? productName = productDetailsProvider.productName;
//     dynamic? UOM = productDetailsProvider.UOM;
//     dynamic? productCost = productDetailsProvider.Cost;

//     var screenWidth = MediaQuery.of(context).size.width;
//     var screenHeight = MediaQuery.of(context).size.height;

//     return WillPopScope(
//       onWillPop: () async {
//         return willpop.onWillPop();
//       },
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           leading: IconButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             icon: Icon(
//               Icons.arrow_back,
//               color: Colors.white,
//               size: screenWidth * 0.06,
//             ),
//           ),
//           title: Text(
//             "Product Expiry Details",
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               color: Colors.white,
//               fontSize: screenWidth * 0.04,
//             ),
//           ),
//           centerTitle: true,
//           actions: [
//             Padding(
//               padding: EdgeInsets.only(right: screenWidth * 0.04, bottom: 10.h),
//               child: GestureDetector(
//                 onTap: () {
//                   DynamicAlertBox().logOut(
//                     context,
//                     "Do you Want to Logout",
//                     () {
//                       Navigator.of(context).pushReplacement(
//                         MaterialPageRoute(builder: (context) => SplashScreen()),
//                       );
//                     },
//                   );
//                 },
//                 child: CircleAvatar(
//                   backgroundColor: Colors.white,
//                   radius: screenWidth * 0.06,
//                   child: Text("MR"),
//                 ),
//               ),
//             ),
//           ],
//           flexibleSpace: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: const [
//                   Colors.purple,
//                   Constants.primaryColor,
//                 ],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//           ),
//         ),
//         body: Stack(
//           children: [
//             Padding(
//               padding: EdgeInsets.all(screenWidth * 0.04),
//               child: SingleChildScrollView(
//                 child: SafeArea(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(
//                         width: double.infinity,
//                         child: Card(
//                           shape: RoundedRectangleBorder(
//                             side: BorderSide(
//                                 width: 0.4, color: Colors.grey.shade200),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 0.4,
//                           child: Padding(
//                             padding: EdgeInsets.all(screenWidth * 0.04),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   productDetailsProvider.productName ?? "",
//                                   style: GoogleFonts.poppins(
//                                     fontSize: screenWidth * 0.045,
//                                     fontWeight: FontWeight.w700,
//                                     color: Colors.grey.shade800,
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                   maxLines: 2,
//                                   softWrap: false,
//                                 ),
//                                 SizedBox(height: screenHeight * 0.01),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   children: [
//                                     Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           'BarCode : ${productDetailsProvider.barcode.toString()}',
//                                           style: GoogleFonts.poppins(
//                                             fontSize: screenWidth * 0.035,
//                                             fontWeight: FontWeight.w500,
//                                             color: Colors.grey[600],
//                                           ),
//                                         ),
//                                         SizedBox(height: screenHeight * 0.005),
//                                         Text(
//                                           'UOM : ${productDetailsProvider.UOM.toString()}',
//                                           style: GoogleFonts.poppins(
//                                             fontSize: screenWidth * 0.035,
//                                             fontWeight: FontWeight.w500,
//                                             color: Colors.grey[600],
//                                           ),
//                                         ),
//                                         SizedBox(height: screenHeight * 0.005),
//                                         Text(
//                                           'Price : ${productDetailsProvider.Cost != null ? productDetailsProvider.Cost.toStringAsFixed(3) : '0.000'}',
//                                           style: GoogleFonts.poppins(
//                                               fontSize: screenWidth * 0.035,
//                                               fontWeight: FontWeight.w600,
//                                               color: Colors.green),
//                                         ),
//                                       ],
//                                     ),
//                                     const Spacer(),
//                                     IconButton(
//                                         onPressed: () {
//                                           // showAlternativeUnits(
//                                           //     context,
//                                           //     selectedItemID,
//                                           //     infoButtonClickedIndex!);
//                                         },
//                                         icon: Icon(Icons.info_outline))
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),

//                       SizedBox(height: screenHeight * 0.02),
//                       Visibility(
//                         visible: itemList.isNotEmpty,
//                         child: Text(
//                           "Added Items",
//                           style: GoogleFonts.poppins(
//                             fontSize: screenWidth * 0.034,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.grey.shade800,
//                           ),
//                         ),
//                       ),
//                       Visibility(
//                           visible: itemList.isNotEmpty,
//                           child: SizedBox(height: screenHeight * 0.01)),
//                       Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.transparent),
//                         ),
//                         child: DynamicHeightGridView(
//                           physics: const NeverScrollableScrollPhysics(),
//                           shrinkWrap: true,
//                           itemCount: itemList.length,
//                           crossAxisCount: 2,
//                           crossAxisSpacing: screenWidth * 0.03,
//                           mainAxisSpacing: screenWidth * 0.03,
//                           builder: (ctx, index) {
//                             CartDetailsItem item = itemList[index];
//                             String pickedDate = DateFormat(
//                               'dd/MM/yyyy',
//                             ).format(item.selectedDate);

//                             return Container(
//                               decoration: BoxDecoration(
//                                 border: Border.all(),
//                                 borderRadius: BorderRadius.circular(
//                                   screenWidth * 0.02,
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: EdgeInsets.all(screenWidth * 0.02),
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       "${item.quantity} ${UOM.toString()} $pickedDate",
//                                       style: TextStyle(
//                                         fontSize: screenWidth * 0.03,
//                                       ),
//                                     ),
//                                     InkWell(
//                                       onTap: () {
//                                         _removeItemFromList(index);
//                                       },
//                                       child: Icon(
//                                         Icons.close,
//                                         size: screenWidth * 0.04,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       Visibility(
//                           visible: itemList.isNotEmpty,
//                           child: SizedBox(height: screenHeight * 0.01)),

//                       SizedBox(height: screenHeight * 0.002),
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Qty",
//                             style: GoogleFonts.poppins(
//                               fontSize: screenWidth * 0.034,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey.shade800,
//                             ),
//                           ),
//                           SizedBox(
//                             width: 20.w,
//                           ),
//                           // SizedBox(height: screenHeight * 0.01),
//                           SizedBox(
//                             width: screenWidth * 0.2,
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: screenWidth * 0.02,
//                               ),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(
//                                   color: _isQuantityValid
//                                       ? Colors.grey
//                                       : Colors.red,
//                                 ),
//                               ),
//                               child: TextFormField(
//                                 style: GoogleFonts.poppins(
//                                     color: Colors.grey.shade900,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 12.sp),
//                                 keyboardType: TextInputType.number,
//                                 controller: _quantityController,
//                                 decoration: InputDecoration(
//                                   hintText: "Enter qty",
//                                   hintStyle: GoogleFonts.poppins(
//                                       color: Colors.grey.shade600,
//                                       fontWeight: FontWeight.w500,
//                                       fontSize: 10.sp),
//                                   border: InputBorder.none,
//                                 ),
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _isQuantityValid = value.isNotEmpty;
//                                   });
//                                 },
//                               ),
//                             ),
//                           ),
//                           SizedBox(
//                             width: 15.w,
//                           ),
//                           Text(
//                             "Exp \nDate",
//                             style: GoogleFonts.poppins(
//                               fontSize: screenWidth * 0.034,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey.shade800,
//                             ),
//                           ),
//                           SizedBox(
//                             width: 20.w,
//                           ),
//                           // SizedBox(height: screenHeight * 0.01),
//                           SizedBox(
//                             width: screenWidth * 0.365,
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: screenWidth * 0.02,
//                               ),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(
//                                   color: _isExpiryDateValid
//                                       ? Colors.grey
//                                       : Colors.red,
//                                 ),
//                               ),
//                               child: TextButton(
//                                 onPressed: () {
//                                   _selectDate(context);
//                                 },
//                                 child: Align(
//                                   alignment: Alignment.centerLeft,
//                                   child: Text(
//                                     _selectedDate == null
//                                         ? "Select Date"
//                                         : DateFormat(
//                                             'dd/MM/yyyy',
//                                           ).format(_selectedDate!),
//                                     style: GoogleFonts.poppins(
//                                         fontWeight: _selectedDate == null
//                                             ? FontWeight.w500
//                                             : FontWeight.w600,
//                                         color: _selectedDate == null
//                                             ? Colors.grey.shade700
//                                             : Colors.grey.shade900,
//                                         fontSize: _selectedDate == null
//                                             ? 10.sp
//                                             : 12.sp),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: screenHeight * 0.02),
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Reason",
//                             style: GoogleFonts.poppins(
//                               fontSize: screenWidth * 0.034,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey.shade800,
//                             ),
//                           ),
//                           Spacer(),
//                           // SizedBox(height: screenHeight * 0.01),
//                           SizedBox(
//                             width: screenWidth * 0.65,
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: screenWidth * 0.02,
//                               ),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: Colors.grey),
//                               ),
//                               child: DropdownButtonFormField<String>(
//                                 decoration: InputDecoration(
//                                   border: InputBorder.none,
//                                   hintStyle: GoogleFonts.poppins(
//                                       color: Colors.grey.shade600,
//                                       fontWeight: FontWeight.w500,
//                                       fontSize: 10.sp),
//                                 ),
//                                 hint: Text(
//                                   "Select Reason",
//                                   style: GoogleFonts.poppins(
//                                       color: Colors.grey.shade600,
//                                       fontWeight: FontWeight.w500,
//                                       fontSize: 12.sp),
//                                 ),
//                                 value: _selectedReason,
//                                 items: const [
//                                   DropdownMenuItem(
//                                     child: Row(
//                                       children: [
//                                         SizedBox(width: 10),
//                                         Text("Excess Stock"),
//                                       ],
//                                     ),
//                                     value: "EXCESS STOCK",
//                                   ),
//                                   DropdownMenuItem(
//                                     child: Row(
//                                       children: [
//                                         SizedBox(width: 10),
//                                         Text("Expired Goods"),
//                                       ],
//                                     ),
//                                     value: "EXPIRED GOODS",
//                                   ),
//                                   DropdownMenuItem(
//                                     child: Row(
//                                       children: [
//                                         SizedBox(width: 10),
//                                         Text("Near Expiry Goods"),
//                                       ],
//                                     ),
//                                     value: "NEAR EXPIRY GOODS",
//                                   ),
//                                   DropdownMenuItem(
//                                     child: Row(
//                                       children: [
//                                         SizedBox(width: 10),
//                                         Text("Damage"),
//                                       ],
//                                     ),
//                                     value: "DAMAGE",
//                                   ),
//                                   DropdownMenuItem(
//                                     child: Row(
//                                       children: [
//                                         SizedBox(width: 10),
//                                         Text("Promo Returns"),
//                                       ],
//                                     ),
//                                     value: "PROMO RETURNS",
//                                   ),
//                                   DropdownMenuItem(
//                                     child: Row(
//                                       children: [
//                                         SizedBox(width: 10),
//                                         Text("Other"),
//                                       ],
//                                     ),
//                                     value: "Other",
//                                   ),
//                                 ],
//                                 onChanged: _selectedReason == "EXPIRED GOODS"
//                                     ? null
//                                     : (value) {
//                                         setState(() {
//                                           _selectedReason = value;
//                                           _showReasonText = value == "Other";
//                                         });
//                                       },
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (_showReasonText)
//                         SizedBox(height: screenHeight * 0.02),
//                       if (_showReasonText)
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Please specify reason",
//                               style: TextStyle(
//                                 fontSize: screenWidth * 0.045,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             SizedBox(height: screenHeight * 0.01),
//                             Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: screenWidth * 0.02,
//                               ),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: Colors.grey),
//                               ),
//                               child: TextFormField(
//                                 controller: _reasonTextController,
//                                 decoration: InputDecoration(
//                                   hintText: "Reason here...",
//                                   border: InputBorder.none,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       SizedBox(height: screenHeight * 0.02),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Text(
//                                 "Notes",
//                                 style: GoogleFonts.poppins(
//                                   fontSize: screenWidth * 0.034,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.grey.shade800,
//                                 ),
//                               ),
//                               Spacer(),
//                               GestureDetector(
//                                 onTap: () {
//                                   if (_quantityController.text.isEmpty) {
//                                     setState(() {
//                                       _isQuantityValid = false;
//                                     });
//                                   } else {
//                                     setState(() {
//                                       _isQuantityValid = true;
//                                     });
//                                   }

//                                   if (_selectedDate == null) {
//                                     setState(() {
//                                       _isExpiryDateValid = false;
//                                     });
//                                   } else {
//                                     setState(() {
//                                       _isExpiryDateValid = true;
//                                     });
//                                   }

//                                   if (_quantityController.text.isNotEmpty &&
//                                       _selectedDate != null) {
//                                     _addItemToList();
//                                   }
//                                 },
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                       color: Constants.primaryColor,
//                                       borderRadius: BorderRadius.circular(12)),
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                         vertical: 6, horizontal: 25),
//                                     child: Row(
//                                       children: [
//                                         Text(
//                                           'Add',
//                                           style: GoogleFonts.poppins(
//                                             fontSize: screenWidth * 0.028,
//                                             fontWeight: FontWeight.w700,
//                                             color: Colors.white,
//                                           ),
//                                         ),
//                                         Icon(
//                                           Icons.add,
//                                           size: 16.sp,
//                                           color: Colors.white,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               )
//                             ],
//                           ),
//                           SizedBox(height: screenHeight * 0.016),
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: screenWidth * 0.02,
//                             ),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.grey),
//                             ),
//                             child: TextFormField(
//                               maxLines: 3,
//                               keyboardType: TextInputType.multiline,
//                               controller: _notesController,
//                               decoration: InputDecoration(
//                                 hintStyle: GoogleFonts.poppins(
//                                     color: Colors.grey.shade600,
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: 12.sp),
//                                 hintText: "Write some notes about the product",
//                                 border: InputBorder.none,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: screenHeight * 0.02),

//                       SizedBox(
//                         height: screenHeight * 0.012,
//                       ), // Placeholder for sticky button

//                       Container(
//                         // color: Colors.white,
//                         padding: EdgeInsets.symmetric(
//                           horizontal: screenWidth * 0.01,
//                           vertical: screenHeight * 0.012,
//                         ),
//                         child: SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: itemList.isEmpty
//                                 ? null
//                                 : () {
//                                     _showAddToCartDialog(context);
//                                   },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: itemList.isEmpty
//                                   ? Colors.grey.shade700
//                                   : const Color.fromARGB(255, 132, 23, 152),
//                               padding: EdgeInsets.symmetric(
//                                 vertical: screenHeight * 0.012,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             child: Text(
//                               "Add to Bin",
//                               style: GoogleFonts.poppins(
//                                 color: Colors.white,
//                                 fontSize: screenWidth * 0.04,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _fetchLastSalesPrice() async {
//     var productDetailsProvider = Provider.of<ProductDetailsProvider>(
//       context,
//       listen: false,
//     );
//     var vendorDetailsProvider = Provider.of<CreateRequestVendorDetailsProvider>(
//       context,
//       listen: false,
//     );

//     String barcode = productDetailsProvider.barcode ?? '';
//     String customerId = vendorDetailsProvider.vendorId?.toString() ?? '';

//     try {
//       var response = await http.get(
//         Uri.parse(Urls.getLastSalesPrice),
//         headers: {'barcode': barcode, 'customerId': customerId},
//       );

//       if (response.statusCode == 200) {
//         var responseData = json.decode(response.body);
//         var data = responseData['data'];

//         if (data.isNotEmpty) {
//           setState(() {
//             productDetailsProvider.updateCost(
//               data[0]['UnitPrice'],
//             ); // Assuming data[0] contains the price
//           });
//         } else {
//           print('No data available to update the cost.');
//         }
//       } else {
//         print('Failed to fetch price. Status code: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching price: $e');
//     }
//   }

//   void _showAddToCartDialog(BuildContext context) {
//     var screenWidth = MediaQuery.of(context).size.width;
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             "Do you want to add to Cart?",
//             style: TextStyle(fontSize: screenWidth * 0.045),
//           ),
//           actions: [
//             Center(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   TextButton(
//                     onPressed: () {
//                       _addToCart();
//                       Navigator.of(context).pop();
//                       Navigator.of(context).pop();
//                       showTopToast("Added to cart");
//                       showTopToast("Added to bin");
//                     },
//                     style: ButtonStyle(
//                       side: MaterialStateProperty.all(
//                         BorderSide(color: Colors.blue),
//                       ),
//                     ),
//                     child: Text(
//                       "Yes",
//                       style: TextStyle(fontSize: screenWidth * 0.04),
//                     ),
//                   ),
//                   SizedBox(width: screenWidth * 0.02),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                     style: ButtonStyle(
//                       side: MaterialStateProperty.all(
//                         BorderSide(color: Colors.blue),
//                       ),
//                     ),
//                     child: Text(
//                       "No",
//                       style: TextStyle(fontSize: screenWidth * 0.04),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<DateTime?> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1990),
//       lastDate: DateTime(DateTime.now().year + 10),
//     );

//     if (picked != null && picked != DateTime.now()) {
//       setState(() {
//         _selectedDate = picked;
//         _expiryDateController.text = picked.toLocal().toString().split(' ')[0];

//         // Check if the selected date is before today
//         if (picked.isBefore(DateTime.now())) {
//           _selectedReason = "EXPIRED GOODS";
//           _showReasonText = false;
//         } else {
//           _selectedReason = null;
//         }
//       });
//       return picked;
//     }
//     return null;
//   }

//   void _addItemToList() {
//     var productDetailsProvider = Provider.of<ProductDetailsProvider>(
//       context,
//       listen: false,
//     );
//     dynamic? productId = productDetailsProvider.productId;
//     String? productName = productDetailsProvider.productName;
//     dynamic? ItemID = productDetailsProvider.ItemId;
//     dynamic? UomId = productDetailsProvider.UOMId;
//     dynamic? UOM = productDetailsProvider.UOM;
//     dynamic? Cost = productDetailsProvider.Cost;
//     dynamic? Barcode = productDetailsProvider.barcode;
//     if (_quantityController.text.isNotEmpty && _selectedDate != null) {
//       int quantity = int.parse(_quantityController.text);
//       String notes = _notesController.text;
//       String reason = _selectedReason ?? '';
//       CartDetailsItem newItem = CartDetailsItem(
//           productName.toString(),
//           productId.toString(),
//           quantity,
//           _selectedDate!,
//           notes,
//           reason,
//           ItemID,
//           UomId,
//           UOM,
//           Cost,
//           Barcode);

//       setState(() {
//         itemList.add(newItem);
//         _quantityController.clear();
//         _selectedDate = null;
//         _notesController.clear();
//         _reasonTextController.clear();
//         _selectedReason = null;
//         _showReasonText = false;
//       });
//     }
//   }

//   void _addToCart() {
//     CartProvider cartProvider = Provider.of<CartProvider>(
//       context,
//       listen: false,
//     );
//     for (CartDetailsItem item in itemList) {
//       cartProvider.addToCart(item);
//     }
//   }

//   void _removeItemFromList(int index) {
//     setState(() {
//       itemList.removeAt(index);
//     });
//   }
// }

// class CartDetailsItem {
//   String productName;
//   String productIndex;
//   int quantity;
//   DateTime selectedDate;
//   String note;
//   String reason;
//   dynamic itemId;
//   dynamic uomId;
//   dynamic UOM;
//   dynamic Cost;
//   dynamic barcode;

//   CartDetailsItem(
//       this.productName,
//       this.productIndex,
//       this.quantity,
//       this.selectedDate,
//       this.note,
//       this.reason,
//       this.itemId,
//       this.uomId,
//       this.UOM,
//       this.Cost,
//       this.barcode);
// }
