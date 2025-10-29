import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceDetailScreen extends StatelessWidget {
  final BluetoothDevice device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    // MODIFIÉ : Utilisation de platformName pour la cohérence
    final deviceName = device.platformName.isEmpty ? 'Unknown Device' : device.platformName;

    return Scaffold(
      appBar: AppBar(title: Text(deviceName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $deviceName', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('ID: ${device.remoteId}', style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}