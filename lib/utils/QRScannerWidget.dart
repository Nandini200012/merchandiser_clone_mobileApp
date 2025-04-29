import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String) onScan;

  const QRScannerWidget({Key? key, required this.onScan}) : super(key: key);

  @override
  _QRScannerWidgetState createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  final MobileScannerController controller = MobileScannerController();
  String? errorText; // To show error if any

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleError(MobileScannerException error) {
    String message = "An unknown error occurred.";
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = "Camera permission denied.";
        break;
      case MobileScannerErrorCode.permissionDenied:
        message =
            "Camera permission permanently denied. Please enable it from settings.";
        break;
      case MobileScannerErrorCode.genericError:
      default:
        message = error.errorDetails.toString() ?? "Unknown scanner error.";
    }
    setState(() {
      errorText = message;
    });
    controller.stop(); // Stop scanning on error
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final String? code = barcode.rawValue;
                      if (code != null) {
                        widget.onScan(code);
                        controller.stop(); // Stop the scanner after detecting
                        break;
                      }
                    }
                  },
                  errorBuilder: (context, error, child) {
                    _handleError(error);
                    return Center(
                      child: Text(
                        errorText ?? "Scanner error",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  },
                ),
                if (errorText != null)
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.black54,
                      child: Text(
                        errorText!,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.stop();
              Navigator.pop(context);
            },
            child: Text("Close Scanner"),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// class QRScannerWidget extends StatefulWidget {
//   final Function(String) onScan;

//   const QRScannerWidget({Key? key, required this.onScan}) : super(key: key);

//   @override
//   _QRScannerWidgetState createState() => _QRScannerWidgetState();
// }

// class _QRScannerWidgetState extends State<QRScannerWidget> {
//   MobileScannerController controller = MobileScannerController();

//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: MediaQuery.of(context).size.height * 0.8,
//       child: Column(
//         children: [
//           Expanded(
//             flex: 4,
//             child: MobileScanner(
//               controller: controller,
//               onDetect: (capture) {
//                 final List<Barcode> barcodes = capture.barcodes;
//                 for (final barcode in barcodes) {
//                   final String? code = barcode.rawValue;
//                   if (code != null) {
//                     widget.onScan(code);
//                     controller.stop(); // Stop the scanner after detecting
//                     break;
//                   }
//                 }
//               },
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               controller.stop();
//               Navigator.pop(context);
//             },
//             child: Text("Close Scanner"),
//           ),
//         ],
//       ),
//     );
//   }
// }
