import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merchandiser_clone/screens/salesman_screens/sales_man_navigation.dart';
import 'package:merchandiser_clone/screens/salesman_screens/salesman_bottom_navbar.dart';

class DynamicAlertBox {
  void showPopUpForSaving(
    context,
    String content,
    String btnText1,
    String btnText2,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Column(children: [Text(content)]),
          actions: [
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
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Request Updated Successfully"),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder
                                >(
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
                                Navigator.pop(context);

                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const SalesManBottomNavBar(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: Text("OK"),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(btnText1),
            ),
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
                Navigator.of(context).pop();
              },
              child: Text(btnText2),
            ),
          ],
        );
      },
    );
  }

  void logOut(context, String message, VoidCallback onTap) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Column(
            children: [
              Text(message, style: TextStyle(fontSize: 12.sp)),
              SizedBox(height: 5.h),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: ButtonStyle(
                    side: MaterialStateProperty.all(
                      const BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ), // Set the border color and width
                    ),
                  ),
                  onPressed: onTap,
                  child: Text("Yes"),
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
                  child: Text("No"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
