import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merchandiser_clone/provider/salesman_request_provider.dart';
import 'package:merchandiser_clone/screens/salesman_screens/api_service/salesman_api_service.dart';
import 'package:merchandiser_clone/screens/salesman_screens/model/salesman_request_list_model.dart';
import 'package:merchandiser_clone/screens/salesman_screens/request_details_screen.dart';
import 'package:merchandiser_clone/screens/splash_screen.dart';
import 'package:merchandiser_clone/utils/dynamic_alert_box.dart';
import 'package:merchandiser_clone/utils/willpop.dart';
import 'package:provider/provider.dart';

class SalesmanHomeScreen extends StatefulWidget {
  const SalesmanHomeScreen({super.key});

  @override
  State<SalesmanHomeScreen> createState() => _SalesmanHomeScreenState();
}

final SalesManApiService apiService = SalesManApiService();
late Future<SalesmanRequestListModel> salesRequestList;
late Willpop willpop;

class _SalesmanHomeScreenState extends State<SalesmanHomeScreen> {
  @override
  void initState() {
    super.initState();
    willpop = Willpop(context);
    _refreshData();
    salesRequestList = apiService.getSalesmanRequestList();
  }

  Future<void> _refreshData() async {
    setState(() {
      salesRequestList = SalesManApiService().getSalesmanRequestList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Design size of your mockup
      builder: (context, child) {
        return WillPopScope(
          onWillPop: () async {
            return willpop.onWillPop();
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.brown,
              automaticallyImplyLeading: false,
              title: Text(
                "Home",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 15.w),
                  child: GestureDetector(
                    onTap: () {
                      DynamicAlertBox().logOut(
                        context,
                        "Do you Want to Logout",
                        () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => SplashScreen(),
                            ),
                          );
                        },
                      );
                    },
                    child: CircleAvatar(radius: 22.r, child: Text("SM")),
                  ),
                ),
              ],
            ),
            resizeToAvoidBottomInset: false,
            body: RefreshIndicator(
              onRefresh: _refreshData,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
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
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "Request",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Expanded(
                          child: Consumer<SalesManRequestProvider>(
                            builder: (
                              context,
                              salesmanRequestProductsProvider,
                              _,
                            ) {
                              return FutureBuilder(
                                future: salesRequestList,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Text("Error: ${snapshot.error}"),
                                    );
                                  } else {
                                    List<Datum> datums = snapshot.data!.data;
                                    if (datums.isEmpty) {
                                      return Center(
                                        child: Text("No Request Available"),
                                      );
                                    }
                                    return ListView.builder(
                                      itemCount: datums.length,
                                      itemBuilder: (context, index) {
                                        String selectedVendorName =
                                            datums[index].vendorName;
                                        String selectedVendortId =
                                            datums[index].vendorId.toString();
                                        String selectedProductQuantity =
                                            datums[index].totalProduct
                                                .toString();
                                        int requesId = datums[index].requestId;
                                        String productFirstLetter =
                                            selectedVendorName.substring(0, 1);
                                        String date = datums[index].date;

                                        return Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 8.h,
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey
                                                          .withOpacity(0.5),
                                                      spreadRadius: 2,
                                                      blurRadius: 5,
                                                      offset: Offset(0, 3),
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    ListTile(
                                                      leading: CircleAvatar(
                                                        backgroundColor:
                                                            Colors.brown,
                                                        child: Text(
                                                          productFirstLetter,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      title: Text(
                                                        selectedVendorName,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16.sp,
                                                        ),
                                                      ),
                                                      subtitle: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            selectedVendortId,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                          Text(
                                                            date,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Divider(
                                                      color: Colors.grey,
                                                      thickness: 1.h,
                                                      indent: 16.w,
                                                      endIndent: 16.w,
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.all(
                                                        8.w,
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                selectedProductQuantity,
                                                                style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      28.sp,
                                                                  color:
                                                                      Colors
                                                                          .brown,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 10.w,
                                                              ),
                                                              Text(
                                                                "Products",
                                                                style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      18.sp,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                            width: 150.w,
                                                            child: TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                  context,
                                                                ).push(
                                                                  MaterialPageRoute(
                                                                    builder: (
                                                                      context,
                                                                    ) {
                                                                      return RequestDetailsScreen(
                                                                        vendorName:
                                                                            selectedVendorName,
                                                                        vendorId:
                                                                            selectedVendortId,
                                                                        requestId:
                                                                            requesId,
                                                                      );
                                                                    },
                                                                  ),
                                                                );
                                                              },
                                                              child: Text(
                                                                "Details",
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .brown,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              style: ButtonStyle(
                                                                padding: MaterialStateProperty.all(
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        10.h,
                                                                  ),
                                                                ),
                                                                side: MaterialStateProperty.all<
                                                                  BorderSide
                                                                >(
                                                                  BorderSide(
                                                                    color:
                                                                        Colors
                                                                            .brown,
                                                                    width:
                                                                        1.0.w,
                                                                  ),
                                                                ),
                                                                shape: MaterialStateProperty.all<
                                                                  OutlinedBorder
                                                                >(
                                                                  RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10.r,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
