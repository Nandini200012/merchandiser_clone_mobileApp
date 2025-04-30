import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

class ProductDetails {
  final String productName;
  final String productId;

  ProductDetails({required this.productName, required this.productId});
}

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
  final TextEditingController _searchController = TextEditingController();
  late Future<ProductAndCategoriesModel> productAndCategories;
  final MerchendiserApiService apiService = MerchendiserApiService();
  late Willpop willpop;
  List<Category> categories = [];
  List<String> selectedCategories = [];
  List<int> selectedCategoryIds = [];
  String selectedProductName = '';
  String selectedProductId = '';
  String selectedUOM = '';
  dynamic selectedUOMId = '';
  double selectedCost = 0.0;
  dynamic selectedItemID = '';
  dynamic selectedbarcode = '';

  int? infoButtonClickedIndex;

  @override
  void initState() {
    super.initState();
    willpop = Willpop(context);
    fetchInitialData();
  }

  void fetchInitialData() {
    productAndCategories = apiService.getProductAndCategories(
      flag: 100,
      pageNo: 1,
      vendorId: widget.vendorId ?? 1,
      filterText: '',
    );
    productAndCategories.then((data) {
      setState(() {
        categories = data.data.categories;
      });
    });
  }

  Future<void> showAlternativeUnits(
    BuildContext context,
    dynamic itemID,
    int index,
  ) async {
    try {
      List<dynamic> data = await apiService.fetchAlternativeUnits(itemID);
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      shrinkWrap: true, // Ensure ListView takes minimal space
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable scrolling in ListView
                      itemCount: data.length,
                      itemBuilder: (context, itemIndex) {
                        var item = data[itemIndex];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8.0),
                                Text(
                                  'Barcode : ${item['productId']}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  'UOM : ${item['UOM']}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                                Text(
                                  'Price : ${item['Cost'].toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                selectedProductName = item['productName'];
                                selectedProductId = item['productId'];
                                selectedUOM = item['UOM'];
                                selectedUOMId = item['UOMId'];
                                selectedCost = item['Cost'];
                                selectedItemID = item['ItemID'];
                                selectedbarcode = item['Barcode'];
                                infoButtonClickedIndex = index;
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

  Future<void> _refresh() async {
    productAndCategories = apiService.getProductAndCategories(
      flag: 100,
      pageNo: 1,
      vendorId: widget.vendorId ?? 1,
      filterText: '',
    );
    log("product data len: ${productAndCategories.toString()}");
    productAndCategories.then((data) {
      setState(() {
        categories = data.data.categories;
      });
    });
  }

  List<Product> filterProducts(List<Product> products, String query) {
    return [];
  }

  void _updateSelectedCategories() {
    setState(() {
      selectedCategoryIds = selectedCategories
          .map((categoryName) {
            try {
              return categories
                  .firstWhere(
                    (category) => category.grpName == categoryName,
                  )
                  .grpId;
            } catch (e) {
              print("Category not found: $categoryName");
              return -1;
            }
          })
          .where((id) => id != -1)
          .toList();
      print("Selected Category Names -------->>>>: $selectedCategories");
      print("Selected Category IDS -------->>>>: $selectedCategoryIds");
    });
  }

  void _applyFilters() async {
    log("apply filters ------->>>>>>> ${_searchController.text}");
    try {
      final result = await apiService.getProductAndCategories(
        flag: 101,
        pageNo: 1,
        vendorId: widget.vendorId ?? 1,
        filterText: _searchController.text,
        selectedCategoryIds: selectedCategoryIds,
      );
      setState(() {
        productAndCategories = Future.value(result);
        print("Selected Category IDs: $selectedCategoryIds");
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  void _showFilterBottomSheet(BuildContext context, List<Category> categories) {
    TextEditingController _searchController = TextEditingController();
    List<Category> filteredCategories = List.from(categories);
    List<String> localSelectedCategories = List.from(selectedCategories);

    void _filterCategories(String query) {
      setState(() {
        filteredCategories = categories
            .where(
              (category) => category.grpName.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final mediaQuery = MediaQuery.of(context);
            final screenHeight = mediaQuery.size.height;
            final screenWidth = mediaQuery.size.width;

            List<Category> sortedCategories = List.from(filteredCategories)
              ..sort((a, b) {
                if (localSelectedCategories.contains(a.grpName) &&
                    !localSelectedCategories.contains(b.grpName)) {
                  return -1;
                } else if (!localSelectedCategories.contains(a.grpName) &&
                    localSelectedCategories.contains(b.grpName)) {
                  return 1;
                } else {
                  return a.grpName.compareTo(b.grpName);
                }
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
                      Text(
                        'Filter Categories',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: screenWidth * 0.06),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              size: screenWidth * 0.06,
                            ),
                            hintText: 'Search',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.02,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.015,
                              horizontal: screenWidth * 0.04,
                            ),
                          ),
                          style: TextStyle(fontSize: screenWidth * 0.04),
                          onChanged: (value) {
                            setState(() {
                              _filterCategories(value);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sortedCategories.length,
                      itemBuilder: (context, index) {
                        String firstLetter = sortedCategories[index]
                            .grpName
                            .substring(0, 1)
                            .toUpperCase();
                        bool isSelected = localSelectedCategories.contains(
                          sortedCategories[index].grpName,
                        );

                        return Container(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.2)
                              : Colors
                                  .transparent, // Change color when selected
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  localSelectedCategories.add(
                                    sortedCategories[index].grpName,
                                  );
                                } else {
                                  localSelectedCategories.remove(
                                    sortedCategories[index].grpName,
                                  );
                                }
                                sortedCategories.sort((a, b) {
                                  if (localSelectedCategories.contains(
                                        a.grpName,
                                      ) &&
                                      !localSelectedCategories.contains(
                                        b.grpName,
                                      )) {
                                    return -1;
                                  } else if (!localSelectedCategories.contains(
                                        a.grpName,
                                      ) &&
                                      localSelectedCategories.contains(
                                        b.grpName,
                                      )) {
                                    return 1;
                                  } else {
                                    return a.grpName.compareTo(b.grpName);
                                  }
                                });
                                _updateSelectedCategories();
                                _applyFilters();
                              });
                            },
                            title: Text(
                              sortedCategories[index].grpName,
                              style: TextStyle(fontSize: screenWidth * 0.04),
                            ),
                            secondary: CircleAvatar(
                              radius: screenWidth * 0.06,
                              backgroundColor: Constants.primaryColor,
                              // Colors.purple,
                              child: Text(
                                firstLetter,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.05,
                                ),
                              ),
                            ),
                            // Adjust the color for the selected state
                            tileColor: isSelected
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.transparent,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var productDetailsProvider = Provider.of<ProductDetailsProvider>(context);
    var cartProvider = Provider.of<CartProvider>(context); // Add this line
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;

    return WillPopScope(
        onWillPop: () async {
          return willpop.onWillPop();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Constants.primaryColor,
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: () {
                if (cartProvider.items.isEmpty) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const CreateRequestScreen(),
                    ),
                    (route) => false,
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Unsaved Changes'),
                      content: const Text(
                        'Going back without saving may lead to loss of data.\nPlease save your changes.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(), // Just close dialog
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop(); // Close dialog
                            cartProvider.clearCart();
                            // Navigator.of(context).pushAndRemoveUntil(
                            //   MaterialPageRoute(
                            //     builder: (context) =>
                            //         const CreateRequestScreen(),
                            //   ),
                            //   (route) => false,
                            // );
                          },
                          child: const Text('Leave'),
                        ),
                      ],
                    ),
                  );
                }
                // Navigator.of(context).pop();
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
                  onTap: () {
                    DynamicAlertBox().logOut(
                      context,
                      "Do you Want to Logout",
                      () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const SplashScreen()),
                        );
                      },
                    );
                  },
                  child: const CircleAvatar(
                    radius: 22,
                    child: Text("MR"),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              // gradient: LinearGradient(
              //   colors: [
              //     Colors.white, // Top color
              //     Colors.white, // New middle color (white)
              //     Colors.white, // New middle color (white)
              //     Colors.white, // New middle color (white)
              //     Colors.white, // New middle color (white)
              //     Colors.white, // Bottom color
              //   ],
              //   begin: Alignment.topCenter,
              //   end: Alignment.bottomCenter,
              //   stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              // ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: Column(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.02,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.06,
                                  child: TextFormField(
                                    controller: _searchController,
                                    onChanged: (query) {
                                      setState(() {});
                                    },
                                    onFieldSubmitted: (value) {
                                      setState(() {
                                        _applyFilters();
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Search',
                                      labelStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.04,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                        ),
                                      ),
                                      suffixIcon:
                                          _searchController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.close,
                                                    color: const Color.fromARGB(
                                                        255, 19, 19, 19),
                                                    size: MediaQuery.of(
                                                          context,
                                                        ).size.width *
                                                        0.05,
                                                  ),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    setState(() {
                                                      _applyFilters();
                                                    });
                                                  },
                                                )
                                              : null,
                                      prefixIcon: IconButton(
                                        icon: Icon(
                                          Icons.search,
                                          color: Constants.primaryColor,
                                          size: MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.06,
                                        ),
                                        onPressed: () {
                                          _searchController.text.isEmpty
                                              ? null
                                              : setState(() {
                                                  _applyFilters();
                                                });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical:
                                            MediaQuery.of(context).size.height *
                                                0.01,
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.04,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.04,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.barcode_reader,
                                  size: MediaQuery.of(context).size.width * 0.1,
                                  color: Colors.grey.shade900,
                                  // color: Constants.appColor,
                                  // Constants.appColor,
                                ),
                                onPressed: scanQrCode,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.02,
                          vertical: 0
                          // MediaQuery.of(context).size.width * 0.001,
                          // MediaQuery.of(context).size.width * 0.02,
                          ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Products",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.045,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.filter_list_sharp,
                              color: Colors.grey.shade900,
                              size: MediaQuery.of(context).size.width * 0.06,
                            ),
                            onPressed: () {
                              if (productAndCategories != null) {
                                productAndCategories.then((data) {
                                  _showFilterBottomSheet(
                                    context,
                                    data.data.categories,
                                  );
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<ProductAndCategoriesModel>(
                        future: productAndCategories,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CupertinoActivityIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text("Error: ${snapshot.error}"));
                          } else {
                            final List<Product> products =
                                snapshot.data!.data.products;
                            if (products.isEmpty) {
                              return const Center(
                                child: Text('No data found.',
                                    style: TextStyle(fontSize: 18)),
                              );
                            }
                            return ListView.builder(
                              padding: EdgeInsets.only(bottom: 20.h),
                              itemCount: products.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final bool isSelected =
                                    index == infoButtonClickedIndex;
                                return isSelected
                                    ? _buildSelectedProductTile(
                                        context,
                                        productDetailsProvider,
                                        widget.vendorId,
                                        widget.vendorName,
                                        widget.salesManName,
                                        widget.salesManId,
                                      )
                                    : _buildProductTile(
                                        context,
                                        product,
                                        index,
                                        cartProvider,
                                        productDetailsProvider,
                                        widget.vendorId,
                                        widget.vendorName,
                                        widget.salesManName,
                                        widget.salesManId,
                                      );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FutureBuilder<ProductAndCategoriesModel>(
            future: productAndCategories,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text(""));
              } else {
                final List<Product> products = snapshot.data!.data.products;
                if (products.isEmpty) {
                  return const Center(
                    child: Text('', style: TextStyle(fontSize: 18)),
                  );
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
                          // gradient: const LinearGradient(
                          //   colors: [Colors.purple, Constants.primaryColor],
                          //   begin: Alignment.centerLeft,
                          //   end: Alignment.centerRight,
                          // ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const CartScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              return const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Bin",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.shopping_cart,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: w / 2 - 60,
                        child: badges.Badge(
                          position: badges.BadgePosition.topEnd(),
                          badgeContent: Consumer<CartProvider>(
                            builder: (context, cartProvider, _) {
                              return Text(
                                cartProvider.getCartQuantity().toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                ), // Optional: to set text color inside the badge
                              );
                            },
                          ),
                          badgeStyle: const badges.BadgeStyle(
                            badgeColor: Colors
                                .white, // Change this to your desired color
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ));
  }

  void scanQrCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return QRScannerWidget(
          onScan: (String scannedData) async {
            Navigator.pop(context); // Close the scanner first

            if (scannedData.isNotEmpty) {
              _searchController.text = scannedData;

              try {
                ProductAndCategoriesModel response =
                    await apiService.getProductAndCategories(
                  flag: 101,
                  pageNo: 1,
                  vendorId: widget.vendorId ?? 1,
                  filterText: _searchController.text,
                );

                if (response.data.products == null ||
                    response.data.products!.isEmpty) {
                  // Assuming products list is inside response
                  _showNoProductFoundPopup();
                } else {
                  setState(() {
                    productAndCategories = Future.value(response);
                  });
                }
              } catch (e) {
                _showErrorPopup(e.toString());
              } finally {
                _searchController.clear();
              }
            }
          },
        );
      },
    );
  }

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

//   void scanQrCode() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) {
//         return QRScannerWidget(
//           onScan: (String scannedData) {
//             Navigator.pop(context); // Close the scanner
//             if (scannedData.isNotEmpty) {
//               Future<ProductAndCategoriesModel> obj;
//                  setState(() {
//                 _searchController.text = scannedData;
//                 obj = apiService.getProductAndCategories(
//                   flag: 101,
//                   pageNo: 1,
//                   vendorId: widget.vendorId ?? 1,
//                   filterText: _searchController.text,
//                 );
//                 _searchController.text = ""; // Clear after use
//               });
// if(obj.isEmpty){
//   add popup here
// }else

//               setState(() {
//                 _searchController.text = scannedData;
//                 productAndCategories = apiService.getProductAndCategories(
//                   flag: 101,
//                   pageNo: 1,
//                   vendorId: widget.vendorId ?? 1,
//                   filterText: _searchController.text,
//                 );
//                 _searchController.text = ""; // Clear after use
//               });
//             }
//           },
//         );
//       },
//     );
//   }

// Build the special selected product tile
  Widget _buildSelectedProductTile(
    BuildContext context,
    ProductDetailsProvider productDetailsProvider,
    int? vendorId,
    String? vendorName,
    String? salesManName,
    String? salesManId,
  ) {
    return InkWell(
      onTap: () {
        productDetailsProvider.setProductDetails(
          selectedProductId,
          selectedProductName,
          selectedUOM,
          selectedUOMId,
          selectedCost,
          selectedItemID,
          selectedbarcode,
        );
        _searchController.clear();
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => CartDetailsScreen(
                    vendorId: vendorId,
                    vendorName: vendorName,
                    salesManId: salesManId,
                    salesManName: salesManName,
                  )),
        );
      },
      child: Card(
        color: Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Constants.primaryColor,
            //  Colors.purple,
            child: Center(
              child: Text(
                selectedProductName.substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          title: _buildProductDetailsColumn(
            productName: selectedProductName,
            barcode: selectedProductId,
            uom: selectedUOM,
            price: selectedCost,
            onInfoPressed: () {
              showAlternativeUnits(
                  context, selectedItemID, infoButtonClickedIndex!);
            },
          ),
        ),
      ),
    );
  }

// Build the normal product tile
  Widget _buildProductTile(
    BuildContext context,
    Product product,
    int index,
    CartProvider cartProvider,
    ProductDetailsProvider productDetailsProvider,
    int? vendorId,
    String? vendorName,
    String? salesManName,
    String? salesManId,
  ) {
    final String firstLetter = product.productName.substring(0, 1);
    final bool isInCart = cartProvider.items.any((item) =>
        item.itemId == product.itemID &&
        item.productIndex == product.productId &&
        item.uomId == product.UOMId);

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
        );
        _searchController.clear();
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => CartDetailsScreen(
                    vendorId: vendorId,
                    vendorName: vendorName,
                    salesManId: salesManId,
                    salesManName: salesManName,
                  )),
        );
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
              child: Center(
                child: Text(firstLetter,
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildProductDetailsColumn(
                productName: product.productName,
                barcode: product.barcode,
                uom: product.UOM,
                price: product.ProductCost,
                onInfoPressed: () {
                  showAlternativeUnits(context, product.itemID, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

// Reusable column for product details
  Widget _buildProductDetailsColumn({
    required String productName,
    required dynamic barcode,
    required String uom,
    required double price,
    required VoidCallback onInfoPressed,
  }) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: MediaQuery.of(context).size.width * .6,
                child: Text(
                  productName,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                )),
            Text(
              'Barcode : $barcode',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'UNIT: $uom',
              style: const TextStyle(fontSize: 12, color: Colors.green),
            ),
            Text(
              'Price : ${price.toStringAsFixed(3)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        Spacer(),
        IconButton(
          icon: Icon(Icons.info_outline, size: 24, color: Colors.grey.shade700),
          onPressed: onInfoPressed,
        ),
      ],
    );
  }
}
