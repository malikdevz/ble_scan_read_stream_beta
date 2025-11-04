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
    // reactive provider watch
    final ble = context.watch<BleController>();
    // Static provider read
    final bleReader = context.read<BleController>();
    //filters list
    final Map<String, String?> filters = {
      'All': null,
      'Audio Devices': 'Audio Devices', // UUID Audio Sink
      'Smartwatches': 'WATCH', // "WATCH"
    };

    return Scaffold(
      appBar: AppBar(title: const Text('BLE Scanner')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- BLE Adapter state ---
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
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                      ),
                      onPressed: bleReader.requestPermission,
                      child: const Text('Grant permissions'),
                    ),
                  ],
                ),
              ),

            // --- Results control ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Controls',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          //filter by widget
                          const Text(
                            'Filter by:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<String>(
                              value: ble.deviceTypeFilter,
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
                              underline: Container(height: 1, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      //search by name widget
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Search device by name',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                        ),
                        onChanged: bleReader.updateFilter,
                      ),
                      const Divider(height: 30, thickness: 1),
                      if (ble.blePermissions)
                        Column(
                          children: [
                            Text(
                              ble.scanStateLabel,
                              style: TextStyle(
                                color: ble.isScanning ? Colors.blue.shade900 : Colors.grey.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: (ble.adapterState != BluetoothAdapterState.on)
                                  ? null
                                  : ble.isScanning
                                      ? bleReader.stopScan
                                      : bleReader.startScan,
                              child: Text(ble.isScanning ? 'STOP SCAN' : 'START SCAN'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            const Divider(indent: 20, endIndent: 20),

            // if no device found
            if (ble.filteredScanResults.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: ble.isScanning
                    ? const Center(child: CircularProgressIndicator())
                    : const Center(child: Text('No devices found')),
              )
            else
              ListView.builder(
                // display devices list
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: ble.filteredScanResults.length,
                itemBuilder: (context, index) {
                  final result = ble.filteredScanResults[index];
                  return DeviceTile(
                    result: result,
                    onTap: () {
                      bleReader.stopScan();
                      ble.disconnect();
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
          ],
        ),
      ),
    );
  }
}