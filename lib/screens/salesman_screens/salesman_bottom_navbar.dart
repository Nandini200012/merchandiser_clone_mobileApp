import 'package:flutter/material.dart';
import 'package:merchandiser_clone/screens/salesman_screens/api_service/salesman_api_service.dart';
import 'package:merchandiser_clone/screens/salesman_screens/model/salesman_request_list_model.dart';
import 'package:merchandiser_clone/screens/salesman_screens/salesman_dashboard_screen.dart';
import 'package:merchandiser_clone/screens/salesman_screens/salesman_home_screen.dart';

class SalesManBottomNavBar extends StatefulWidget {
  const SalesManBottomNavBar({super.key});

  @override
  State<SalesManBottomNavBar> createState() => _SalesManBottomNavBarState();
}

class _SalesManBottomNavBarState extends State<SalesManBottomNavBar> {
  int currentIndex = 0;
  late Future<SalesmanRequestListModel> salesRequestList;
  final SalesManApiService apiService = SalesManApiService();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
    return Scaffold(
      backgroundColor: Colors.brown,
      body: IndexedStack(
        index: currentIndex,
        children: const [SalesmanHomeScreen(), SalesmanDashboardScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.brown,
        selectedItemColor: Colors.white,
        elevation: 0,
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            backgroundColor: Colors.blue,
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.brown,
            icon: Icon(Icons.space_dashboard),
            label: '',
          ),
        ],
      ),
    );
  }
}
