import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merchandiser_clone/screens/manager_screens/manager_bottom_navbar.dart';
import 'package:merchandiser_clone/screens/marchandiser_screens/marchendiser_bottomnav.dart';
import 'package:merchandiser_clone/screens/marchandiser_screens/marchendiser_dashboard_screen.dart';
import 'package:merchandiser_clone/screens/salesman_screens/salesman_bottom_navbar.dart';
import 'package:merchandiser_clone/utils/SharedPreferencesUtil.dart';
import 'package:merchandiser_clone/utils/constants.dart';
import 'package:merchandiser_clone/utils/urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool remember = prefs.getBool("rememberMe") ?? false;

    if (remember) {
      String? username = prefs.getString("rememberedUsername");
      String? password = prefs.getString("rememberedPassword");

      if (username != null && password != null) {
        usernameController.text = username;
        passwordController.text = password;
        rememberMe = true;
      }
    }
  }

  Future<void> _signIn() async {
    try {
      EasyLoading.show(
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
        status: "Please Wait",
      );

      String enteredUsername = usernameController.text;
      String enteredPassword = passwordController.text;

      var url = Uri.parse(Urls.login);

      var response = await http.get(
        url,
        headers: {'UserID': enteredUsername, 'Password': enteredPassword},
      );

      print("Response:>>>$response");

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['isSuccess']) {
          var data = jsonResponse['data'][0];
          String userId = data['UserId'];
          int employeeId = data['EmployeeId'];
          String appRole = data['App_Role'];

          await SharedPreferencesUtil.setUserDetails(
            userId,
            employeeId,
            appRole,
          );

          if (rememberMe) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setBool("rememberMe", true);
            prefs.setString("rememberedUsername", enteredUsername);
            prefs.setString("rememberedPassword", enteredPassword);
          } else {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setBool("rememberMe", false);
            prefs.remove("rememberedUsername");
            prefs.remove("rememberedPassword");
          }
          _navigateToUserScreen(appRole);
        } else {
          _showErrorDialog('Invalid Login Credential.');
        }
      } else {
        _showErrorDialog('Failed to authenticate. Please try again.');
      }
    } catch (error) {
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      EasyLoading.dismiss();
    }
  }

  void _navigateToUserScreen(String appRole) {
    switch (appRole) {
      case "Merchandiser":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MarchendiserDashboardScreen(),
            // const MarchendiserBottomNavigation(),
          ),
        );
        break;
      // case "SalesMan":
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => const SalesManBottomNavBar()),
      //   );
      //   break;
      // case "Manager":
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => const ManagerBottomNavBar()),
      //   );
      //   break;
      default:
        _showErrorDialog('Invalid login credentials!');
        break;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
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
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final paddingHorizontal = screenWidth * 0.1; // 10% of the screen width
    final paddingVertical = screenHeight * 0.05; // 5% of the screen height

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              // Color.fromARGB(255, 11, 38, 60),
              Colors.white
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              // padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: screenHeight * 0.47,
                              width: double.infinity,
                              color: Constants.primaryColor,
                            ),
                            Positioned(
                              top: screenHeight * .26,
                              left: screenWidth * .02,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Merchandiser',
                                    style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  SizedBox(
                                    height: 10.h,
                                  ),
                                  Text(
                                    'Sign in to your ',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 25.sp,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Account',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 25.sp,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Text(
                        //   "Sign In",
                        //   style: TextStyle(
                        //     fontSize: 30,
                        //     fontWeight: FontWeight.bold,
                        //     color: Colors.white,
                        //     shadows: [
                        //       Shadow(
                        //         blurRadius: 10.0,
                        //         color: Colors.black45,
                        //         offset: Offset(2.0, 2.0),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        SizedBox(height: 40.h),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 24.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            // boxShadow: [
                            //   BoxShadow(
                            //     color: Colors.black.withOpacity(0.1),
                            //     blurRadius: 10,
                            //     spreadRadius: 5,
                            //   ),
                            // ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: usernameController,
                                decoration: InputDecoration(
                                  fillColor: Colors.grey[200],
                                  filled: true,
                                  labelText: 'Username',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                  prefixIcon: Icon(Icons.person,
                                      color: Colors.grey.shade700),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              PasswordField(controller: passwordController),
                              const SizedBox(height: 16.0),
                              Row(
                                children: [
                                  Checkbox(
                                    activeColor: Colors.purple.shade300,
                                    value: rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        rememberMe = value!;
                                      });
                                    },
                                  ),
                                  const Text(
                                    "Remember me",
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 69, 68, 68)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24.0),
                              SizedBox(
                                width: double.infinity,
                                child: Material(
                                  elevation: 3,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.purple,
                                          Colors.purple,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _signIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20.0,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "Login",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  const PasswordField({Key? key, required this.controller}) : super(key: key);

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        fillColor: Colors.grey[200],
        filled: true,
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(
          Icons.lock,
          color: Colors.grey.shade600,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
          ),
          onPressed: _togglePasswordVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
