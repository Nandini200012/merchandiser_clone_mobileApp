import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutterMaterial;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:merchandiser_clone/model/report_list_model.dart';
import 'package:merchandiser_clone/screens/manager_screens/api_service/manager_api_service.dart';
import 'package:merchandiser_clone/screens/salesman_screens/salesman_report_details_screen.dart';
import 'package:merchandiser_clone/screens/splash_screen.dart';
import 'package:merchandiser_clone/utils/avatharmenu.dart';
import 'package:merchandiser_clone/utils/dynamic_alert_box.dart';
import 'package:merchandiser_clone/utils/willpop.dart';

class SalesmanDashboardScreen extends StatefulWidget {
  const SalesmanDashboardScreen({super.key});

  @override
  State<SalesmanDashboardScreen> createState() =>
      _SalesmanDashboardScreenState();
}

class _SalesmanDashboardScreenState extends State<SalesmanDashboardScreen> {
  final ManagerApiService apiService = ManagerApiService();
  Faker faker = Faker();
  DateTime _selectedDate = DateTime.now();
  DateTime currentDate = DateTime.now();
  Data? reportListData;
  Status selectedStatus = Status.banding;
  late Willpop willpop;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    willpop = Willpop(context);
    fetchData("B");
  }

  void fetchData(String filterMode) async {
    try {
      final reportList = await apiService.getReportList(
        fromDate: _selectedDate.toString() ?? currentDate.toString(),
        toDate: _selectedDate.toString() ?? currentDate.toString(),
        reportListMode: "SM",
        filterMode: filterMode,
        pageNo: 1,
      );

      setState(() {
        reportListData = reportList.data;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return willpop.onWillPop();
      },
      child: Scaffold(
        // backgroundColor: Color(0xffedf2fb),
        appBar: AppBar(
          backgroundColor: Colors.brown,
          automaticallyImplyLeading: false,
          elevation: 0,
          // backgroundColor: Color(0xffedf2fb),
          title: const Text(
            "Reports",
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 15),
              child:
              // AvatarWithMenu(txt: "SM",)
              GestureDetector(
                onTap: () {
                  DynamicAlertBox().logOut(
                    context,
                    "Do you Want to Logout",
                    () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => SplashScreen()),
                      );
                    },
                  );
                },
                child: CircleAvatar(radius: 22, child: Text("SM")),
              ),
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white, // Top color
                Colors.white, // New middle color (white)
                Colors.white, // New middle color (white)
                Colors.white, // New middle color (white)
                Colors.white, // New middle color (white)
                Colors.white, // Bottom color
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: SafeArea(
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      _selectDate(context, selectedStatus);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: 50,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          TextButton(
                            child: Text(
                              _selectedDate == null
                                  ? DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(DateTime.now()).toString()
                                  : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDate!),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                            ),
                            onPressed: () {
                              _selectDate(context, selectedStatus);
                            },
                          ),
                          const Spacer(),
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.calendar_month,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10, width: double.infinity),
                  Row(
                    children: [
                      buildStatusCard(Status.banding, "Banding", "B"),
                      SizedBox(width: 10),
                      buildStatusCard(Status.discount, "Discount", "D"),
                      SizedBox(width: 10),
                      buildStatusCard(Status.returning, "Return", "R"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.brown,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        tileColor: Colors.brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color:
                                Colors.brown, // Adjust border color as needed
                            width: 1.0, // Set border width
                          ),
                        ),
                        leadingAndTrailingTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10.0,
                            left: 10,
                          ),
                          child: Text(
                            "Req No",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        title: Container(
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 10.0,
                                  left: 10,
                                ),
                                child: Text(
                                  "Date",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Expanded(child: const SizedBox(width: 10)),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 10.0,
                                    left: 10,
                                  ),
                                  child: Text(
                                    "Name",
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(child: const SizedBox(width: 20)),
                              Expanded(child: const SizedBox(width: 20)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  buildListViewForStatus(Status.banding),
                  buildListViewForStatus(Status.discount),
                  buildListViewForStatus(Status.returning),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _selectDate(BuildContext context, Status status) async {
    String filterMode;

    switch (status) {
      case Status.banding:
        filterMode = "B";
        break;
      case Status.discount:
        filterMode = "D";
        break;
      case Status.returning:
        filterMode = "R";
        break;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 2 * 365)),
      lastDate: DateTime(DateTime.now().year + 10),
    );

    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _selectedDate = picked;
      });
      fetchData(filterMode);
      return picked;
    }
    return null;
  }

  Widget buildStatusCard(Status status, String title, String filterMode) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedStatus = status;
            fetchData(filterMode);
            print("Status: >>> $selectedStatus");
          });
        },
        child: flutterMaterial.Card(
          child: Container(
            decoration: BoxDecoration(
              color: selectedStatus == status ? Colors.brown : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 5.h),
                Text(
                  title,
                  style: TextStyle(
                    color:
                        selectedStatus == status ? Colors.white : Colors.brown,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  getStatusValue(status),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color:
                        selectedStatus == status ? Colors.white : Colors.brown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getStatusValue(Status status) {
    switch (status) {
      case Status.banding:
        return reportListData?.cards[0].bandig.toString() ?? "0";
      case Status.discount:
        return reportListData?.cards[0].discount.toString() ?? "0";
      case Status.returning:
        return reportListData?.cards[0].cardReturn.toString() ?? "0";
      default:
        return "0";
    }
  }

  Widget buildListViewForStatus(Status status) {
    return selectedStatus == status
        ? reportListData == null || reportListData!.details.isEmpty
            ? const Expanded(child: Center(child: Text("No Data")))
            : Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reportListData?.details.length,
                itemBuilder: (context, index) {
                  return buildListTile(index, reportListData?.details[index]);
                },
              ),
            )
        : Container(); // Return an empty container if status is not selected
  }

  Widget buildListTile(int index, Detail? detailData) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => SalesManReportDetailsScreen(
                  requestId: reportListData!.details[index].requestId,
                  selectedStatus: selectedStatus,
                ),
          ),
        );
      },
      child: flutterMaterial.Card(
        color: Colors.white,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          // visualDensity: VisualDensity.comfortable,
          dense: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              detailData?.requestId.toString() ?? "",
              style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
            ),
          ),
          title: Container(
            // height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 10.w),
                Text(
                  detailData?.date ?? "",
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    detailData?.vendorName ?? "",
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum Status { banding, discount, returning }
