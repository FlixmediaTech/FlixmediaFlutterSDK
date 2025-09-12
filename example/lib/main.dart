import 'package:flutter/material.dart';
import 'package:flix_inpage/flix_inpage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlixBridge.initialize(
    username: 'flixmediaqa',
    password: r'FlixQa99&$',
  );
  runApp(const MaterialApp(home: HomePage()));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product name')),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Product Name",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "\$99",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            FlixInpageHtmlView(
              productParams: {
                "mpn": "OLED77B3PUA.AUS",
                "ean": "cache003",
                "distributorId": 6,
                "isoCode": "us",
                "flIsoCode": "en",
              },
              baseURL: "https://demo.flix360.io",
            ),
          ],
        ),
      ),

      // --- Bottom View ---
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: ElevatedButton(
            onPressed: () {
              //
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Buy Now',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
