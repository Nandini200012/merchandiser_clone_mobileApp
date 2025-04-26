import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:merchandiser_clone/provider/split_provider.dart';
import 'package:merchandiser_clone/screens/salesman_screens/api_service/salesman_api_service.dart';
import 'package:merchandiser_clone/screens/salesman_screens/model/salesman_request_by_id_model.dart';
import 'package:merchandiser_clone/screens/salesman_screens/model/salesman_request_list_model.dart';
import 'package:merchandiser_clone/screens/salesman_screens/salesman_bottom_navbar.dart';
import 'package:merchandiser_clone/screens/salesman_screens/split_screen.dart';
import 'package:merchandiser_clone/utils/constants.dart';
import 'package:merchandiser_clone/utils/show_success_pop_up.dart';
import 'package:merchandiser_clone/utils/urls.dart';
import 'package:merchandiser_clone/utils/willpop.dart';
import 'package:provider/provider.dart';
import 'package:merchandiser_clone/screens/salesman_screens/model/salesman_info_model.dart'
    as info;
import 'package:merchandiser_clone/provider/salesman_request_provider.dart';
import 'package:merchandiser_clone/screens/splash_screen.dart';
import 'package:merchandiser_clone/utils/dynamic_alert_box.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:marchandise/screens/salesman_screens//model/discount_mode.dart';
import '../salesman_screens/model/discount_mode.dart';

enum MyButton {
  bandingButton,
  discountButton,
  returnButton,
  splitButton,
  noActionButton,
}

class Product {
  String name;
  dynamic productId;
  String status;
  String discountValue;
  bool editingDiscount;
  int siNo;
  dynamic uom;
  dynamic expiryDate;
  dynamic cost;
  dynamic qty;
  dynamic reason;
  dynamic notes;
  DiscountMode discountMode;
  double discountAmount;
  double discountPercentage;
  dynamic itemID;

  Product(
    this.name,
    this.productId,
    this.status, {
    this.discountValue = '',
    this.editingDiscount = true,
    required this.siNo,
    this.uom,
    this.expiryDate,
    this.cost,
    this.qty,
    this.reason,
    this.notes,
    this.discountMode = DiscountMode.percentage,
    this.discountAmount = 0.0,
    this.discountPercentage = 0.0,
    this.itemID,
  });
}

class RequestDetailsScreen extends StatefulWidget {
  final String vendorName;
  final String vendorId;
  final int requestId;
  const RequestDetailsScreen({
    Key? key,
    required this.vendorName,
    required this.vendorId,
    required this.requestId,
  }) : super(key: key);

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  List<Product> products = [];
  Set<Product> selectedProducts = {};
  List<Map<String, dynamic>> detailsList = [];
  SalesManApiService salesManApiService = SalesManApiService();
  MyButton currentButton = MyButton.bandingButton;
  String vendorName = "";
  late Willpop willpop;
  late Future<SalesmanRequestListModel> salesRequestList;
  final SalesManApiService apiService = SalesManApiService();
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _discountController;
  bool _isEditingQty = false;
  Product? _editingProduct;
  TextEditingController _qtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    salesRequestList = apiService.getSalesmanRequestList();
    _discountController = TextEditingController();
    willpop = Willpop(context);
    vendorName = widget.vendorName;
    _fetchSalesmanData();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _discountController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _discountController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      salesRequestList = apiService.getSalesmanRequestList();
    });
  }

  Future<void> _fetchSalesmanData() async {
    try {
      EasyLoading.show(
        status: 'Loading...',
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
      );
      SalesmanRequestById salesmanData = await salesManApiService
          .getSalesManRequestById(widget.requestId);

      setState(() {
        products =
            salesmanData.data.map((datum) {
              return Product(
                datum.prdouctName,
                datum.prdouctId,
                datum.status,
                editingDiscount: true,
                siNo: datum.siNo,
                uom: datum.uom,
                expiryDate: datum.date,
                cost: datum.cost,
                qty: datum.qty,
                reason: datum.reason,
                notes: datum.notes,
                itemID: datum.itemID,
              );
            }).toList();
      });
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<dynamic?> getLoggedEmployeeID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('EmployeeId');
  }

  void updateRequest() async {
    try {
      EasyLoading.show(
        status: 'Please wait...',
        dismissOnTap: false,
        maskType: EasyLoadingMaskType.black,
      );

      var apiUrl = Uri.parse(Urls.requestUpdate);
      dynamic? userId = await getLoggedEmployeeID();

      // Extract SplitDetails
      List<Map<String, dynamic>> splitDetailsList = [];
      for (var product in products) {
        List<Map<String, dynamic>> splitDetailsMaps =
            getSplitDetailsMapsByItemId(product.itemID, product.siNo);
        if (splitDetailsMaps.isNotEmpty) {
          splitDetailsList.addAll(splitDetailsMaps);
        }
      }
      // Debug print for splitDetailsList
      print("Split Details List: $splitDetailsList");
      print("Details List: $detailsList");

      var headers = {
        'Content-Type': 'application/json',
        'Authorization': Constants.token,
      };

      final Map<String, dynamic> requestBody = {
        "RequestID": widget.requestId,
        "RequestUpdationMode": "S",
        "UserID": userId,
        "Details": detailsList,
        "QtySplit": splitDetailsList,
      };

      // Convert requestBody to JSON string and print it
      var requestBodyJson = jsonEncode(requestBody);
      print("Request Body JSON: $requestBodyJson");

      var response = await http.post(
        apiUrl,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print("Response Body Template: ${response.body}");

      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (jsonResponse['isSuccess'] == true) {
          _showSnackbar('Request updated successfully.');
          Provider.of<SplitProvider>(
            context,
            listen: false,
          ).clearAllSplitDetails();
        } else {
          _showErrorPopup(jsonResponse['message']);
        }
      } else {
        _showErrorPopup(jsonResponse['message']);
      }
    } catch (e) {
      _showErrorPopup(e.toString());
    } finally {
      EasyLoading.dismiss();
    }
  }

  void _showErrorPopup(String message) {
    ShowSuccessPopUp().errorPopup(context: context, errorMessage: message);
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(375, 812));
    return WillPopScope(
      onWillPop: () async => willpop.onWillPop(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(),
        body: Column(
          children: [Expanded(child: _buildBody()), _buildSaveButton()],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.brown,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: const Text("Details", style: TextStyle(color: Colors.white)),
      centerTitle: true,
      actions: [_buildLogoutButton()],
    );
  }

  Padding _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: GestureDetector(
        onTap: () {
          DynamicAlertBox().logOut(context, "Do you Want to Logout", () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => SplashScreen()),
            );
          });
        },
        child: CircleAvatar(radius: 22, child: Text("SM")),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white,
            Colors.white,
            Colors.white,
            Colors.white,
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(child: _buildProductList()),
          ],
        ),
      ),
    );
  }

  void _showErrorBottomSheet(String message) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: 200.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 40.sp),
              SizedBox(height: 16.h),
              Text(
                message,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _validateAndUpdateRequest() {
    if (detailsList.isEmpty) {
      _showErrorBottomSheet('Please select at least one product to update.');
    } else {
      _showUpdateDialog();
    }
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      color: Colors.white,
      child: ElevatedButton(
        onPressed: _validateAndUpdateRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          padding: EdgeInsets.symmetric(vertical: 16.0),
        ),
        child: Text(
          'Save',
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(message, style: const TextStyle(fontSize: 16)),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: const BorderSide(color: Colors.blue),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 16,
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Do you want to Update",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        updateRequest();
                        _refreshData();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => SalesManBottomNavBar(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30.w,
                          vertical: 10.h,
                        ),
                      ),
                      child: Text(
                        "Yes",
                        style: TextStyle(fontSize: 16.sp, color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30.w,
                          vertical: 10.h,
                        ),
                      ),
                      child: Text(
                        "No",
                        style: TextStyle(fontSize: 16.sp, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList() {
    if (products.isEmpty) {
      return Center(child: Text('No Requests available'));
    }
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index]);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final splitProvider = Provider.of<SplitProvider>(context);

    return Card(
      color: Colors.grey[100],
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.brown,
                  child: Text(
                    product.name.substring(0, 1),
                    style: TextStyle(color: Colors.white, fontSize: 24.sp),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'ItemCode : ${product.productId.toString()}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Expiry Date : ${product.expiryDate.toString()}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEditingQty = true;
                            _editingProduct = product;
                            _qtyController.text = product.qty.toString();
                          });
                        },
                        child:
                            _isEditingQty && _editingProduct == product
                                ? TextField(
                                  onChanged: (value) {
                                    int qty = int.tryParse(value) ?? 0;
                                    setState(() {
                                      product.qty = qty;
                                    });
                                  },
                                  controller: _qtyController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter Qty',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onEditingComplete: () {
                                    setState(() {
                                      _isEditingQty = false;
                                      _editingProduct = null;
                                    });
                                  },
                                  autofocus: true,
                                )
                                : Text(
                                  'Qty : ${product.qty.toString()}',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12.sp,
                                  ),
                                ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Unit : ${product.uom.toString()}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Price : ${product.cost}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Reason : ${product.reason}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Notes : ${product.notes}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        product.status,
                        style: TextStyle(
                          color: _getStatusColor(product.status),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (product.status == 'Discount' &&
                          product.editingDiscount) ...[
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: FocusScope(
                                child: Focus(
                                  focusNode: _focusNode,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Percentage',
                                            style: TextStyle(fontSize: 12.sp),
                                          ),
                                          Switch(
                                            value:
                                                product.discountMode ==
                                                DiscountMode.amount,
                                            onChanged: (value) {
                                              setState(() {
                                                product.discountMode =
                                                    value
                                                        ? DiscountMode.amount
                                                        : DiscountMode
                                                            .percentage;
                                              });
                                            },
                                          ),
                                          Text(
                                            'Amount',
                                            style: TextStyle(fontSize: 12.sp),
                                          ),
                                        ],
                                      ),
                                      TextField(
                                        onChanged: (value) {
                                          double discount =
                                              double.tryParse(value) ?? 0;
                                          if (product.discountMode ==
                                                  DiscountMode.percentage &&
                                              (discount < 0 ||
                                                  discount > 100)) {
                                            Flushbar(
                                              message:
                                                  'Discount percentage must be between 0 and 100',
                                              backgroundColor: Colors.red,
                                              flushbarPosition:
                                                  FlushbarPosition.TOP,
                                              duration: Duration(seconds: 3),
                                            ).show(context);
                                            setState(() {
                                              product.discountValue = "";
                                            });
                                          } else {
                                            product.discountValue = value;
                                            if (product.discountMode ==
                                                DiscountMode.percentage) {
                                              product.discountPercentage =
                                                  discount;
                                              product.discountAmount =
                                                  (product.cost ?? 0) *
                                                  (discount / 100);
                                            } else {
                                              product.discountAmount = discount;
                                              product.discountPercentage =
                                                  (discount /
                                                      (product.cost ?? 1)) *
                                                  100;
                                            }
                                          }
                                        },
                                        controller: TextEditingController(
                                          text:
                                              product.discountValue.isEmpty
                                                  ? ''
                                                  : product.discountValue,
                                        ),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText:
                                              product.discountMode ==
                                                      DiscountMode.percentage
                                                  ? 'Enter Discount %'
                                                  : 'Enter Discount Amount',
                                          hintText: '0.000',
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (product
                                                    .discountValue
                                                    .isEmpty) {
                                                  product.discountValue = "";
                                                  _showConfirmationDialog(
                                                    context,
                                                    product,
                                                  );
                                                } else {
                                                  product.editingDiscount =
                                                      false;
                                                  createDataList();
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        autofocus: true,
                                      ),
                                      if (product.discountMode ==
                                          DiscountMode.percentage)
                                        Text(
                                          'Equivalent Discount Amount: ${product.discountAmount.toStringAsFixed(3)}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Equivalent Discount Percentage: ${product.discountPercentage.toStringAsFixed(3)}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                      ],
                      if (!product.editingDiscount &&
                          double.parse(
                                product.discountValue.isNotEmpty
                                    ? product.discountValue
                                    : '0',
                              ) >
                              0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                product.editingDiscount = true;
                                _discountController.text =
                                    product.discountValue;
                                _focusNode.requestFocus();
                              });
                            },
                            child: Text(
                              '${product.discountMode == DiscountMode.percentage ? 'Discount Percentage' : 'Discount Amount'}: ${double.parse(product.discountValue).toStringAsFixed(3)}'
                              ' (${product.discountMode == DiscountMode.percentage ? 'Amount: ' + product.discountAmount.toStringAsFixed(3) : 'Percentage: ' + product.discountPercentage.toStringAsFixed(3)})',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(
              color: Colors.grey,
              thickness: 1.h,
              indent: 16.w,
              endIndent: 16.w,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildUpdateButton(product),
                splitProvider.getSplitDetails(
                          product.productId,
                          product.siNo,
                        ) !=
                        null
                    ? _buildEditButton(product)
                    : Container(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton(Product product) {
    return ElevatedButton(
      onPressed: () => _showUpdateOptions(product),
      child: Text("Update", style: TextStyle(fontSize: 12.sp)),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.brown,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildEditButton(Product product) {
    return ElevatedButton(
      onPressed: () => _editSplitDetails(product),
      child: Text("Edit Split", style: TextStyle(fontSize: 12.sp)),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.brown,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showUpdateOptions(Product product) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.add, color: Colors.brown),
                  title: Text("Banding", style: TextStyle(fontSize: 16.sp)),
                  onTap: () {
                    _updateProductStatus(MyButton.bandingButton, product);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_offer, color: Colors.brown),
                  title: Text("Discount", style: TextStyle(fontSize: 16.sp)),
                  onTap: () {
                    setState(() {
                      product.status = 'Discount';
                      product.editingDiscount = true;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.reply, color: Colors.brown),
                  title: Text("Return", style: TextStyle(fontSize: 16.sp)),
                  onTap: () {
                    _updateProductStatus(MyButton.returnButton, product);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.call_split, color: Colors.brown),
                  title: Text("Split", style: TextStyle(fontSize: 16.sp)),
                  onTap: () {
                    _updateProductStatus(MyButton.splitButton, product);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SplitScreen(
                              product: product,
                              onSplitSave: (updatedProduct) {
                                setState(() {
                                  products[products.indexOf(product)] =
                                      updatedProduct;
                                  createDataList();
                                });
                              },
                              screenMode: 'SalesMan',
                            ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cancel, color: Colors.brown),
                  title: Text("No Actions", style: TextStyle(fontSize: 16.sp)),
                  onTap: () {
                    _updateProductStatus(MyButton.noActionButton, product);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateProductStatus(MyButton buttonType, Product product) {
    String newStatus = _getButtonTitle(buttonType);
    print(
      "Current status: ${product.status}, New status: $newStatus",
    ); // Debug print

    if (newStatus != "Split" && product.status == "Split") {
      setState(() {
        final splitProvider = Provider.of<SplitProvider>(
          context,
          listen: false,
        );
        splitProvider.clearSplitDetails(product.productId, product.siNo);
        _updateProductDirectly(product, _getButtonTitle(buttonType));
      });
    } else {
      _updateProductDirectly(product, newStatus);
    }
  }

  void _showClearSplitDialog(Product product, MyButton buttonType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Split Quantity'),
          content: Text('Do you want to clear the split quantity?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                final splitProvider = Provider.of<SplitProvider>(
                  context,
                  listen: false,
                );
                splitProvider.clearSplitDetails(
                  product.productId,
                  product.siNo,
                );
                _updateProductDirectly(product, _getButtonTitle(buttonType));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateProductDirectly(Product product, String newStatus) {
    setState(() {
      product.status = newStatus;
      if (newStatus == "Banding" ||
          newStatus == "Return" ||
          newStatus == "No Actions") {
        product.discountValue = '';
        product.editingDiscount = false;
        product.discountAmount = 0.00;
        product.discountPercentage = 0.00;
      }
      selectedProducts.add(product);
      createDataList();
      // Navigator.of(context).pop();
    });
  }

  void _editSplitDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SplitScreen(
              product: product,
              onSplitSave: (updatedProduct) {
                setState(() {
                  products[products.indexOf(product)] = updatedProduct;
                  createDataList();
                });
              },
              screenMode: 'SalesMan',
            ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Discount Entered'),
          content: Text('Do you want to proceed with a 0% discount?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    product.discountValue = '';
                    product.discountAmount = 0.00;
                    product.discountPercentage = 0.00;
                    product.editingDiscount = false;
                  });
                }
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    if (product.discountValue.isEmpty) {
                      product.discountValue = '';
                      product.discountAmount = 0.00;
                      product.discountPercentage = 0.00;
                    }
                    product.editingDiscount = false;
                  });
                }
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Banding':
        return Colors.red;
      case 'Discount':
        return const Color.fromARGB(255, 5, 131, 9);
      case 'Return':
        return const Color.fromARGB(255, 255, 153, 0);
      case 'Split':
        return Colors.purple;
      case 'No Actions':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  void _updateStatusAndRefresh(Product product, String status) {
    setState(() {
      if (status == "Banding" || status == "Return" || status == "No Actions") {
        product.discountValue = '';
        product.editingDiscount = false;
        product.discountAmount = 0.00;
        product.discountPercentage = 0.00;
      }
      product.status = status;
      selectedProducts.add(product);
      createDataList();
    });
  }

  String _getButtonTitle(MyButton buttonType) {
    switch (buttonType) {
      case MyButton.bandingButton:
        return "Banding";
      case MyButton.discountButton:
        return "Discount";
      case MyButton.returnButton:
        return "Return";
      case MyButton.splitButton:
        return "Split";
      case MyButton.noActionButton:
        return "No Actions";
      default:
        return "";
    }
  }

  void createDataList() {
    detailsList.clear();
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);

    for (var product in products) {
      if (product.status != "Initial") {
        double discountValue = 0.0;
        if (product.status == 'Discount') {
          try {
            discountValue = double.parse(product.discountValue);
          } catch (e) {
            print('Error parsing discount value: $e');
          }
        }

        // List<Map<String, dynamic>> splitDetailsMaps = splitProvider
        //     .getSplitDetails(product.itemID)
        //     ?.map((splitDetail) => splitDetail.toMap())
        //     .toList() ?? [];

        detailsList.add({
          "Id": product.productId,
          "SiNo": product.siNo,
          "Qty": product.qty,
          "Banding": product.status == 'Banding' ? true : false,
          "Discount": product.status == 'Discount' ? true : false,
          "Return": product.status == 'Return' ? true : false,
          "Split": product.status == 'Split' ? true : false,
          // "No Actions": product.status == 'No Actions',
          "DiscountMode":
              product.discountMode == DiscountMode.percentage
                  ? 'Percentage'
                  : 'Amount',
          // "DiscountValue": product.discountValue,
          "DiscountAmount": product.discountAmount,
          "DiscountPercentage": product.discountPercentage,
          "Approved": false,
          "Rejected": false,
          "DiscPerc": product.discountPercentage,
          // "SplitDetails": splitDetailsMaps,
        });
      }
    }
    print("DetailsList FAHAL SALAM .......:>>>$detailsList");
  }

  // Helper method to get split details maps for a product
  List<Map<String, dynamic>> getSplitDetailsMapsByItemId(
    dynamic itemId,
    dynamic SiNo,
  ) {
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);

    return splitProvider
            .getSplitDetails(itemId, SiNo)
            ?.map((splitDetail) => splitDetail.toMap())
            .toList() ??
        [];
  }

  Widget _buildDetailCard(info.Datum detail) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 5,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 4.0,
            horizontal: 4.0,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Quantity : ${detail.qty}",
                style: TextStyle(fontSize: 11.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                'Reason: ${detail.reason}',
                style: TextStyle(fontSize: 11.sp),
              ),
              SizedBox(height: 4.h),
              Text('Note: ${detail.note}', style: TextStyle(fontSize: 11.sp)),
              SizedBox(height: 4.h),
              Text(
                "Expiry Date : ${detail.date ?? "N/A"}",
                style: TextStyle(fontSize: 11.sp),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}
