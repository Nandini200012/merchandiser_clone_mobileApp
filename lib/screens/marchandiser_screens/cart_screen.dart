import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:merchandiser_clone/provider/cart_provider.dart';
import 'package:merchandiser_clone/provider/create_request_vendor_detals.dart';
import 'package:merchandiser_clone/provider/product_details_provider.dart';
import 'package:merchandiser_clone/provider/salesperson_provider.dart';
import 'package:merchandiser_clone/screens/common_widget/alert_popup.dart';
import 'package:merchandiser_clone/screens/marchandiser_screens/cart_details_screen.dart';
import 'package:merchandiser_clone/screens/marchandiser_screens/create_request_screen.dart';
import 'package:merchandiser_clone/screens/marchandiser_screens/marchendiser_bottomnav.dart';
import 'package:merchandiser_clone/screens/marchandiser_screens/marchendiser_dashboard_screen.dart';
import 'package:merchandiser_clone/screens/splash_screen.dart';
import 'package:merchandiser_clone/utils/SharedPreferencesUtil.dart';
import 'package:merchandiser_clone/utils/constants.dart';
import 'package:merchandiser_clone/utils/dynamic_alert_box.dart';
import 'package:merchandiser_clone/utils/urls.dart';
import 'package:merchandiser_clone/utils/willpop.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:http/http.dart' as http;

class CartScreen extends StatefulWidget {
  final List<CartDetailsItem>? itemList;
  final String? notes;
  final String? reason;

  const CartScreen({super.key, this.itemList, this.notes, this.reason});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> detailsList = [];
  late Willpop willpop;

  @override
  void initState() {
    super.initState();
    willpop = Willpop(context);
    print("Notes :>>${widget.notes}");
    print("Reason :>>${widget.reason}");
  }

  @override
  Widget build(BuildContext context) {
    var vendorDetailsProvider = Provider.of<CreateRequestVendorDetailsProvider>(
      context,
    );
    int? vendorId = vendorDetailsProvider.vendorId;
    String? vendorName = vendorDetailsProvider.vendorName;
    print("provider  Vendor ID : $vendorId");
    print("provider  Vendor Name : $vendorName");

    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    // details of sales man
    var salesPersonDetailsProvider = Provider.of<SalesPersonDetailsProvider>(
      context,
    );
    String? salesManName = salesPersonDetailsProvider.salesManName;
    int? salesManId = salesPersonDetailsProvider.salesManId;
    dynamic? _remarks = salesPersonDetailsProvider.remarks;

    print("provider Sales Man Name $salesManName");
    print("provider Sales Man Id $salesManId");
    print("provider Sales Remarks ... $salesManId");

    // product Details from provider
    var productDetailsProvider = Provider.of<ProductDetailsProvider>(context);
    dynamic? productId = productDetailsProvider.productId;
    String? productName = productDetailsProvider.productName;
    print("provider Product Name $productName");
    print("provider Product Id $productId");

    CartProvider cartProvider = Provider.of<CartProvider>(context);
    Map<String, List<CartDetailsItem>> groupedItems = groupBy(
      cartProvider.items,
      (item) => item.productName,
    );

    List<Map<String, dynamic>> detailsList = cartProvider.items.map((item) {
      return {
        "ItemID": item.itemId,
        "Barcode": item.productIndex,
        "Name": item.productName,
        "Qty": item.quantity.toDouble(),
        "UomID": item.uomId,
        "UOM": item.uom,
        "Cost": item.cost,
        "Date": item.selectedDate.toIso8601String(),
        "Note": item.note,
        "Reason": item.reason,
        "Banding": false,
        "Discount": false,
        "Return": false,
        "Approved": false,
        "Rejected": false,
      };
    }).toList();

    print("List Details :>>>$detailsList");
    void errorPopup(String errorMessage) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          title: Column(
            children: [
              Text(
                errorMessage,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Ok"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10.0,
                    ), // Adjust as needed
                    side: const BorderSide(color: Colors.blue, width: 2.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      print('Error: $errorMessage');
    }

    // Define your getUserId function
    Future<dynamic?> getLoggedEmployeeID() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt('EmployeeId');
    }

    void sendPostRequest() async {
      try {
        EasyLoading.show(
          status: 'Please wait...',
          dismissOnTap: false,
          maskType: EasyLoadingMaskType.black,
        );

        var apiUrl = Uri.parse(Urls.requestInsert);
        dynamic? userId = await getLoggedEmployeeID();

        var headers = {
          'Content-Type': 'application/json',
          'Authorization': Constants.token,
        };

        final Map<String, dynamic> requestBody = {
          "Marchandiser": userId,
          "SalesPersonID": salesManId,
          "SalesPersonName": salesManName,
          "VendorID": vendorId,
          "VendorName": vendorName,
          "Remarks": _remarks,
          "Details": detailsList,
        };
        print("JsonBody:${requestBody}");

        var requestBodyJson = jsonEncode(requestBody);
        print("Encode Body : $requestBodyJson");

        var response = await http.post(
          apiUrl,
          headers: headers,
          body: requestBodyJson,
        );

        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print("Response: $jsonResponse");

        if (response.statusCode == 200) {
          if (jsonResponse['isSuccess'] == true) {
            vendorDetailsProvider.clearVendorDetails();
            salesPersonDetailsProvider.clearSalesPersonDetails();
            productDetailsProvider.clearProductDetails();
            cartProvider.clearCart();
            successPopup();
          } else if (jsonResponse["isSuccess"] == false) {
            // showDialog(context: context, builder: builder)
            errorPopup(jsonResponse['message']);
          }
        } else {
          errorPopup(jsonResponse['message']);
          print('Error: ${response.statusCode}');
          print('Response data: ${response.body}');
          // errorPopup('An error occurred. Please try again.');
        }
      } catch (e) {
        print(e);
        errorPopup('An error occurred. Please try again.');
      } finally {
        EasyLoading.dismiss();
      }
    }

    return WillPopScope(
      onWillPop: () async {
        return willpop.onWillPop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          // leading: IconButton(
          //   icon: const Icon(Icons.arrow_back),
          //   onPressed: () {
          //     if (cartProvider.items.isEmpty) {
          //       Navigator.of(context).pushAndRemoveUntil(
          //         MaterialPageRoute(
          //           builder: (context) => const CreateRequestScreen(),
          //         ),
          //         (route) => false,
          //       );
          //     } else {
          //       showDialog(
          //         context: context,
          //         builder: (context) => AlertDialog(
          //           title: const Text('Unsaved Changes'),
          //           content: const Text(
          //             'Going back without saving may lead to loss of data.\nPlease save your changes.',
          //           ),
          //           actions: [
          //             TextButton(
          //               onPressed: () =>
          //                   Navigator.of(context).pop(), // Just close dialog
          //               child: const Text('Cancel'),
          //             ),
          //             TextButton(
          //               onPressed: () {
          //                 Navigator.of(context).pop(); // Close dialog
          //                 Navigator.of(context).pushAndRemoveUntil(
          //                   MaterialPageRoute(
          //                     builder: (context) => const CreateRequestScreen(),
          //                   ),
          //                   (route) => false,
          //                 );
          //               },
          //               child: const Text('Leave'),
          //             ),
          //           ],
          //         ),
          //       );
          //     }
          //   },
          // ),

          leading: IconButton(
            onPressed: () {
              cartProvider.items.isEmpty
                  ? Navigator.of(context).pop()
                  // ? Navigator.of(context).pushAndRemoveUntil(
                  //     MaterialPageRoute(
                  //       builder: (context) => const CreateRequestScreen(),
                  //     ),
                  //     (route) => false,
                  //   )
                  : Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          title: const Text(
            "Bin",
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
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
                    backgroundColor: Colors.white,
                    child: Text(
                      "MR",
                    )),
              ),
            ),
          ],
        ),
        body: cartProvider.items.isEmpty
            ? const Center(
                child: Text(
                  "No Items in Cart",
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: groupedItems.length,
                      itemBuilder: (context, index) {
                        String productName = groupedItems.keys.elementAt(
                          index,
                        );
                        String productNameFirstLetter = productName.substring(
                          0,
                          1,
                        );
                        List<CartDetailsItem> items =
                            groupedItems[productName]!;
                        return StickyHeader(
                          header: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Constants.primarylite,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ), // Adjust the padding as needed
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20, // Adjust the radius as needed
                                    backgroundColor: Colors.white,
                                    child: Center(
                                      child: Text(
                                        productNameFirstLetter,
                                        style: const TextStyle(
                                          fontSize: 24,
                                        ), // Increase font size if needed
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                          maxLines:
                                              2, // Adjust the number of lines as needed
                                          overflow: TextOverflow
                                              .ellipsis, // Adds ellipsis to the text if it overflows
                                        ),
                                        Text(
                                          'Barcode : ${items.first.barcode.toString()}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                          maxLines:
                                              2, // Adjust the number of lines as needed
                                          overflow: TextOverflow
                                              .ellipsis, // Adds ellipsis to the text if it overflows
                                        ),
                                        Text(
                                          'Customer name : $vendorName',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Constants.primaryColor),
                                          maxLines:
                                              2, // Adjust the number of lines as needed
                                          overflow: TextOverflow
                                              .ellipsis, // Adds ellipsis to the text if it overflows
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          content: Container(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                title: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (var item in items)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Qty: ${item.quantity} Pcs',
                                                ),
                                                Text(
                                                  'Date: ${DateFormat('dd/MM/yyyy').format(item.selectedDate)}',
                                                ),
                                                const Divider(),
                                              ],
                                            ),
                                            InkWell(
                                              onTap: () {
                                                _deleteAlert(context, item);
                                              },
                                              child: const Icon(Icons.delete,
                                                  color:
                                                      Constants.primaryColor),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: Container(
          height: 100.h,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<CartProvider>(
                  builder: (context, cartProvider, _) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Qty :  ${cartProvider.getCartQuantity().toString()}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(
                            height: 2.h,
                          ),
                          Text("Total Product :  ${groupedItems.length}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  },
                ),
                Container(
                  height: 50,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Constants.buttonColor,
                    // gradient: const LinearGradient(
                    //   colors: [Colors.purple, Colors.purple],
                    //   begin: Alignment.centerLeft,
                    //   end: Alignment.centerRight,
                    // ),
                    // color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: cartProvider.items.isNotEmpty
                        ? () {
                            showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Center(
                                    child: Text(
                                      "Do you want to save",
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                  ),
                                  actions: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Consumer<CartProvider>(
                                          builder: (
                                            context,
                                            cartProvider,
                                            _,
                                          ) {
                                            return TextButton(
                                              style: ButtonStyle(
                                                side: MaterialStateProperty.all(
                                                  const BorderSide(
                                                    color: Colors.blue,
                                                    width: 2.0,
                                                  ), // Set the border color and width
                                                ),
                                              ),
                                              onPressed:
                                                  cartProvider.items.isNotEmpty
                                                      ? () {
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          sendPostRequest();
                                                        }
                                                      : null,
                                              child: const Text("Yes"),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 15),
                                        TextButton(
                                          style: ButtonStyle(
                                            side: MaterialStateProperty.all(
                                              const BorderSide(
                                                color: Colors.blue,
                                                width: 2.0,
                                              ), // Set the border color and width
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("No"),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        : null,
                    child: const Center(
                      child: Text(
                        "Save Request",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteAlert(context, CartDetailsItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // title: Container(height: 40,width: 40,child: Image.asset("assets/Delete-Button.png"),),
        //  Center(
        //   child: Icon(Icons.warning,color: Colors.red,size: 50,),
        // ),
        title: Center(
          child: Text(
            "Do you Want to Remove",
            style: TextStyle(fontSize: 12.sp),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Consumer<CartProvider>(
                builder: (context, cartProvider, _) {
                  return TextButton(
                    style: ButtonStyle(
                      side: MaterialStateProperty.all(
                        const BorderSide(
                          color: Colors.blue,
                          width: 2.0,
                        ), // Set the border color and width
                      ),
                    ),
                    onPressed: () {
                      cartProvider.removeFromCart(item);
                      Navigator.pop(context);
                    },
                    child: const Text("Yes"),
                  );
                },
              ),
              const SizedBox(width: 10),
              TextButton(
                style: ButtonStyle(
                  side: MaterialStateProperty.all(
                    const BorderSide(
                      color: Colors.blue,
                      width: 2.0,
                    ), // Set the border color and width
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("No"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void successPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              "Request Saved Successfully",
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10.0,
                        ), // Adjust the value as needed
                        side: const BorderSide(
                          color: Colors.blue,
                        ), // Change the color to the desired outline color
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            const MarchendiserDashboardScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void appBarBackButtonClicked() {}
}
