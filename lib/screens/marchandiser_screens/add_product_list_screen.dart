// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:merchandiser_clone/provider/cart_provider.dart';
import 'package:merchandiser_clone/provider/product_details_provider.dart';
import 'package:merchandiser_clone/screens/marchandiser_screens/create_request_screen.dart';
import 'package:merchandiser_clone/screens/salesman_screens/model/merchendiser_api_service.dart';
import 'package:merchandiser_clone/screens/marchandiser_screens/cart_details_screen.dart';
import 'package:merchandiser_clone/screens/marchandiser_screens/cart_screen.dart';
import 'package:merchandiser_clone/screens/model/product_and_categories_model.dart';
import 'package:merchandiser_clone/screens/splash_screen.dart';
import 'package:merchandiser_clone/utils/QRScannerWidget.dart';
import 'package:merchandiser_clone/utils/constants.dart';
import 'package:merchandiser_clone/utils/dynamic_alert_box.dart';
import 'package:merchandiser_clone/utils/willpop.dart';

// Model for Product Details
class ProductDetails {
  final String productName;
  final String productId;

  ProductDetails({required this.productName, required this.productId});
}

// Main Stateful Widget
class AddProductListViewScreen extends StatefulWidget {
  final int? vendorId;
  final String? vendorName;
  final String? salesManName;
  final String? salesManId;

  const AddProductListViewScreen({
    Key? key,
    this.vendorId,
    this.vendorName,
    this.salesManName,
    this.salesManId,
  }) : super(key: key);

  @override
  State<AddProductListViewScreen> createState() =>
      _AddProductListViewScreenState();
}

class _AddProductListViewScreenState extends State<AddProductListViewScreen> {
  // Controllers and Services
  final TextEditingController _searchController = TextEditingController();
  final MerchendiserApiService _apiService = MerchendiserApiService();
  late Willpop _willpop;

  // State Variables
  late Future<ProductAndCategoriesModel> _productAndCategories;
  List<Category> _categories = [];
  List<String> _selectedCategories = [];
  List<int> _selectedCategoryIds = [];
  String _selectedProductName = '';
  String _selectedProductId = '';
  String _selectedUOM = '';
  dynamic _selectedUOMId = '';
  double _selectedCost = 0.0;
  dynamic _selectedItemID = '';
  dynamic _selectedBarcode = '';
  int? _infoButtonClickedIndex;
  dynamic _selectedUomCost = 0.0;

  @override
  void initState() {
    super.initState();
    _willpop = Willpop(context);
    _fetchInitialData();
  }

  // Fetch initial product and category data
  void _fetchInitialData() {
    _productAndCategories = _apiService.getProductAndCategories(
      flag: 100,
      pageNo: 1,
      vendorId: widget.vendorId ?? 1,
      filterText: '',
    );
    _productAndCategories.then((data) {
      if (!mounted) return;
      setState(() {
        _categories = data.data.categories;
      });
    });
  }

  // Refresh product list
  Future<void> _refresh() async {
    _productAndCategories = _apiService.getProductAndCategories(
      flag: 100,
      pageNo: 1,
      vendorId: widget.vendorId ?? 1,
      filterText: '',
    );
    log("Product data fetched: ${_productAndCategories.toString()}");
    _productAndCategories.then((data) {
      if (!mounted) return;
      setState(() {
        _categories = data.data.categories;
      });
    });
  }

  // Update selected category IDs
  void _updateSelectedCategories() {
    setState(() {
      _selectedCategoryIds = _selectedCategories
          .map((categoryName) {
            try {
              final category = _categories.firstWhere(
                (category) => category.grpName == categoryName,
                orElse: () => Category(grpId: -1, grpName: ''),
              );
              return category.grpId;
            } catch (e) {
              log("Error finding category: $categoryName, Error: $e");
              return -1;
            }
          })
          .where((id) => id != -1)
          .toList();
      log("Updated Selected Categories: $_selectedCategories");
      log("Updated Selected Category IDs: $_selectedCategoryIds");
    });
    _applyFilters();
  }

  // Apply filters based on search and selected categories
  Future<void> _applyFilters() async {
    log("Applying filters with search: ${_searchController.text} ${_selectedCategoryIds}, categories: $_selectedCategoryIds");
    try {
      final result = await _apiService.getProductAndCategories(
        flag: 101,
        pageNo: 1,
        vendorId: widget.vendorId ?? 1,
        filterText: _searchController.text,
        selectedCategoryIds:
            _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
      );
      log("API Response: ${result.data.products.length} products found");
      if (!mounted) return;
      setState(() {
        _productAndCategories = Future.value(result);
      });
    } catch (e) {
      log("Error applying filters: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to apply filters: $e")),
      );
    }
  }

  // Show alternative units bottom sheet
  Future<void> _showAlternativeUnits(
      BuildContext context, dynamic itemID, int index) async {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      List<dynamic> data = await _apiService.fetchAlternativeUnits(itemID);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        backgroundColor: Colors.white,
        builder: (context) => _AlternativeUnitsBottomSheet(
          data: data,
          onItemSelected: (item) {
            setState(() {
              _selectedProductName = item['productName'];
              _selectedProductId = item['productId'];
              _selectedUOM = item['UOM'];
              _selectedUOMId = item['UOMId'];
              _selectedCost = item['Cost'];
              _selectedItemID = item['ItemID'];
              _selectedBarcode = item['Barcode'];
              _selectedUomCost = item['uomCost'];
              _selectedUOMId = item['UOMId'];
              _infoButtonClickedIndex = index;
            });
          },
          cartProvider: cartProvider, // Pass the cartProvider
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  // Scan QR code and handle the result
  void _scanQrCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => QRScannerWidget(
        onScan: (String scannedData) async {
          Navigator.pop(context);
          if (scannedData.isNotEmpty) {
            _searchController.text = scannedData;
            try {
              ProductAndCategoriesModel response =
                  await _apiService.getProductAndCategories(
                flag: 101,
                pageNo: 1,
                vendorId: widget.vendorId ?? 1,
                filterText: _searchController.text,
              );
              if (response.data.products == null ||
                  response.data.products!.isEmpty) {
                _showNoProductFoundPopup();
              } else {
                setState(() {
                  _productAndCategories = Future.value(response);
                });
              }
            } catch (e) {
              _showErrorPopup(e.toString());
            } finally {
              _searchController.clear();
            }
          }
        },
      ),
    );
  }

  // Show error popup
  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show no product found popup
  void _showNoProductFoundPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Product Found'),
        content: Text(
          'No product matched with the scanned code.',
          style:
              GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productDetailsProvider = Provider.of<ProductDetailsProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () => Future.value(_willpop.onWillPop()),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(context, cartProvider),
        body: Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: Column(
                children: [
                  _buildSearchBar(w, h),
                  _buildFilterBar(w),
                  _buildProductList(productDetailsProvider, cartProvider, w, h),
                ],
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildFloatingActionButton(cartProvider, w),
      ),
    );
  }

  // Build AppBar
  AppBar _buildAppBar(BuildContext context, CartProvider cartProvider) {
    return AppBar(
      backgroundColor: Constants.primaryColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: () {
          if (cartProvider.items.isEmpty) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const CreateRequestScreen()),
              (route) => false,
            );
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Unsaved Changes'),
                content: const Text(
                    'Going back without saving may lead to loss of data.\nPlease save your changes.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      cartProvider.clearCart();
                    },
                    child: const Text('Leave'),
                  ),
                ],
              ),
            );
          }
        },
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Text(
        "Add Items",
        style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w500),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: GestureDetector(
            onTap: () => DynamicAlertBox().logOut(
              context,
              "Do you Want to Logout",
              () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SplashScreen()),
              ),
            ),
            child: const CircleAvatar(
                radius: 22, child: Text("MR"), backgroundColor: Colors.white),
          ),
        ),
      ],
    );
  }

  // Build Search Bar
  Widget _buildSearchBar(double w, double h) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: h * 0.01),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _searchController,
              onChanged: (query) => setState(() {}),
              onFieldSubmitted: (value) => _applyFilters(),
              decoration: InputDecoration(
                labelText: 'Search',
                labelStyle: TextStyle(fontSize: w * 0.04),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(w * 0.02)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,
                            color: Colors.grey.shade900, size: w * 0.05),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                prefixIcon: IconButton(
                  icon: Icon(Icons.search,
                      color: Constants.primaryColor, size: w * 0.06),
                  onPressed: _searchController.text.isEmpty
                      ? null
                      : () => _applyFilters(),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                    vertical: h * 0.01, horizontal: w * 0.04),
              ),
              style: TextStyle(fontSize: w * 0.04),
            ),
          ),
          IconButton(
            icon: Icon(Icons.barcode_reader,
                size: w * 0.1, color: Colors.grey.shade900),
            onPressed: _scanQrCode,
          ),
        ],
      ),
    );
  }

  // Build Filter Bar
  Widget _buildFilterBar(double w) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Products",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: w * 0.045),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.filter_list_sharp,
                color: Colors.grey.shade900, size: w * 0.06),
            onPressed: () {
              _productAndCategories.then((data) {
                _showFilterBottomSheet(context, data.data.categories);
              });
            },
          ),
        ],
      ),
    );
  }

  // Build Product List
  Widget _buildProductList(ProductDetailsProvider productDetailsProvider,
      CartProvider cartProvider, double w, double h) {
    return Expanded(
      child: FutureBuilder<ProductAndCategoriesModel>(
        future: _productAndCategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            final List<Product> products = snapshot.data!.data.products;
            if (products.isEmpty) {
              return const Center(
                  child:
                      Text('No data found.', style: TextStyle(fontSize: 18)));
            }
            return ListView.builder(
              padding: EdgeInsets.only(bottom: 20.h),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final bool isSelected = index == _infoButtonClickedIndex;
                return isSelected
                    ? _SelectedProductTile(
                        productDetailsProvider: productDetailsProvider,
                        vendorId: widget.vendorId,
                        vendorName: widget.vendorName,
                        salesManName: widget.salesManName,
                        salesManId: widget.salesManId,
                        selectedProductName: _selectedProductName,
                        selectedProductId: _selectedProductId,
                        selectedUOM: _selectedUOM,
                        selectedCost: _selectedCost,
                        selectedItemID: _selectedItemID,
                        selectedBarcode: _selectedBarcode,
                        selectedUomCost: _selectedUomCost,
                        selectedUOMid: _selectedUOMId,
                        onInfoPressed: () => _showAlternativeUnits(
                            context, _selectedItemID, _infoButtonClickedIndex!),
                      )
                    : _ProductTile(
                        product: product,
                        index: index,
                        cartProvider: cartProvider,
                        productDetailsProvider: productDetailsProvider,
                        vendorId: widget.vendorId,
                        vendorName: widget.vendorName,
                        salesManName: widget.salesManName,
                        salesManId: widget.salesManId,
                        onInfoPressed: () => _showAlternativeUnits(
                            context, product.itemID, index),
                      );
              },
            );
          }
        },
      ),
    );
  }

  // Build Floating Action Button
  Widget _buildFloatingActionButton(CartProvider cartProvider, double w) {
    return FutureBuilder<ProductAndCategoriesModel>(
      future: _productAndCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            snapshot.data!.data.products.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Stack(
            children: [
              Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Constants.buttonColor,
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const CartScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Bin",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500)),
                      SizedBox(width: 4),
                      Icon(Icons.shopping_cart, size: 22, color: Colors.white),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: w / 2 - 60,
                child: badges.Badge(
                  position: badges.BadgePosition.topEnd(),
                  badgeContent: Consumer<CartProvider>(
                    builder: (context, cartProvider, _) => Text(
                      cartProvider.getCartQuantity().toString(),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  badgeStyle: const badges.BadgeStyle(badgeColor: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show Filter Bottom Sheet
  void _showFilterBottomSheet(BuildContext context, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        categories: categories,
        selectedCategories: _selectedCategories,
        onCategoriesChanged: (newSelectedCategories) {
          setState(() {
            _selectedCategories = newSelectedCategories;
            _updateSelectedCategories();
            _applyFilters();
          });
        },
      ),
    );
  }
}

// Widget for Filter Bottom Sheet
class _FilterBottomSheet extends StatefulWidget {
  final List<Category> categories;
  final List<String> selectedCategories;
  final Function(List<String>) onCategoriesChanged;

  const _FilterBottomSheet({
    required this.categories,
    required this.selectedCategories,
    required this.onCategoriesChanged,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<Category> _filteredCategories;
  late List<String> _localSelectedCategories;

  @override
  void initState() {
    super.initState();
    _filteredCategories = List.from(widget.categories);
    _localSelectedCategories = List.from(widget.selectedCategories);
  }

  void _filterCategories(String query) {
    setState(() {
      _filteredCategories = widget.categories
          .where((category) =>
              category.grpName.toLowerCase().contains(query.toLowerCase()))
          .toList();
      log("Filtered categories: ${_filteredCategories.length} found");
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    List<Category> sortedCategories = List.from(_filteredCategories)
      ..sort((a, b) {
        final aSelected = _localSelectedCategories.contains(a.grpName);
        final bSelected = _localSelectedCategories.contains(b.grpName);
        if (aSelected && !bSelected) return -1;
        if (!aSelected && bSelected) return 1;
        return a.grpName.compareTo(b.grpName);
      });

    return Container(
      height: screenHeight * 0.85,
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Categories',
                  style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.close, size: screenWidth * 0.06),
                onPressed: () {
                  widget.onCategoriesChanged(_localSelectedCategories);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, size: screenWidth * 0.06),
              hintText: 'Search',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02)),
              contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.015,
                  horizontal: screenWidth * 0.04),
            ),
            style: TextStyle(fontSize: screenWidth * 0.04),
            onChanged: _filterCategories,
          ),
          SizedBox(height: screenHeight * 0.02),
          Expanded(
            child: ListView.builder(
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final category = sortedCategories[index];
                final isSelected =
                    _localSelectedCategories.contains(category.grpName);
                return Container(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.transparent,
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _localSelectedCategories.add(category.grpName);
                        } else {
                          _localSelectedCategories.remove(category.grpName);
                        }
                        log("Local Selected Categories: $_localSelectedCategories");
                      });
                    },
                    title: Text(category.grpName,
                        style: TextStyle(fontSize: screenWidth * 0.04)),
                    secondary: CircleAvatar(
                      radius: screenWidth * 0.06,
                      backgroundColor: Constants.primaryColor,
                      child: Text(
                        category.grpName.isNotEmpty
                            ? category.grpName.substring(0, 1).toUpperCase()
                            : '',
                        style: TextStyle(
                            color: Colors.white, fontSize: screenWidth * 0.05),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.onCategoriesChanged(_localSelectedCategories);
            },
            child: Material(
              elevation: 2,
              child: Container(
                height: screenHeight * 0.045,
                width: screenWidth * .98,
                decoration: BoxDecoration(
                    color: Constants.buttonColor,
                    borderRadius: BorderRadius.circular(10.r)),
                child: Center(
                    child: Text(
                  "Filter",
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500),
                )),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// Widget for Alternative Units Bottom Sheet
// Widget for Alternative Units Bottom Sheet
class _AlternativeUnitsBottomSheet extends StatelessWidget {
  final List<dynamic> data;
  final Function(Map<String, dynamic>) onItemSelected;
  final CartProvider cartProvider; // Add cartProvider

  const _AlternativeUnitsBottomSheet({
    required this.data,
    required this.onItemSelected,
    required this.cartProvider, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Alternative Units',
                  style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
            ),
            const Divider(thickness: 1.0),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, itemIndex) {
                  final item = data[itemIndex];

                  // Check if this alternative unit is in cart
                  final isInCart = cartProvider.items.any(
                    (cartItem) =>
                        cartItem.itemId == item['ItemID'] &&
                        cartItem.uomId == item['UOMId'],
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    elevation: 3,
                    color: isInCart
                        ? Colors.yellow[300]
                        : Colors.white, // Apply color condition
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(item['productName'],
                          style: const TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8.0),
                          Text('Barcode : ${item['productId']}',
                              style: TextStyle(color: Colors.grey[700])),
                          Text('UOM : ${item['UOM']}',
                              style: const TextStyle(color: Colors.green)),
                          Text('Price : ${item['Cost'].toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                      onTap: () {
                        onItemSelected(item);
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
  }
}

// Widget for Selected Product Tile
class _SelectedProductTile extends StatelessWidget {
  final ProductDetailsProvider productDetailsProvider;
  final int? vendorId;
  final String? vendorName;
  final String? salesManName;
  final String? salesManId;
  final String selectedProductName;
  final String selectedProductId;
  final String selectedUOM;
  final String selectedUOMid;
  final double selectedCost;
  final dynamic selectedItemID;
  final dynamic selectedBarcode;
  final dynamic selectedUomCost;
  final VoidCallback onInfoPressed;

  const _SelectedProductTile({
    required this.productDetailsProvider,
    required this.vendorId,
    required this.selectedUOMid,
    required this.vendorName,
    required this.salesManName,
    required this.salesManId,
    required this.selectedProductName,
    required this.selectedProductId,
    required this.selectedUOM,
    required this.selectedCost,
    required this.selectedItemID,
    required this.selectedBarcode,
    required this.onInfoPressed,
    required this.selectedUomCost,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        productDetailsProvider.setProductDetails(
            selectedProductId,
            selectedProductName,
            selectedUOM,
            selectedItemID, // Assuming UOMId is same as ItemID for simplicity
            selectedCost,
            selectedItemID,
            selectedBarcode,
            selectedUomCost);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CartDetailsScreen(
              vendorId: vendorId,
              vendorName: vendorName,
              salesManId: salesManId,
              salesManName: salesManName,
              uomId: selectedUOMid,
            ),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Constants.primaryColor,
            child: Text(selectedProductName.substring(0, 1),
                style: const TextStyle(color: Colors.white)),
          ),
          title: _ProductDetailsColumn(
            //  id:product.itemID,
            //   cartProvider:cartProvider,
            productName: selectedProductName,
            barcode: selectedProductId,
            uom: selectedUOM,
            price: selectedCost,
            // uomId: selectedUOMid,
            onInfoPressed: onInfoPressed,
          ),
        ),
      ),
    );
  }
}

// Widget for Product Tile
class _ProductTile extends StatelessWidget {
  final Product product;
  final int index;
  final CartProvider cartProvider;
  final ProductDetailsProvider productDetailsProvider;
  final int? vendorId;
  final String? vendorName;
  final String? salesManName;
  final String? salesManId;
  final VoidCallback onInfoPressed;

  const _ProductTile({
    required this.product,
    required this.index,
    required this.cartProvider,
    required this.productDetailsProvider,
    required this.vendorId,
    required this.vendorName,
    required this.salesManName,
    required this.salesManId,
    required this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isInCart =
        cartProvider.items.any((item) => item.itemId == product.itemID
            // Ff&&
            // item.productIndex == product.productId &&
            // item.uomId == product.UOMId,
            );

    return InkWell(
      onTap: () {
        productDetailsProvider.setProductDetails(
            product.productId,
            product.productName,
            product.UOM,
            product.UOMId,
            product.ProductCost,
            product.itemID,
            product.barcode,
            product.uomCost);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CartDetailsScreen(
              vendorId: vendorId,
              vendorName: vendorName,
              salesManId: salesManId,
              salesManName: salesManName,
              uomId: product.UOMId.toString(),
            ),
          ),
        );
        log("uom id ${product.UOMId}");
      },
      child: Container(
        decoration: BoxDecoration(
          color: isInCart ? Colors.yellow[300] : Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Constants.primaryColor,
              child: Text(product.productName.substring(0, 1),
                  style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _ProductDetailsColumn(
                  id: product.itemID,
                  // uomId: product.UOMId,
                  productName: product.productName,
                  barcode: product.barcode,
                  uom: product.UOM,
                  price: product.ProductCost,
                  onInfoPressed: onInfoPressed,
                  isInCart: isInCart),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Product Details Column
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:provider/provider.dart';
// import 'package:merchandiser_clone/model/cart_provider.dart';
// import 'package:merchandiser_clone/constants.dart'; // Assuming Constants is defined here

class _ProductDetailsColumn extends StatelessWidget {
  final String productName;
  final dynamic barcode;
  final String uom;
  final int id;
  // final String uomId;
  final double price;
  final VoidCallback onInfoPressed;
  final bool isInCart;

  const _ProductDetailsColumn({
    required this.productName,
    required this.barcode,
    this.id = 0,
    // required this.uomId,
    required this.uom,
    required this.price,
    required this.onInfoPressed,
    this.isInCart = false,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Text(
                  productName,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Barcode: $barcode',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'UNIT: $uom',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
              Text(
                'Price: ${price.toStringAsFixed(3)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (isInCart)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      thickness: 0.4,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(
                      width: 700.w, // Adjust width to fit multiple containers
                      height: 20.h, // Adjust height for compact display
                      child: Builder(
                        builder: (context) {
                          final uomQuantities = cartProvider
                              .getQuantityByUomForItem(id.toString());
                          if (uomQuantities.isEmpty) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13.r),
                                color: Constants.primaryColor,
                              ),
                              padding: const EdgeInsets.all(2.0),
                              child: Center(
                                child: Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: uomQuantities.length,
                            itemBuilder: (context, index) {
                              final entry =
                                  uomQuantities.entries.elementAt(index);
                              final uom = entry.key.toString();
                              final quantity = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(13.r),
                                    color: Constants.primaryColor,
                                  ),
                                  padding: const EdgeInsets.all(2.0),
                                  child: Center(
                                    child: Text(
                                      '$uom: $quantity',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                )
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.info_outline, size: 24, color: Colors.grey.shade700),
          onPressed: onInfoPressed,
        ),
      ],
    );
  }
}
// class _ProductDetailsColumn extends StatelessWidget {
//   final String productName;
//   final dynamic barcode;

//   final String uom;
//   final int id;
//   final double price;
//   final VoidCallback onInfoPressed;
//   final bool isInCart;

//   const _ProductDetailsColumn(
//       {required this.productName,
//       required this.barcode,
//       this.id = 0,
//       required this.uom,
//       required this.price,
//       required this.onInfoPressed,
//       this.isInCart = false});

//   @override
//   Widget build(BuildContext context) {
//     final cartProvider = Provider.of<CartProvider>(context);

//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               SizedBox(
//                 width: MediaQuery.of(context).size.width * 0.6,
//                 child: Text(productName,
//                     style: const TextStyle(fontSize: 14),
//                     overflow: TextOverflow.ellipsis),
//               ),
//               Text('Barcode : $barcode',
//                   style: const TextStyle(fontSize: 12, color: Colors.grey)),
//               Text('UNIT: $uom',
//                   style: const TextStyle(fontSize: 12, color: Colors.green)),
//               Text('Price : ${price.toStringAsFixed(3)}',
//                   style: const TextStyle(fontSize: 12, color: Colors.grey)),
//             ],
//           ),
//         ),
//         if (isInCart)
//           Container(
//             decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(13.r),
//                 color: Constants.primaryColor),
//             child: Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(2.0),
//                 child: Text(
//                   cartProvider
//                           .getQuantityByUomForItem(id.toString())
//                           ?.toString() ??
//                       '0',
//                   style: TextStyle(
//                       fontSize: 10.sp,
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ),
//           ),
//         IconButton(
//           icon: Icon(Icons.info_outline, size: 24, color: Colors.grey.shade700),
//           onPressed: onInfoPressed,
//         ),
//       ],
//     );
//   }
// }
