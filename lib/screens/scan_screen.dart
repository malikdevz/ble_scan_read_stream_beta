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
    // Watch pour reconstruire l'UI lors des notifications
    final ble = context.watch<BleController>();
    // Read pour appeler des fonctions sans reconstruire
    final bleReader = context.read<BleController>();
    // Liste de filtres possibles
    final Map<String, String?> filters = {
      'All': null, // Aucun filtre
      'Audio Devices': '110B', // UUID Audio Sink
      'Smartwatches': 'WATCH', // On peut filtrer par nom contenant "WATCH"
    };


    return Scaffold(
      appBar: AppBar(title: const Text('BLE Scanner')),
      body: Column(
        children: [
          // --- État du Bluetooth ---
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

          // --- Permissions ---
          if (!ble.blePermissions)
            Container(
              color: Colors.red.withOpacity(0.9),
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'All the requested permissions are necessary for the proper functioning of the application and are used solely for that purpose, so you must grant them.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                    onPressed: ble.blePermissions ? null : bleReader.requestPermission,
                    child: const Text('Grant permissions'),
                  ),
                ],
              ),
            ),

          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Filter by:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: ble.deviceTypeFilter, // variable du controller
                      items: filters.keys.map((filter) {
                        return DropdownMenuItem<String>(
                          value: filter,
                          child: Text(filter),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          bleReader.updateDeviceTypeFilter(value);
                        }
                      },
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
            ),
          // --- Champ de filtrage ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search a device name in list',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: bleReader.updateFilter,
            ),
          ),

          // --- Scan State + Bouton Start/Stop ---
          if (ble.blePermissions)
            Container(
              color: Colors.blue.withOpacity(0.9),
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ble.scanStateLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                    onPressed: (ble.adapterState != BluetoothAdapterState.on)
                        ? null
                        : ble.isScanning
                            ? bleReader.stopScan
                            : bleReader.startScan,
                    child: Text(ble.isScanning ? 'Stop Scan' : 'Start Scan'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // --- Liste des appareils filtrés ---
          Expanded(
            child: ble.filteredScanResults.isEmpty
                ? ble.isScanning
                    ? const Center(child: CircularProgressIndicator())
                    : const Center(child: Text('No devices found'))
                : ListView.builder(
                    itemCount: ble.filteredScanResults.length,
                    itemBuilder: (context, index) {
                      final result = ble.filteredScanResults[index];
                      return DeviceTile(
                        result: result,
                        onTap: () {
                          bleReader.stopScan();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeviceDetailScreen(result: result),
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
