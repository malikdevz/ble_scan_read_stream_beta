import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../controllers/ble_controller.dart';
import '../widgets/device_tile.dart';
import 'device_detail_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser 'watch' pour que l'UI se reconstruise lors des notifications
    final ble = context.watch<BleController>();
    // Utiliser 'read' pour appeler des fonctions sans reconstruire
    final bleReader = context.read<BleController>();

    return Scaffold(
      appBar: AppBar(title: const Text('BLE Scanner')),
      body: Column(
        children: [
          // --- WIDGET POUR L'ÉTAT DU BLUETOOTH ---
          if (ble.adapterState == BluetoothAdapterState.off)
            Container(
              color: Colors.red.withOpacity(0.9),
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              child: const Text(
                'Bluetooth is turned off. Please enable it.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          // --- CHAMP DE TEXTE POUR LE FILTRAGE ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Filter by device name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: bleReader.updateFilter, // Appelle la méthode du contrôleur
            ),
          ),

          // --- BOUTON DE SCAN ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
              // Désactive le bouton si le scan est en cours ou si le bluetooth est éteint
              onPressed: (ble.isScanning || ble.adapterState != BluetoothAdapterState.on)
                  ? null
                  : bleReader.startScan,
              child: Text(ble.isScanning ? 'Scanning in progress...' : 'Start Scan'),
            ),
          ),

          const SizedBox(height: 10),

          // --- LISTE DES APPAREILS FILTRÉS ---
          Expanded(
            // Utilise la liste filtrée du contrôleur
            child: ble.filteredScanResults.isEmpty
                ? const Center(child: Text('No devices found'))
                : ListView.builder(
                    itemCount: ble.filteredScanResults.length,
                    itemBuilder: (context, index) {
                      final result = ble.filteredScanResults[index];
                      return DeviceTile(
                        result: result, // Passe le ScanResult complet
                        onTap: () {
                          bleReader.stopScan(); // Bonne pratique : arrêter le scan avant de naviguer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeviceDetailScreen(device: result.device),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}