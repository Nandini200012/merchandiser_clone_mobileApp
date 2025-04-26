import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merchandiser_clone/provider/split_provider.dart';
import 'package:merchandiser_clone/screens/salesman_screens/request_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:merchandiser_clone/screens/salesman_screens/model/discount_mode.dart';

class SplitScreen extends StatefulWidget {
  final Product product;
  final Function(Product) onSplitSave;
  final String screenMode;

  const SplitScreen({
    Key? key,
    required this.product,
    required this.onSplitSave,
    required this.screenMode,
  }) : super(key: key);

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  TextEditingController _splitQtyController = TextEditingController();
  TextEditingController _discountController = TextEditingController();
  DiscountMode _splitDiscountMode = DiscountMode.percentage;
  String _splitStatus = 'Banding';
  List<SplitDetail> splitDetails = [];
  dynamic totalSplitQty = 0;
  dynamic availableQty = 0;

  @override
  void initState() {
    super.initState();
    availableQty = widget.product.qty;
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    splitDetails =
        splitProvider.getSplitDetails(
          widget.product.itemID,
          widget.product.siNo,
        ) ??
        [];
    totalSplitQty = splitDetails.fold(
      0,
      (sum, detail) => sum + detail.splitQty,
    );
    availableQty = widget.product.qty - totalSplitQty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Split Quantity'),
        backgroundColor:
            widget.screenMode == 'SalesMan'
                ? Colors.brown
                : Color.fromARGB(255, 207, 68, 18),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Total Quantity: ${widget.product.qty}',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Available Quantity: $availableQty',
                      style: TextStyle(fontSize: 14.sp, color: Colors.green),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: _splitQtyController,
                      decoration: InputDecoration(
                        labelText: 'Enter split quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16.h),
                    DropdownButton<String>(
                      value: _splitStatus,
                      items:
                          <String>['Banding', 'Discount', 'Return'].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _splitStatus = newValue!;
                        });
                      },
                    ),
                    if (_splitStatus == 'Discount')
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Percentage',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                              Switch(
                                value:
                                    _splitDiscountMode == DiscountMode.amount,
                                onChanged: (value) {
                                  setState(() {
                                    _splitDiscountMode =
                                        value
                                            ? DiscountMode.amount
                                            : DiscountMode.percentage;
                                  });
                                },
                              ),
                              Text('Amount', style: TextStyle(fontSize: 12.sp)),
                            ],
                          ),
                          TextField(
                            controller: _discountController,
                            decoration: InputDecoration(
                              labelText:
                                  _splitDiscountMode == DiscountMode.percentage
                                      ? 'Enter Discount %'
                                      : 'Enter Discount Amount',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    SizedBox(height: 16.h),
                    Center(
                      child: FloatingActionButton(
                        onPressed: _handleAddSplit,
                        child: Icon(Icons.add, color: Colors.white),
                        backgroundColor: Colors.brown,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView.builder(
                itemCount: splitDetails.length,
                itemBuilder: (context, index) {
                  final split = splitDetails[index];
                  return Card(
                    margin: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 8.w,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        'Qty: ${split.splitQty}, Status: ${split.splitStatus}',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      subtitle:
                          split.splitStatus == 'Discount'
                              ? Text(
                                '${split.discountMode == DiscountMode.percentage ? 'Discount Percentage: ${split.discountPercentage.toStringAsFixed(3)}%' : 'Discount Amount: ${split.discountAmount.toStringAsFixed(3)}'}',
                                style: TextStyle(fontSize: 12.sp),
                              )
                              : null,
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeSplit(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _handleSplitSave,
          child: Text('Save Splits', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown,
            padding: EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAddSplit() {
    int splitQty = int.tryParse(_splitQtyController.text) ?? 0;
    double discountValue = double.tryParse(_discountController.text) ?? 0;

    if (splitQty <= 0) {
      _showError('Split quantity must be greater than zero.');
      return;
    }

    if (totalSplitQty + splitQty > widget.product.qty) {
      _showError('Total split quantity cannot exceed available quantity.');
      return;
    }

    if (_splitStatus == 'Discount' &&
        _splitDiscountMode == DiscountMode.percentage &&
        (discountValue < 0 || discountValue > 100)) {
      _showError('Discount percentage must be between 0 and 100.');
      return;
    }

    double discountAmount =
        _splitDiscountMode == DiscountMode.percentage
            ? (widget.product.cost ?? 0) * (discountValue / 100)
            : discountValue;
    double discountPercentage =
        _splitDiscountMode == DiscountMode.percentage
            ? discountValue
            : (discountValue / (widget.product.cost ?? 1)) * 100;

    setState(() {
      splitDetails.add(
        SplitDetail(
          widget.product.itemID,
          widget.product.siNo, // Include product ID
          splitQty,
          _splitStatus,
          discountValue: _splitStatus == 'Discount' ? discountValue : 0,
          discountMode: _splitDiscountMode,
          discountAmount: _splitStatus == 'Discount' ? discountAmount : 0,
          discountPercentage:
              _splitStatus == 'Discount' ? discountPercentage : 0,
        ),
      );
      totalSplitQty += splitQty;
      availableQty -= splitQty;
      _splitQtyController.clear();
      _discountController.clear();
      _splitDiscountMode = DiscountMode.percentage;
      _splitStatus = 'Banding';
    });
  }

  void _removeSplit(int index) {
    setState(() {
      totalSplitQty -= splitDetails[index].splitQty;
      availableQty += splitDetails[index].splitQty;
      splitDetails.removeAt(index);
    });
  }

  void _handleSplitSave() {
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    splitProvider.updateSplitDetails(
      widget.product.itemID,
      widget.product.siNo,
      splitDetails,
    );
    setState(() {
      widget.product.status = 'Split';
      // widget.product.qty -= totalSplitQty;
    });

    widget.onSplitSave(widget.product);
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
