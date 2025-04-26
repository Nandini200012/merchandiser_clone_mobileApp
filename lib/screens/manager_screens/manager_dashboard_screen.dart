import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutterMaterial;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:merchandiser_clone/model/report_list_model.dart';
import 'package:merchandiser_clone/screens/manager_screens/api_service/manager_api_service.dart';
import 'package:merchandiser_clone/screens/manager_screens/manager_report_details.dart';
import 'package:merchandiser_clone/screens/splash_screen.dart';
import 'package:merchandiser_clone/utils/dynamic_alert_box.dart';
import 'package:merchandiser_clone/utils/willpop.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final ManagerApiService apiService = ManagerApiService();

  DateTime _selectedDate = DateTime.now();
  DateTime currentDate = DateTime.now();
  Data? reportListData;
  Status selectedStatus = Status.approved;
  late Willpop willpop;
  bool isLoading = false; // Add this line

  @override
  void initState() {
    super.initState();
    willpop = Willpop(context);
    fetchData("A");
  }

  void fetchData(String filterMode) async {
    setState(() {
      isLoading = true; // Set loading to true before fetching data
    });

    try {
      final reportList = await apiService.getReportList(
        fromDate: _selectedDate.toString() ?? currentDate.toString(),
        toDate: _selectedDate.toString() ?? currentDate.toString(),
        reportListMode: "MG",
        filterMode: filterMode,
        pageNo: 1,
      );

      setState(() {
        reportListData = reportList.data;
        isLoading = false; // Set loading to false after data is fetched
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false; // Set loading to false if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return willpop.onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 207, 68, 18),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            "Reports",
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
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
                        MaterialPageRoute(builder: (context) => SplashScreen()),
                      );
                    },
                  );
                },
                child: CircleAvatar(radius: 20.r, child: Text("MGR")),
              ),
            ),
          ],
        ),
        body:
            isLoading // Check if loading is true
                ? Center(child: CircularProgressIndicator()) // Show loader
                : Container(
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
                          SizedBox(height: 5.h, width: double.infinity),
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
                                          ).format(_selectedDate),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15.sp,
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
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              buildStatusCard(Status.approved, "Approved", "A"),
                              const SizedBox(width: 10),
                              buildStatusCard(Status.reject, "Reject", "R"),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 0.0),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 207, 68, 18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                tileColor: Color.fromARGB(255, 207, 68, 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                    color: Color(
                                      0xff023e8a,
                                    ), // Adjust border color as needed
                                    width: 1.0, // Set border width
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 10.0,
                                    left: 10,
                                  ),
                                  child: Text(
                                    "Req No",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                                title: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 10.0,
                                    left: 10,
                                  ),
                                  child: SizedBox(
                                    height: 40,
                                    width: double.infinity,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0,
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
                                        Expanded(child: SizedBox(width: 8)),
                                        Expanded(
                                          child: Text(
                                            "Name",
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: SizedBox(width: 8)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          buildListViewForStatus(Status.approved),
                          buildListViewForStatus(Status.reject),
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
      case Status.approved:
        filterMode = "A";
        break;
      case Status.reject:
        filterMode = "R";
        break;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 2 * 365)),
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
              border: Border.all(color: const Color(0xff023e8a)),
              color:
                  selectedStatus == status
                      ? Color.fromARGB(255, 207, 68, 18)
                      : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 3.h),
                Text(
                  title,
                  style: TextStyle(
                    color:
                        selectedStatus == status
                            ? Colors.white
                            : Color.fromARGB(255, 207, 68, 18),
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  getStatusValue(status),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color:
                        selectedStatus == status
                            ? Colors.white
                            : Color.fromARGB(255, 207, 68, 18),
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
      case Status.approved:
        return reportListData?.cards[0].approved.toString() ?? "0";
      case Status.reject:
        return reportListData?.cards[0].reject.toString() ?? "0";

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
                (context) => ManagerReportDetails(
                  requestId: detailData!.requestId,
                  selectedStatus: selectedStatus,
                ),
          ),
        );
      },
      child: flutterMaterial.Card(
        color: Colors.white,
        child: ListTile(
          dense: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text(
              detailData?.requestId.toString() ?? "",
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xff023e8a),
              ),
            ),
          ),
          title: SizedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 10.w),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Text(
                    detailData?.date ?? "",
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff023e8a),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    detailData?.vendorName ?? "",
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff023e8a),
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

enum Status { approved, reject }
