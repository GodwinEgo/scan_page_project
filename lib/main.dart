import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

void main() => runApp(const ScanPageApp());

class ScanPageApp extends StatelessWidget {
  const ScanPageApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scan Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ScanPage(),
    );
  }
}

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);
  @override
  ScanPageState createState() => ScanPageState();
}

class ScanPageState extends State<ScanPage> {
  String _scanResult = 'No scan result yet';

  Future<void> _scanBarcode() async {
    String scanResult;

    try {
      scanResult = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', // Custom color for the scanner overlay
        'Cancel', // Button text to cancel the scan
        true, // Whether to show flash icon
        ScanMode.BARCODE, // Specify the scan mode (e.g., QR_CODE, BARCODE)
      );
    } catch (e) {
      scanResult = 'Failed to get the scan result: $e';
    }

    if (!mounted) return;

    setState(() {
      _scanResult = scanResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _scanResult,
              style: const TextStyle(fontSize: 18.0),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _scanBarcode,
              child: const Text('Scan Barcode'),
            ),
          ],
        ),
      ),
    );
  }
}
