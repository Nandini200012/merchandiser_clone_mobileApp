import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String) onScan;

  const QRScannerWidget({Key? key, required this.onScan}) : super(key: key);

  @override
  _QRScannerWidgetState createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
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
