import 'package:flutter/material.dart';
import 'package:merchandiser_clone/screens/model/Vendors.dart';

class CreateRequestVendorDetailsProvider with ChangeNotifier {
  int? _vendorId;
  String? _vendorName;
  int? _salesPerson;
  String? _salesPersonName;
  String? _mobile;
  int? get vendorId => _vendorId;
  String? get vendorName => _vendorName;
  int? get salesPerson => _salesPerson;
  String? get salesPersonName => _salesPersonName;

  void setVendorDetails(int vendorId, String vendorName, int salesPerson,
      String salesPersonName, String mobile) {
    _vendorId = vendorId;
    _vendorName = vendorName;
    _salesPerson = salesPerson;
    _salesPersonName = salesPersonName;
    _mobile = mobile;
    notifyListeners();
  }

  void clearVendorDetails() {
    _vendorId = null;
    _vendorName = null;
    _salesPerson = null;
    _salesPersonName = null;
    notifyListeners();
  }

  Vendors getVendor() {
    return Vendors(
      vendorId: _vendorId!,
      vendorName: _vendorName ?? "unknown",
      vendorCode: _vendorId?.toString() ?? "0",
      mobileNo: _mobile ?? "000000000",
      salesPerson: _salesPerson,
      salesPersonName: _salesPersonName,
    );
  }
}
