// To parse this JSON data, do
//
//     final reportDetailsListModel = reportDetailsListModelFromJson(jsonString);

import 'dart:convert';

ReportDetailsListModel reportDetailsListModelFromJson(String str) =>
    ReportDetailsListModel.fromJson(json.decode(str));

String reportDetailsListModelToJson(ReportDetailsListModel data) =>
    json.encode(data.toJson());

class ReportDetailsListModel {
  bool isSuccess;
  String message;
  List<Datum> data;

  ReportDetailsListModel({
    required this.isSuccess,
    required this.message,
    required this.data,
  });

  factory ReportDetailsListModel.fromJson(Map<String, dynamic> json) =>
      ReportDetailsListModel(
        isSuccess: json["isSuccess"],
        message: json["message"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "isSuccess": isSuccess,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class Datum {
  dynamic prdouctId;
  String prdouctName;
  num quantity;
  String expiryDate;
  String note;
  String reason;
  String reqStatus;
  dynamic uom;
  dynamic cost;

  Datum({
    required this.prdouctId,
    required this.prdouctName,
    required this.quantity,
    required this.expiryDate,
    required this.note,
    required this.reason,
    required this.reqStatus,
    required this.uom,
    required this.cost,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        prdouctId: json["prdouctID"],
        prdouctName: json["prdouctName"],
        quantity: json["quantity"],
        expiryDate: json["expiryDate"],
        note: json["note"],
        reason: json["reason"],
        reqStatus: json["reqStatus"],
        uom: json["UOM"],
        cost: json["Cost"],
      );

  Map<String, dynamic> toJson() => {
        "prdouctID": prdouctId,
        "prdouctName": prdouctName,
        "quantity": quantity,
        "expiryDate": expiryDate,
        "note": note,
        "reason": reason,
        "reqStatus": reqStatus,
        "UOM": uom,
        "Cost": cost,
      };
}
