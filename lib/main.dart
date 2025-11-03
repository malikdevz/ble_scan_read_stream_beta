import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/ble_controller.dart';
import 'screens/scan_screen.dart';

void main() {


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLE Scanner',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const ScanScreen(),
    );
  }
}
