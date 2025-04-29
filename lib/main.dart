import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:merchandiser_clone/provider/create_request_vendor_detals.dart';
import 'package:merchandiser_clone/provider/product_details_provider.dart';
import 'package:merchandiser_clone/provider/provider_cart.dart';
import 'package:merchandiser_clone/provider/provider_cart_details.dart';
import 'package:merchandiser_clone/provider/salesman_request_provider.dart';
import 'package:merchandiser_clone/provider/salesperson_provider.dart';
import 'package:merchandiser_clone/provider/selection_provider.dart';
import 'package:merchandiser_clone/provider/split_provider.dart';
import 'package:merchandiser_clone/screens/splash_screen.dart';
import 'package:merchandiser_clone/provider/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final cartProvider = CartProvider();
  final createRequestVendorDetails = CreateRequestVendorDetailsProvider();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShopList()),
        ChangeNotifierProvider(create: (_) => Cart()),
        ChangeNotifierProvider(create: (_) => SalesPersonDetailsProvider()),
        ChangeNotifierProvider(create: (_) => ProductDetailsProvider()),
        ChangeNotifierProvider(create: (_) => SalesManRequestProvider()),
        ChangeNotifierProvider(create: (_) => SelectionProvider()),
        ChangeNotifierProvider.value(value: cartProvider),
        ChangeNotifierProvider.value(value: createRequestVendorDetails),
        ChangeNotifierProvider(create: (_) => SplitProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 740),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          title: 'Marchandiser',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            scaffoldBackgroundColor: Colors.grey.shade200,
            useMaterial3: true,
          ),
          builder: EasyLoading.init(),
          home: const SplashScreen(),
        );
      },
    );
  }
}
