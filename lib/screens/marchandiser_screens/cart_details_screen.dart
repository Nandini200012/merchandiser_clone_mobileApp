// // ignore_for_file: unnecessary_string_interpolations

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
import 'package:merchandiser_clone/utils/unsavedDialogue.dart';
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
  final String uomId;
  dynamic uom;
  final dynamic uomCost;
  final dynamic cost;
  final dynamic barcode;

  CartDetailsItem(
    this.uomCost,
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
  final String? uomId;
  const CartDetailsScreen({
    super.key,
    required this.uomId,
    required this.salesManId,
    required this.salesManName,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<CartDetailsScreen> createState() => _CartDetailsScreenState();
}

class _CartDetailsScreenState extends State<CartDetailsScreen> {
  // Controllers
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _reasonTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
  String selectedUOM = "";
  dynamic selectedUOMID = 0;
  dynamic selectedbarcode = null;
  dynamic selectedUomCost = 0;
  dynamic selectedUomItemID = null;
  late Future<VendorAndSalesPersonModel> salesmanData;
  bool isLoading = false;
  int currentPage = 1;
  final int pageSize = 20;
  bool isNotesChecked = false;
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

      // Add listeners for scrolling when text fields are edited
      _quantityController.addListener(_scrollToBottom);
      _notesController.addListener(_scrollToBottom);
      _reasonTextController.addListener(_scrollToBottom);
    });
  }

  // // Scroll to bottom to ensure Add to Bin button is visible
  void _scrollToBottom({double offset = 100.0}) {
    if (_quantityController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _reasonTextController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          offset, // <-- Replace this with the desired scroll offset in pixels
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // void _scrollToBottom() {
  //   if (_quantityController.text.isNotEmpty ||
  //       _notesController.text.isNotEmpty ||
  //       _reasonTextController.text.isNotEmpty) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       _scrollController.animateTo(
  //         _scrollController.position.extentAfter,
  //         duration: const Duration(milliseconds: 300),
  //         curve: Curves.easeOut,
  //       );
  //     });
  //   }
  // }

  @override
  void dispose() {
    _scrollController.dispose();
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
    final itemID = productDetailsProvider.ItemId ?? '';
    log('Item ID selected Product: $itemID');
    try {
      final response = await http.get(
        Uri.parse(Urls.getLastSalesPrice),
        headers: {'itemID': itemID.toString()},
      );
      if (response.statusCode == 200) {
        log('response from api : ${response.body}');
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        if (data.isNotEmpty) {
          final List<Map<String, dynamic>> formattedList =
              List<Map<String, dynamic>>.from(data);
          productDetailsProvider.setSalesPriceList(formattedList);
          productDetailsProvider.fetchcostbyUom(widget.uomId.toString());
          log('Last sales price data: $formattedList');
          final currentUomId =
              selectedUOMID != 0 ? selectedUOMID : productDetailsProvider.UOMId;
        }
      } else {
        showTopToast('Failed to fetch price: ${response.statusCode}');
        log('Failed to fetch price: ${response.statusCode}');
      }
    } catch (e) {
      showTopToast('Error fetching price: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).unfocus(); // Unfocus to hide the keyboard
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
          _showReasonText = false;
        } else {
          _selectedReason = null;
          _showReasonText = false;
        }
      });

      // Manually focus on another widget if needed (e.g., expiry date button)
      FocusScope.of(context)
          .requestFocus(FocusNode()); // or use a specific focus node
    }
  }

  // Find existing item index
  int _findExistingItemIndex(CartDetailsItem newItem) {
    for (int i = 0; i < itemList.length; i++) {
      final existingItem = itemList[i];
      if (existingItem.barcode == newItem.barcode &&
          existingItem.uomId == newItem.uomId &&
          DateFormat('yyyy-MM-dd').format(existingItem.selectedDate) ==
              DateFormat('yyyy-MM-dd').format(newItem.selectedDate)) {
        return i;
      }
    }
    return -1;
  }

  // Add item to the list
  void _addItemToList() {
    _scrollToBottom(offset: 150.00);
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
      selectedUomCost != 0 ? selectedUomCost : productDetailsProvider.uomcost,
      productDetailsProvider.productName ?? '',
      selectedUomItemID != 0
          ? selectedUomItemID.toString()
          : productDetailsProvider.productId?.toString() ?? '',
      quantity,
      _selectedDate!,
      _notesController.text,
      _selectedReason ?? (_showReasonText ? _reasonTextController.text : ''),
      productDetailsProvider.ItemId,
      selectedUOMID.toString() != '0'
          ? selectedUOMID.toString()
          : productDetailsProvider.UOMId.toString(),
      selectedUOM.isNotEmpty ? selectedUOM : productDetailsProvider.UOM ?? '',
      selectedUomCost != 0 ? selectedUomCost : productDetailsProvider.uomcost,
      selectedbarcode ?? productDetailsProvider.barcode,
    );
    final existingIndex = _findExistingItemIndex(newItem);
    setState(() {
      if (existingIndex != -1) {
        final existingItem = itemList[existingIndex];
        itemList[existingIndex] = CartDetailsItem(
          existingItem.uomCost,
          existingItem.productName,
          existingItem.productIndex,
          existingItem.quantity + newItem.quantity,
          existingItem.selectedDate,
          _notesController.text.isNotEmpty
              ? _notesController.text
              : existingItem.note,
          _selectedReason ?? existingItem.reason,
          existingItem.itemId,
          existingItem.uomId,
          existingItem.uom,
          existingItem.uomCost,
          existingItem.barcode,
        );
        showTopToast('Quantity updated for existing item');
      } else {
        itemList.add(newItem);
        showTopToast('New item added to list');
      }
      _quantityController.clear();
      _selectedDate = null;
      _notesController.clear();
      _reasonTextController.clear();
      _selectedReason = null;
      _showReasonText = false;
      _isQuantityValid = true;
      _isExpiryDateValid = true;
      selectedUOM = productDetailsProvider.UOM ?? "";
      selectedUOMID = productDetailsProvider.UOMId ?? "";
      selectedbarcode = productDetailsProvider.barcode;
      selectedUomCost = productDetailsProvider.uomcost;
      selectedUomItemID = productDetailsProvider.ItemId;
    });
    // Dismiss the keyboard
    FocusScope.of(context).unfocus();
  }

  // Remove item from the list
  void _removeItemFromList(int index) {
    setState(() {
      itemList.removeAt(index);
    });
  }

  // Add items to cart
  void _addToCart() {
    if (itemList.isEmpty) {
      showTopToast('No items to add to cart');
      return;
    }
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    for (final item in itemList) {
      final existingIndex = cartProvider.cartItems.indexWhere((cartItem) =>
          cartItem.barcode == item.barcode &&
          cartItem.uomId == item.uomId &&
          DateFormat('yyyy-MM-dd').format(cartItem.selectedDate) ==
              DateFormat('yyyy-MM-dd').format(item.selectedDate));
      if (existingIndex != -1) {
        final existingItem = cartProvider.cartItems[existingIndex];
        final updatedItem = CartDetailsItem(
          existingItem.uomCost,
          existingItem.productName,
          existingItem.productIndex,
          existingItem.quantity + item.quantity,
          existingItem.selectedDate,
          item.note.isNotEmpty ? item.note : existingItem.note,
          item.reason.isNotEmpty ? item.reason : existingItem.reason,
          existingItem.itemId,
          existingItem.uomId,
          existingItem.uom,
          existingItem.uomCost,
          existingItem.barcode,
        );
        cartProvider.updateItem(existingIndex, updatedItem);
      } else {
        cartProvider.addToCart(item);
      }
    }
    showTopToast('Items added to bin successfully');
    setState(() {
      itemList.clear();
    });
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Constants.primaryColor,
                ),
              )
            : _buildBody(
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
        onPressed: () async {
          if (itemList.isNotEmpty) {
            final shouldLeave = await showDialog<bool>(
              context: context,
              builder: (context) => const UnsavedChangesDialogWidget(),
            );
            if (shouldLeave ?? false) {
              Navigator.of(context).pop();
            }
          } else {
            Navigator.of(context).pop();
          }
        },
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
        decoration: const BoxDecoration(color: Constants.primaryColor),
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
      controller: _scrollController,
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductCard(
                  screenWidth,
                  screenHeight,
                  productDetailsProvider,
                  vendorDetailsProvider,
                  salesPersonDetailsProvider),
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
              _buildNotesSection(
                  screenWidth,
                  screenHeight,
                  _selectedReason != null &&
                      _selectedDate != null &&
                      _quantityController.text.isNotEmpty),
              SizedBox(height: screenHeight * 0.02),
              _buildAddToBinButton(screenWidth, screenHeight),
            ],
          ),
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
            heightFactor: 0.9,
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
                            SizedBox(height: 50.h),
                            const Text(
                              'No data found!',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      selectedUOM = item['UOM'];
                                      selectedUOMID = item['UOMId'];
                                      selectedUomItemID = item['ItemID'];
                                      selectedbarcode = item['productId'];
                                    });
                                    final productDetailsProvider =
                                        Provider.of<ProductDetailsProvider>(
                                            context,
                                            listen: false);
                                    productDetailsProvider.fetchcostbyUom(
                                        selectedUOMID.toString());
                                    setState(() {
                                      selectedUomCost =
                                          productDetailsProvider.uomcost;
                                    });
                                    productDetailsProvider
                                        .updateCostByUom(selectedUOMID);
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
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
                          Row(
                            children: [
                              Text(
                                'Customer : ',
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
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
                                      decorationColor: Colors.blue,
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
            showAlternativeUnits(context, productDetailsProvider.ItemId);
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
                                'BarCode: ${selectedbarcode == null ? (productDetailsProvider.barcode ?? "N/A") : selectedbarcode}',
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
                                      decorationColor: Colors.blue,
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
                              Text(
                                'Cost: ${productDetailsProvider.uomcost.toStringAsFixed(3) ?? "0.000"}',
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
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
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search vendor...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10.h),
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
                                  Navigator.pop(context, vendor);
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 6.h),
                                  padding: const EdgeInsets.all(12),
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
                                        offset: const Offset(0, 2),
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
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
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
                                            const SizedBox(height: 4),
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
                                        const Icon(Icons.check_circle,
                                            color: Colors.blue),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(child: Text('No vendors found')),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((selected) {
      if (selected != null) {
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
                          "${item.quantity} ${item.uom ?? "N/A"} $pickedDate",
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
                FocusScope.of(context).unfocus();
                if (_isQuantityValid && _selectedDate == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _selectDate(context);
                  });
                }
              },
              onChanged: (value) {
                setState(() {
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    _isQuantityValid = false;
                    _quantityController.clear();
                    showTopToast('Quantity must be a positive number');
                  } else {
                    _isQuantityValid = true;
                  }
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
              onChanged:
                  (_quantityController.text.isEmpty || _selectedDate == null)
                      ? null
                      : (value) {
                          setState(() {
                            _selectedReason = value;
                            _showReasonText = value == "Other";
                          });
                        },
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
  Widget _buildNotesSection(
      double screenWidth, double screenHeight, bool isEnabled) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isNotesChecked,
              activeColor: Constants.primaryColor,
              onChanged: (bool? value) {
                setState(() {
                  isNotesChecked = value ?? false;
                });
              },
            ),
            Text(
              "Add Notes",
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.034,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: isEnabled ? _addItemToList : null,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isEnabled ? Constants.primaryColor : Colors.grey.shade500,
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
        Visibility(
          visible: isNotesChecked,
          child: Column(
            children: [
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

// import 'dart:convert';
// import 'dart:developer';
// import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:merchandiser_clone/provider/create_request_vendor_detals.dart';
// import 'package:merchandiser_clone/provider/salesperson_provider.dart';
// import 'package:merchandiser_clone/screens/common_widget/toast.dart';
// import 'package:merchandiser_clone/screens/model/Vendors.dart';
// import 'package:merchandiser_clone/screens/model/vendor_and_salesperson_model.dart';
// import 'package:merchandiser_clone/screens/salesman_screens/model/merchendiser_api_service.dart';
// import 'package:merchandiser_clone/utils/constants.dart';
// import 'package:merchandiser_clone/utils/unsavedDialogue.dart';
// import 'package:merchandiser_clone/utils/urls.dart';
// import 'package:provider/provider.dart';
// import 'package:merchandiser_clone/provider/product_details_provider.dart';
// import 'package:merchandiser_clone/screens/splash_screen.dart';
// import 'package:merchandiser_clone/utils/dynamic_alert_box.dart';
// import 'package:merchandiser_clone/utils/willpop.dart';
// import 'package:merchandiser_clone/provider/cart_provider.dart';
// import 'package:http/http.dart' as http;

// // Model class for cart items
// class CartDetailsItem {
//   final String productName;
//   final String productIndex;
//   final int quantity;
//   final DateTime selectedDate;
//   final String note;
//   final String reason;
//   final dynamic itemId;
//   final String uomId;
//   dynamic uom;
//   final dynamic uomCost;
//   final dynamic cost;
//   final dynamic barcode;

//   CartDetailsItem(
//     this.uomCost,
//     this.productName,
//     this.productIndex,
//     this.quantity,
//     this.selectedDate,
//     this.note,
//     this.reason,
//     this.itemId,
//     this.uomId,
//     this.uom,
//     this.cost,
//     this.barcode,
//   );
// }

// class CartDetailsScreen extends StatefulWidget {
//   final int? vendorId;
//   final String? vendorName;
//   final String? salesManName;
//   final String? salesManId;
//   final String? uomId;
//   const CartDetailsScreen(
//       {super.key,
//       required this.uomId,
//       required this.salesManId,
//       required this.salesManName,
//       required this.vendorId,
//       required this.vendorName});

//   @override
//   State<CartDetailsScreen> createState() => _CartDetailsScreenState();
// }

// class _CartDetailsScreenState extends State<CartDetailsScreen> {
//   // Controllers
//   final TextEditingController _expiryDateController = TextEditingController();
//   final TextEditingController _quantityController = TextEditingController();
//   final TextEditingController _notesController = TextEditingController();
//   final TextEditingController _reasonTextController = TextEditingController();

//   // State variables
//   List<CartDetailsItem> itemList = [];
//   DateTime? _selectedDate;
//   late Willpop willpop;
//   bool _isQuantityValid = true;
//   bool _isExpiryDateValid = true;
//   String? _selectedReason;
//   bool _showReasonText = false;
//   List<Vendors> vendorList = [];
//   late Future<VendorAndSalesPersonModel> vendorData;
//   final MerchendiserApiService vendorapiService = MerchendiserApiService();

//   final MerchendiserApiService salesmanapiService = MerchendiserApiService();

//   List<SalesPerson> _allSalesPersons = [];
//   List<SalesPerson> _filteredSalesPersons = [];
//   String selectedCustomer = "";
//   bool _isExpanded = false;
//   String selectedSalesManName = "";
//   int? selectedSalesPersonId;
//   // Vendors? selectedVendor;
//   String selectedUOM = "";
//   dynamic selectedUOMID = 0;
//   dynamic selectedbarcode = null;
//   dynamic selectedUomCost = 0;
//   dynamic selectedUomItemID = null;

//   late Future<VendorAndSalesPersonModel> salesmanData;
//   @override
//   void initState() {
//     super.initState();
//     willpop = Willpop(context);
//     _fetchLastSalesPrice();

//     fetchVendors();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       var vendorDetailsProvider =
//           Provider.of<CreateRequestVendorDetailsProvider>(
//         context,
//         listen: false,
//       );
//       var productdetailsprovider = Provider.of<ProductDetailsProvider>(
//         context,
//         listen: false,
//       );

//       productdetailsprovider.setSelectedVendor(
//           vendorDetailsProvider.getVendor(), context);
//       // productdetailsprovider.fetchcostbyUom(widget.uomId.toString());
//     });
//   }

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

//   @override
//   void dispose() {
//     _quantityController.dispose();
//     _expiryDateController.dispose();
//     _notesController.dispose();
//     _reasonTextController.dispose();
//     super.dispose();
//   }

//   // Fetch last sales price from API
//   Future<void> _fetchLastSalesPrice() async {
//     final productDetailsProvider =
//         Provider.of<ProductDetailsProvider>(context, listen: false);

//     final itemID = productDetailsProvider.ItemId ?? '';
//     log('Item ID selected Product: $itemID');
//     try {
//       final response = await http.get(
//         Uri.parse(Urls.getLastSalesPrice),
//         headers: {'itemID': itemID.toString()},
//       );

//       if (response.statusCode == 200) {
//         log('response from api : ${response.body}');
//         final responseData = json.decode(response.body);
//         final List<dynamic> data = responseData['data'] ?? [];

//         if (data.isNotEmpty) {
//           final List<Map<String, dynamic>> formattedList =
//               List<Map<String, dynamic>>.from(data);
//           productDetailsProvider.setSalesPriceList(formattedList);
//           productDetailsProvider.fetchcostbyUom(widget.uomId.toString());
//           log('Last sales price data: $formattedList');

//           // Default to selectedUOMID if available
//           final currentUomId =
//               selectedUOMID != 0 ? selectedUOMID : productDetailsProvider.UOMId;

//           // productDetailsProvider.updateCostByUom(currentUomId);
//         }
//       } else {
//         showTopToast('Failed to fetch price: ${response.statusCode}');
//         log('Failed to fetch price: ${response.statusCode}');
//       }
//     } catch (e) {
//       showTopToast('Error fetching price: $e');
//     }
//   }

//   // Select expiry date
//   Future<void> _selectDate(BuildContext context) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1990),
//       lastDate: DateTime(DateTime.now().year + 10),
//     );

//     if (picked != null) {
//       setState(() {
//         _selectedDate = picked;
//         _expiryDateController.text = picked.toLocal().toString().split(' ')[0];
//         _isExpiryDateValid = true;
//         if (picked.isBefore(DateTime.now())) {
//           _selectedReason = "EXPIRED GOODS";
//           _showReasonText = false;
//         } else {
//           _selectedReason = null;
//           _showReasonText = false;
//         }
//       });
//     }
//   }

//   // Add this method to your _CartDetailsScreenState class
//   int _findExistingItemIndex(CartDetailsItem newItem) {
//     for (int i = 0; i < itemList.length; i++) {
//       final existingItem = itemList[i];
//       if (existingItem.barcode == newItem.barcode &&
//           existingItem.uomId == newItem.uomId &&
//           DateFormat('yyyy-MM-dd').format(existingItem.selectedDate) ==
//               DateFormat('yyyy-MM-dd').format(newItem.selectedDate)) {
//         return i; // Return index if match found
//       }
//     }
//     return -1; // Return -1 if no match
//   }

//   // Add item to the list
//   void _addItemToList() {
//     final productDetailsProvider =
//         Provider.of<ProductDetailsProvider>(context, listen: false);
//     bool isValid = true;

//     // Validate inputs
//     if (_quantityController.text.isEmpty) {
//       _isQuantityValid = false;
//       isValid = false;
//     }
//     if (_selectedDate == null) {
//       _isExpiryDateValid = false;
//       isValid = false;
//     }

//     if (!isValid) {
//       setState(() {});
//       return;
//     }

//     final quantity = int.parse(_quantityController.text);
//     final newItem = CartDetailsItem(
//       selectedUomCost != 0 ? selectedUomCost : productDetailsProvider.uomcost,
//       productDetailsProvider.productName ?? '',
//       selectedUomItemID != 0
//           ? selectedUomItemID.toString()
//           : productDetailsProvider.productId?.toString() ?? '',
//       quantity,
//       _selectedDate!,
//       _notesController.text,
//       _selectedReason ?? (_showReasonText ? _reasonTextController.text : ''),
//       productDetailsProvider.ItemId,
//       selectedUOMID.toString() != '0'
//           ? selectedUOMID.toString()
//           : productDetailsProvider.UOMId.toString(),
//       selectedUOM.isNotEmpty ? selectedUOM : productDetailsProvider.UOM ?? '',
//       selectedUomCost != 0 ? selectedUomCost : productDetailsProvider.uomcost,
//       selectedbarcode ?? productDetailsProvider.barcode,
//     );

//     // Check if item already exists
//     final existingIndex = _findExistingItemIndex(newItem);

//     setState(() {
//       if (existingIndex != -1) {
//         // Update quantity of existing item
//         final existingItem = itemList[existingIndex];
//         itemList[existingIndex] = CartDetailsItem(
//           existingItem.uomCost,
//           existingItem.productName,
//           existingItem.productIndex,
//           existingItem.quantity + newItem.quantity, // Add quantities
//           existingItem.selectedDate,
//           _notesController.text.isNotEmpty
//               ? _notesController.text
//               : existingItem.note, // Keep existing note if new one is empty
//           _selectedReason ?? existingItem.reason,
//           existingItem.itemId,
//           existingItem.uomId,
//           existingItem.uom,
//           existingItem.uomCost,
//           existingItem.barcode,
//         );
//         showTopToast('Quantity updated for existing item');
//       } else {
//         // Add new item
//         itemList.add(newItem);
//         showTopToast('New item added to list');
//       }

//       setState(() {
//         _quantityController.clear();
//         _selectedDate = null;
//         _notesController.clear();
//         _reasonTextController.clear();
//         _selectedReason = null;
//         _showReasonText = false;
//         _isQuantityValid = true;
//         _isExpiryDateValid = true;
//         selectedUOM = productDetailsProvider.UOM ?? "";
//         selectedUOMID = productDetailsProvider.UOMId ?? "";
//         selectedbarcode = productDetailsProvider.barcode;
//         selectedUomCost = productDetailsProvider.uomcost;
//         selectedUomItemID = productDetailsProvider.ItemId;
//       });
//     });
//   }

//   // Remove item from the list
//   void _removeItemFromList(int index) {
//     setState(() {
//       itemList.removeAt(index);
//     });
//   }

//   // Add items to cart
//   void _addToCart() {
//     if (itemList.isEmpty) {
//       showTopToast('No items to add to cart');
//       return;
//     }

//     final cartProvider = Provider.of<CartProvider>(context, listen: false);

//     for (final item in itemList) {
//       final existingIndex = cartProvider.cartItems.indexWhere((cartItem) =>
//           cartItem.barcode == item.barcode &&
//           cartItem.uomId == item.uomId &&
//           DateFormat('yyyy-MM-dd').format(cartItem.selectedDate) ==
//               DateFormat('yyyy-MM-dd').format(item.selectedDate));

//       if (existingIndex != -1) {
//         // Update quantity
//         final existingItem = cartProvider.cartItems[existingIndex];
//         final updatedItem = CartDetailsItem(
//           existingItem.uomCost,
//           existingItem.productName,
//           existingItem.productIndex,
//           existingItem.quantity + item.quantity,
//           existingItem.selectedDate,
//           item.note.isNotEmpty ? item.note : existingItem.note,
//           item.reason.isNotEmpty ? item.reason : existingItem.reason,
//           existingItem.itemId,
//           existingItem.uomId,
//           existingItem.uom,
//           existingItem.uomCost,
//           existingItem.barcode,
//         );

//         cartProvider.updateItem(existingIndex, updatedItem);
//       } else {
//         // Add new item
//         cartProvider.addToCart(item);
//       }
//     }

//     showTopToast('Items added to bin successfully');
//     setState(() {
//       itemList.clear();
//     });
//   }

//   // Show add-to-cart confirmation dialog
//   void _showAddToCartDialog(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             "Do you want to add to bin?",
//             style: GoogleFonts.poppins(fontSize: screenWidth * 0.045),
//           ),
//           actions: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 TextButton(
//                   onPressed: () {
//                     _addToCart();
//                     Navigator.of(context).pop();
//                     Navigator.of(context).pop();
//                   },
//                   style: ButtonStyle(
//                     side: MaterialStateProperty.all(
//                         const BorderSide(color: Colors.blue)),
//                   ),
//                   child: Text(
//                     "Yes",
//                     style: GoogleFonts.poppins(fontSize: screenWidth * 0.04),
//                   ),
//                 ),
//                 SizedBox(width: screenWidth * 0.02),
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   style: ButtonStyle(
//                     side: MaterialStateProperty.all(
//                         const BorderSide(color: Colors.blue)),
//                   ),
//                   child: Text(
//                     "No",
//                     style: GoogleFonts.poppins(fontSize: screenWidth * 0.04),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final productDetailsProvider = Provider.of<ProductDetailsProvider>(context);
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     var salesPersonDetailsProvider = Provider.of<SalesPersonDetailsProvider>(
//       context,
//     );
//     var vendorDetailsProvider = Provider.of<CreateRequestVendorDetailsProvider>(
//       context,
//     );
//     return WillPopScope(
//       onWillPop: () async => Future.value(willpop.onWillPop()),
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         appBar: _buildAppBar(context, screenWidth),
//         body: isLoading
//             ? const Center(
//                 child: CircularProgressIndicator(
//                   color: Constants.primaryColor,
//                 ),
//               )
//             : _buildBody(
//                 context,
//                 screenWidth,
//                 screenHeight,
//                 productDetailsProvider,
//                 vendorDetailsProvider,
//                 salesPersonDetailsProvider),
//       ),
//     );
//   }

//   // Build AppBar
//   AppBar _buildAppBar(BuildContext context, double screenWidth) {
//     return AppBar(
//       automaticallyImplyLeading: false,
//       leading: IconButton(
//         onPressed: () async {
//           if (itemList.isNotEmpty) {
//             final shouldLeave = await showDialog<bool>(
//               context: context,
//               builder: (context) => const UnsavedChangesDialogWidget(),
//             );

//             if (shouldLeave ?? false) {
//               Navigator.of(context).pop();
//             }
//           } else {
//             Navigator.of(context).pop();
//           }
//         },
//         icon: Icon(
//           Icons.arrow_back,
//           color: Colors.white,
//           size: screenWidth * 0.06,
//         ),
//       ),
//       title: Text(
//         "Product Expiry Details",
//         style: GoogleFonts.poppins(
//           fontWeight: FontWeight.w600,
//           color: Colors.white,
//           fontSize: screenWidth * 0.04,
//         ),
//       ),
//       centerTitle: true,
//       actions: [
//         Padding(
//           padding: EdgeInsets.only(right: screenWidth * 0.04, bottom: 10.h),
//           child: GestureDetector(
//             onTap: () {
//               DynamicAlertBox().logOut(
//                 context,
//                 "Do you want to logout?",
//                 () => Navigator.of(context).pushReplacement(
//                   MaterialPageRoute(builder: (context) => const SplashScreen()),
//                 ),
//               );
//             },
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               radius: screenWidth * 0.06,
//               child: const Text("MR"),
//             ),
//           ),
//         ),
//       ],
//       flexibleSpace: Container(
//         decoration: const BoxDecoration(color: Constants.primaryColor),
//       ),
//     );
//   }

//   // Build Body

//   Widget _buildBody(
//       BuildContext context,
//       double screenWidth,
//       double screenHeight,
//       ProductDetailsProvider productDetailsProvider,
//       CreateRequestVendorDetailsProvider vendorDetailsProvider,
//       SalesPersonDetailsProvider salesPersonDetailsProvider) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(screenWidth * 0.04),
//       child: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildProductCard(screenWidth, screenHeight, productDetailsProvider,
//                 vendorDetailsProvider, salesPersonDetailsProvider),
//             SizedBox(height: screenHeight * 0.001),
//             _buildAddedItemsSection(
//                 screenWidth, screenHeight, productDetailsProvider),
//             SizedBox(height: screenHeight * 0.02),
//             _buildQuantityAndDateInputs(screenWidth, screenHeight),
//             SizedBox(height: screenHeight * 0.02),
//             _buildReasonSection(screenWidth, screenHeight),
//             if (_showReasonText) SizedBox(height: screenHeight * 0.02),
//             if (_showReasonText)
//               _buildCustomReasonInput(screenWidth, screenHeight),
//             SizedBox(height: screenHeight * 0.02),
//             _buildNotesSection(
//                 screenWidth,
//                 screenHeight,
//                 _selectedReason != null &&
//                     _selectedDate != null &&
//                     _quantityController.text.isNotEmpty),
//             SizedBox(height: screenHeight * 0.02),
//             _buildAddToBinButton(screenWidth, screenHeight),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> showAlternativeUnits(
//     BuildContext context,
//     dynamic itemID,
//   ) async {
//     try {
//       List<dynamic> data = await vendorapiService.fetchAlternativeUnits(itemID);
//       showModalBottomSheet(
//         context: context,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
//         ),
//         backgroundColor: Colors.white,
//         builder: (context) {
//           return FractionallySizedBox(
//             heightFactor: 0.9, // Adjust the height as needed
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Padding(
//                     padding: EdgeInsets.all(16.0),
//                     child: Text(
//                       'Alternative Units',
//                       style: TextStyle(
//                         fontSize: 18.0,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const Divider(thickness: 1.0),
//                   data.isEmpty
//                       ? Column(
//                           children: [
//                             SizedBox(
//                               height: 50.h,
//                             ),
//                             const Text(
//                               'No data found!',
//                               style: TextStyle(
//                                 fontSize: 16.0,
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//                           ],
//                         )
//                       : Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: ListView.builder(
//                             shrinkWrap:
//                                 true, // Ensure ListView takes minimal space
//                             physics:
//                                 const NeverScrollableScrollPhysics(), // Disable scrolling in ListView
//                             itemCount: data.length,
//                             itemBuilder: (context, itemIndex) {
//                               var item = data[itemIndex];
//                               return Card(
//                                 margin:
//                                     const EdgeInsets.symmetric(vertical: 8.0),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(15.0),
//                                 ),
//                                 elevation: 3,
//                                 child: ListTile(
//                                   contentPadding: const EdgeInsets.all(16.0),
//                                   title: Text(
//                                     item['productName'],
//                                     style: const TextStyle(
//                                       fontSize: 16.0,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   subtitle: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       const SizedBox(height: 8.0),
//                                       Text(
//                                         'Barcode : ${item['productId']}',
//                                         style:
//                                             TextStyle(color: Colors.grey[700]),
//                                       ),
//                                       Text(
//                                         'UOM : ${item['UOM']}',
//                                         style: const TextStyle(
//                                             color: Colors.green),
//                                       ),
//                                       // Text(
//                                       //   'Price : ${item['Cost']}',
//                                       //   style:
//                                       //       TextStyle(color: Colors.grey[700]),
//                                       // ),
//                                     ],
//                                   ),
//                                   onTap: () {
//                                     setState(() {
//                                       selectedUOM = item['UOM'];
//                                       selectedUOMID = item['UOMId'];
//                                       // selectedUomCost = item['Cost'];
//                                       selectedUomItemID = item['ItemID'];
//                                       selectedbarcode = item['productId'];
//                                     });
//                                     final productDetailsProvider =
//                                         Provider.of<ProductDetailsProvider>(
//                                             context,
//                                             listen: false);
//                                     productDetailsProvider.fetchcostbyUom(
//                                         selectedUOMID.toString());
//                                     setState(() {
//                                       selectedUomCost =
//                                           productDetailsProvider.uomcost;
//                                     });
//                                     productDetailsProvider
//                                         .updateCostByUom(selectedUOMID);
//                                     Navigator.pop(context);
//                                   },
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     } catch (error) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(error.toString())));
//     }
//   }

//   // Product Details Card
//   Widget _buildProductCard(
//       double screenWidth,
//       double screenHeight,
//       ProductDetailsProvider productDetailsProvider,
//       CreateRequestVendorDetailsProvider vendorDetailsProvider,
//       SalesPersonDetailsProvider salesPersonDetailsProvider) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Card(
//               shape: RoundedRectangleBorder(
//                 side: BorderSide(width: 0.4, color: Colors.grey.shade200),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               elevation: 0.4,
//               child: Padding(
//                 padding: EdgeInsets.all(screenWidth * 0.024),
//                 child: Container(
//                   width: screenWidth * 0.85,
//                   child: Row(
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Text(
//                                 'Customer : ',
//                                 style: GoogleFonts.poppins(
//                                   fontSize: screenWidth * 0.035,
//                                   fontWeight: FontWeight.w700,
//                                   color: Colors.black,
//                                 ),
//                               ),
//                               GestureDetector(
//                                 onTap: () {
//                                   showVendorSelectionSheet(
//                                       context,
//                                       productDetailsProvider,
//                                       vendorDetailsProvider,
//                                       salesPersonDetailsProvider);
//                                 },
//                                 child: SizedBox(
//                                   width: screenWidth * .6,
//                                   child: Text(
//                                     '${productDetailsProvider.selectedVendor == null ? vendorDetailsProvider.vendorName : productDetailsProvider.selectedVendor!.vendorName ?? 'Unknown'}',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: screenWidth * 0.035,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.blue,
//                                       decoration: TextDecoration.underline,
//                                       decorationColor:
//                                           Colors.blue, // Underline color
//                                       decorationThickness: 2,
//                                     ),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 2.h),
//                           Text(
//                             selectedSalesManName.isEmpty
//                                 ? 'Sales person:  ${salesPersonDetailsProvider.salesManName ?? "Unknown"}'
//                                 : 'Sales person:  ${selectedSalesManName}',
//                             style: GoogleFonts.poppins(
//                               fontSize: screenWidth * 0.035,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         GestureDetector(
//           onTap: () {
//             showAlternativeUnits(
//               context,
//               productDetailsProvider.ItemId,
//             );
//           },
//           child: Card(
//             shape: RoundedRectangleBorder(
//               side: BorderSide(width: 0.4, color: Colors.grey.shade200),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             elevation: 0.4,
//             child: Padding(
//               padding: EdgeInsets.all(screenWidth * 0.024),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     productDetailsProvider.productName ?? "Unknown Product",
//                     style: GoogleFonts.poppins(
//                       fontSize: screenWidth * 0.037,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.grey.shade800,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 2,
//                   ),
//                   SizedBox(height: screenHeight * 0.01),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Text(
//                                 'BarCode: ${selectedbarcode == null ? (productDetailsProvider.barcode ?? "N/A") : selectedbarcode}',
//                                 style: GoogleFonts.poppins(
//                                   fontSize: screenWidth * 0.035,
//                                   fontWeight: FontWeight.w500,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               SizedBox(width: screenWidth * 0.1),
//                               Row(
//                                 children: [
//                                   Text(
//                                     'UOM: ',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: screenWidth * 0.035,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                   Text(
//                                     selectedUOM.isEmpty
//                                         ? '${productDetailsProvider.UOM ?? "N/A"}'
//                                         : '${selectedUOM ?? "N/A"}',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: screenWidth * 0.035,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.blue,
//                                       decoration: TextDecoration.underline,
//                                       decorationColor:
//                                           Colors.blue, // Underline color
//                                       decorationThickness: 2,
//                                     ),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: screenHeight * 0.005),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Cost: ${productDetailsProvider.uomcost.toStringAsFixed(3) ?? "0.000"}',
//                                 style: GoogleFonts.poppins(
//                                   fontSize: screenWidth * 0.035,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.green,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   showVendorSelectionSheet(
//       BuildContext context,
//       ProductDetailsProvider productDetailsProvider,
//       CreateRequestVendorDetailsProvider vendorprovider,
//       SalesPersonDetailsProvider salesmanprovider) {
//     TextEditingController searchController = TextEditingController();
//     List<Vendors> filteredVendors = List.from(vendorList);

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return Container(
//               padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
//               height: MediaQuery.of(context).size.height * 0.9,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius:
//                     const BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               child: Column(
//                 children: [
//                   // Search Bar
//                   TextField(
//                     controller: searchController,
//                     onChanged: (value) {
//                       setState(() {
//                         filteredVendors = vendorList
//                             .where((vendor) => vendor.vendorName
//                                 .toLowerCase()
//                                 .contains(value.toLowerCase()))
//                             .toList();
//                       });
//                     },
//                     decoration: InputDecoration(
//                       prefixIcon: const Icon(Icons.search),
//                       hintText: 'Search vendor...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       filled: true,
//                       fillColor: Colors.white,
//                     ),
//                   ),
//                   SizedBox(height: 10.h),
//                   // List
//                   Expanded(
//                     child: filteredVendors.isNotEmpty
//                         ? ListView.builder(
//                             itemCount: filteredVendors.length,
//                             itemBuilder: (context, index) {
//                               final vendor = filteredVendors[index];
//                               final isSelected = vendor ==
//                                   productDetailsProvider.selectedVendor;

//                               return GestureDetector(
//                                 onTap: () {
//                                   salesmanprovider.setSalesPersonDetails(
//                                       vendor.salesPersonName,
//                                       vendor.salesPerson,
//                                       "");

//                                   vendorprovider.setVendorDetails(
//                                       vendor.vendorId,
//                                       vendor.vendorName,
//                                       vendor.salesPerson,
//                                       vendor.salesPersonName,
//                                       vendor.mobileNo);
//                                   productDetailsProvider.setSelectedVendor(
//                                       vendor, context);
//                                   selectedSalesManName =
//                                       vendor.salesPersonName.toString();
//                                   // _fetchSalesmanData(vendor.vendorId);
//                                   Navigator.pop(
//                                       context, vendor); // Return on tap
//                                 },
//                                 child: Container(
//                                   margin: EdgeInsets.symmetric(vertical: 6.h),
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: isSelected
//                                         ? Colors.blue.shade100
//                                         : Colors.white,
//                                     borderRadius: BorderRadius.circular(15),
//                                     border: Border.all(
//                                         color: isSelected
//                                             ? Colors.blue
//                                             : Colors.grey.shade300),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.grey.withOpacity(0.1),
//                                         blurRadius: 4,
//                                         offset: const Offset(0, 2),
//                                       ),
//                                     ],
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       CircleAvatar(
//                                         backgroundColor: Constants.primaryColor,
//                                         child: Text(
//                                           vendor.vendorName.isNotEmpty
//                                               ? vendor.vendorName[0]
//                                               : '',
//                                           style: const TextStyle(
//                                               color: Colors.white),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 12),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               vendor.vendorName,
//                                               style: TextStyle(
//                                                 fontSize: 16.sp,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               'Code: ${vendor.vendorCode}',
//                                               style: TextStyle(
//                                                   fontSize: 13.sp,
//                                                   color: Colors.grey.shade600),
//                                             ),
//                                             Text(
//                                               'Mobile: ${vendor.mobileNo}',
//                                               style: TextStyle(
//                                                   fontSize: 13.sp,
//                                                   color: Colors.grey.shade600),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       if (isSelected)
//                                         const Icon(Icons.check_circle,
//                                             color: Colors.blue),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           )
//                         : const Center(child: Text('No vendors found')),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     ).then((selected) {
//       if (selected != null) {
//         // Use the selected vendor
//         print("Selected Vendor: ${selected.vendorName}");
//       }
//     });
//   }

//   // Added Items Section
//   Widget _buildAddedItemsSection(
//     double screenWidth,
//     double screenHeight,
//     ProductDetailsProvider productDetailsProvider,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (itemList.isNotEmpty)
//           Text(
//             "Added Items",
//             style: GoogleFonts.poppins(
//               fontSize: screenWidth * 0.034,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey.shade800,
//             ),
//           ),
//         if (itemList.isNotEmpty) SizedBox(height: screenHeight * 0.01),
//         if (itemList.isNotEmpty)
//           Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.transparent),
//             ),
//             child: DynamicHeightGridView(
//               physics: const NeverScrollableScrollPhysics(),
//               shrinkWrap: true,
//               itemCount: itemList.length,
//               crossAxisCount: 2,
//               crossAxisSpacing: screenWidth * 0.03,
//               mainAxisSpacing: screenWidth * 0.03,
//               builder: (ctx, index) {
//                 final item = itemList[index];
//                 final pickedDate =
//                     DateFormat('dd/MM/yyyy').format(item.selectedDate);

//                 return Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(),
//                     borderRadius: BorderRadius.circular(screenWidth * 0.02),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.all(screenWidth * 0.02),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "${item.quantity} ${item.uom ?? "N/A"} $pickedDate",
//                           style:
//                               GoogleFonts.poppins(fontSize: screenWidth * 0.03),
//                         ),
//                         InkWell(
//                           onTap: () => _removeItemFromList(index),
//                           child: Icon(Icons.close, size: screenWidth * 0.04),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//       ],
//     );
//   }

//   // Quantity and Expiry Date Inputs
//   Widget _buildQuantityAndDateInputs(double screenWidth, double screenHeight) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(
//           "Qty",
//           style: GoogleFonts.poppins(
//             fontSize: screenWidth * 0.034,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         SizedBox(width: 10.w),
//         SizedBox(
//           height: 40.h,
//           width: screenWidth * 0.25,
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                   color: _isQuantityValid ? Colors.grey : Colors.red),
//             ),
//             child: TextFormField(
//               style: GoogleFonts.poppins(
//                 color: Colors.grey.shade900,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 12.sp,
//               ),
//               keyboardType: TextInputType.number,
//               controller: _quantityController,
//               decoration: InputDecoration(
//                 hintText: "qty",
//                 hintStyle: GoogleFonts.poppins(
//                   color: Colors.grey.shade600,
//                   fontWeight: FontWeight.w500,
//                   fontSize: 10.sp,
//                 ),
//                 border: InputBorder.none,
//               ),
//               onEditingComplete: () {
//                 if (_isQuantityValid && _selectedDate == null) {
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     _selectDate(context);
//                   });
//                 }
//               },
//               onChanged: (value) {
//                 setState(() {
//                   // Disallow negative quantities or zero
//                   final parsed = int.tryParse(value);
//                   if (parsed == null || parsed <= 0) {
//                     _isQuantityValid = false;
//                     _quantityController
//                         .clear(); // optional: clear invalid input
//                     showTopToast('Quantity must be a positive number');
//                   } else {
//                     _isQuantityValid = true;
//                   }
//                 });
//               },
//             ),
//           ),
//         ),
//         SizedBox(width: 15.w),
//         Text(
//           "Exp\nDate",
//           style: GoogleFonts.poppins(
//             fontSize: screenWidth * 0.034,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         SizedBox(width: 10.w),
//         SizedBox(
//           width: screenWidth * 0.42,
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                   color: _isExpiryDateValid ? Colors.grey : Colors.red),
//             ),
//             child: TextButton(
//               onPressed: () => _selectDate(context),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   _selectedDate == null
//                       ? "Select Date"
//                       : DateFormat('dd/MM/yyyy').format(_selectedDate!),
//                   style: GoogleFonts.poppins(
//                     fontWeight: _selectedDate == null
//                         ? FontWeight.w500
//                         : FontWeight.w600,
//                     color: _selectedDate == null
//                         ? Colors.grey.shade700
//                         : Colors.grey.shade900,
//                     fontSize: _selectedDate == null ? 10.sp : 12.sp,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Reason Selection
//   Widget _buildReasonSection(double screenWidth, double screenHeight) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(
//           "Reason",
//           style: GoogleFonts.poppins(
//             fontSize: screenWidth * 0.034,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const Spacer(),
//         SizedBox(
//           width: screenWidth * 0.74,
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.grey),
//             ),
//             child: DropdownButtonFormField<String>(
//               decoration: const InputDecoration(border: InputBorder.none),
//               hint: Text(
//                 "Select Reason",
//                 style: GoogleFonts.poppins(
//                   color: Colors.grey.shade600,
//                   fontWeight: FontWeight.w500,
//                   fontSize: 12.sp,
//                 ),
//               ),
//               value: _selectedReason,
//               items: const [
//                 DropdownMenuItem(
//                     value: "EXCESS STOCK", child: Text("Excess Stock")),
//                 DropdownMenuItem(
//                     value: "EXPIRED GOODS", child: Text("Expired Goods")),
//                 DropdownMenuItem(
//                     value: "NEAR EXPIRY GOODS",
//                     child: Text("Near Expiry Goods")),
//                 DropdownMenuItem(value: "DAMAGE", child: Text("Damage")),
//                 DropdownMenuItem(
//                     value: "PROMO RETURNS", child: Text("Promo Returns")),
//                 DropdownMenuItem(value: "Other", child: Text("Other")),
//               ],
//               onChanged: (
//                       // _selectedReason == "EXPIRED GOODS" ||
//                       _quantityController.text.isEmpty || _selectedDate == null)
//                   ? null
//                   : (value) {
//                       setState(() {
//                         _selectedReason = value;
//                         _showReasonText = value == "Other";
//                       });
//                     },
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Custom Reason Input
//   Widget _buildCustomReasonInput(double screenWidth, double screenHeight) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Please specify reason",
//           style: GoogleFonts.poppins(
//             fontSize: screenWidth * 0.045,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//         SizedBox(height: screenHeight * 0.01),
//         Container(
//           padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.grey),
//           ),
//           child: TextFormField(
//             controller: _reasonTextController,
//             decoration: const InputDecoration(
//               hintText: "Reason here...",
//               border: InputBorder.none,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Notes Section with Add Button
//   Widget _buildNotesSection(
//       double screenWidth, double screenHeight, bool isEnabled) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               "Notes",
//               style: GoogleFonts.poppins(
//                 fontSize: screenWidth * 0.034,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const Spacer(),
//             GestureDetector(
//               onTap: isEnabled ? _addItemToList : null,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color:
//                       isEnabled ? Constants.primaryColor : Colors.grey.shade500,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding:
//                       const EdgeInsets.symmetric(vertical: 6, horizontal: 25),
//                   child: Row(
//                     children: [
//                       Text(
//                         'Add',
//                         style: GoogleFonts.poppins(
//                           fontSize: screenWidth * 0.028,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.white,
//                         ),
//                       ),
//                       Icon(Icons.add, size: 16.sp, color: Colors.white),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: screenHeight * 0.016),
//         Container(
//           padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.grey),
//           ),
//           child: TextFormField(
//             maxLines: 3,
//             keyboardType: TextInputType.multiline,
//             controller: _notesController,
//             decoration: InputDecoration(
//               hintStyle: GoogleFonts.poppins(
//                 color: Colors.grey.shade600,
//                 fontWeight: FontWeight.w500,
//                 fontSize: 12.sp,
//               ),
//               hintText: "Write some notes about the product",
//               border: InputBorder.none,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Add to Bin Button
//   Widget _buildAddToBinButton(double screenWidth, double screenHeight) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//           horizontal: screenWidth * 0.01, vertical: screenHeight * 0.012),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           onPressed:
//               itemList.isEmpty ? null : () => _showAddToCartDialog(context),
//           style: ElevatedButton.styleFrom(
//             backgroundColor:
//                 itemList.isEmpty ? Colors.grey.shade700 : Constants.buttonColor,
//             // const Color.fromARGB(255, 132, 23, 152),
//             padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           child: Text(
//             "Add to Bin",
//             style: GoogleFonts.poppins(
//               color: Colors.white,
//               fontSize: screenWidth * 0.04,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
