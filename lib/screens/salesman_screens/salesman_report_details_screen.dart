import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merchandiser_clone/screens/manager_screens/api_service/manager_api_service.dart';
import 'package:merchandiser_clone/screens/manager_screens/model/report_details_list_model.dart';
import 'package:merchandiser_clone/screens/salesman_screens/salesman_dashboard_screen.dart';
import 'package:merchandiser_clone/utils/willpop.dart';
import 'package:super_banners/super_banners.dart';

class SalesManReportDetailsScreen extends StatefulWidget {
  final int requestId;
  final Status selectedStatus;
  const SalesManReportDetailsScreen({
    super.key,
    required this.requestId,
    required this.selectedStatus,
  });

  @override
  State<SalesManReportDetailsScreen> createState() =>
      _SalesManReportDetailsScreenState();
}

class _SalesManReportDetailsScreenState
    extends State<SalesManReportDetailsScreen> {
  ManagerApiService apiService = ManagerApiService();
  Future<ReportDetailsListModel>? reportDetailsListFuture;
  late Willpop willpop;
  @override
  void initState() {
    super.initState();
    willpop = Willpop(context);
    reportDetailsListFuture = fetchData();
    print("object:>>>${widget.requestId}");
    print("object:>>>${widget.selectedStatus}");
  }

  Future<ReportDetailsListModel> fetchData() async {
    final filterMode = getStatusString(widget.selectedStatus);

    try {
      EasyLoading.show(
        status: "Loading...",
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
      );
      return await apiService.fetchReportDetailsList(
        reportListMode: "SM",
        filterMode: filterMode,
        requestID: widget.requestId,
      );
    } catch (e) {
      rethrow;
    } finally {
      EasyLoading.dismiss();
    }
  }

  String getStatusString(Status status) {
    switch (status) {
      case Status.banding:
        return "B";
      case Status.discount:
        return "D";
      case Status.returning:
        return "R";
      default:
        return "";
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
          backgroundColor: Colors.brown,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text(
            "Request Details",
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
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
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: FutureBuilder<ReportDetailsListModel>(
                    future: reportDetailsListFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container();
                      } else if (snapshot.hasError) {
                        return Text("Error : ${snapshot.error}");
                      } else if (!snapshot.hasData || snapshot.data == null) {
                        return const Center(
                          child: const Text('No data available!!'),
                        );
                      } else {
                        ReportDetailsListModel reportDetailsListModel =
                            snapshot.data!;
                        return reportDetailsListModel.data.isEmpty
                            ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Text("No data available")],
                            )
                            : ListView.builder(
                              itemCount:
                                  reportDetailsListModel.data.length ?? 0,
                              itemBuilder: (context, index) {
                                Datum data = reportDetailsListModel.data[index];
                                return Stack(
                                  children: [
                                    Card(
                                      elevation: 4,
                                      child: ListTile(
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Barcode : ${data.prdouctId}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 10.sp,
                                              ),
                                            ),
                                            Text(
                                              "Product Name : ${data.prdouctName}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 10.sp,
                                              ),
                                            ),
                                            Text(
                                              "Quantity : ${data.quantity.toStringAsFixed(2)}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 10.sp,
                                              ),
                                            ),
                                            Text(
                                              "Expiry Date : ${data.expiryDate}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 10.sp,
                                              ),
                                            ),
                                            Text(
                                              "Note : ${data.note.isNotEmpty ? data.note : "N/A"}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 10.sp,
                                              ),
                                            ),
                                            Text(
                                              "Reason : ${data.reason.isNotEmpty ? data.reason : "N/A"}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 10.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 5,
                                      top: 5,
                                      child: CornerBanner(
                                        bannerPosition:
                                            CornerBannerPosition.topRight,
                                        bannerColor: Colors.black.withOpacity(
                                          0.8,
                                        ),
                                        child: Text(
                                          data.reqStatus,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
    );
  }
}
