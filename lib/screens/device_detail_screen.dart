import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../controllers/ble_controller.dart';

class DeviceDetailScreen extends StatelessWidget {
  final ScanResult result;

  const DeviceDetailScreen({super.key, required this.result});

  // BUILD DEVICE INFO WIDGETS
  Widget _buildDeviceInfoCard(BuildContext context, BleController ble, BleController bleReader, BluetoothDevice device) {
    final deviceName = device.platformName.isEmpty ? 'Unknown Device' : device.platformName;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(deviceName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue.shade900), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('ID: ${device.remoteId}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('RSSI: ${result.rssi} dBm', style: TextStyle(fontSize: 14, color: Colors.grey.shade700), textAlign: TextAlign.center),
            if (ble.mtu != 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('MTU Size: ${ble.mtu} bytes', style: TextStyle(fontSize: 14, color: Colors.grey.shade700), textAlign: TextAlign.center),
              ),
            const SizedBox(height: 20),
            if(ble.isOnRetry)
            Text(
               'Trying to reconnect, Attempt number ${(3-ble.retry_connection)} in progress…',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            Text(
              ble.connectionState == BleConnectionState.connected ? 'Connected' : ble.connectionState == BleConnectionState.connecting ? 'Connecting...' : ble.connectionState == BleConnectionState.disconnecting ? 'Disconnecting...' : 'Disconnected',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ble.connectionState == BleConnectionState.connected ? Colors.green : ble.connectionState == BleConnectionState.connecting ? Colors.grey : ble.connectionState == BleConnectionState.disconnecting ? Colors.grey : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if(result.advertisementData.connectable)
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40), backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: ble.connectionState == BleConnectionState.connecting ? null : ble.connectionState == BleConnectionState.connected ? bleReader.disconnect : () => bleReader.connect(device),
              child: Text(ble.connectionState == BleConnectionState.connecting ? 'PLEASE WAIT...' : ble.connectionState == BleConnectionState.connected ? 'DISCONNECT' : 'CONNECT TO DEVICE'),
            ),
            if(!result.advertisementData.connectable)
            Text(
               'This Device is an advertising only (beacons, trackers) - Not connectable.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: 15,
              ),
            ),
            if(ble.showfeebck)
            Text(
               'Fail to connect but try again, if persist this device not able to receive connection by now',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BUILD DEVICE SERVICE WIDGETS
Widget _buildServicesCard(BuildContext context, BleController ble) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Device Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue.shade900), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            if(ble.connectionState != BleConnectionState.connected && result.advertisementData.connectable)
            Text('You must be connected to device to see the services lists', style: TextStyle(fontSize: 14, color: Colors.grey.shade700), textAlign: TextAlign.center),
            if(!result.advertisementData.connectable)
            Text('This device is not connectable', style: TextStyle(fontSize: 14, color: Colors.grey.shade700), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            
            if (ble.connectionState == BleConnectionState.connected && ble.services.isNotEmpty)
              ListView(
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(),
                children: ble.services.map((service) {
                  return ExpansionTile(
                    title: Text('Service UUID => ${service.uuid}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    children: service.characteristics.map((c) {
                      return ListTile(
                        title: Text('Characteristic UUID => ${c.uuid}'),
                        subtitle: Row(
                          children: [
                            if (c.properties.read) TextButton(onPressed: () async => await c.read(), child: const Text('Read')),
                            if (c.properties.write) TextButton(onPressed: () async => await c.write([0x01]), child: const Text('Write')),
                            if (c.properties.notify) TextButton(onPressed: () async => await c.setNotifyValue(!c.isNotifying), child: const Text('Subscribe')),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              )
            else if (ble.connectionState == BleConnectionState.connected && ble.services.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Center(child: Text('No services found')),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleController>();
    final bleReader = context.read<BleController>();
    final device = result.device;
    final deviceName = device.platformName.isEmpty ? 'Unknown Device' : device.platformName;

    return Scaffold(
      appBar: AppBar(title: Text(deviceName)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildDeviceInfoCard(context, ble, bleReader, device),
              const SizedBox(height: 12),
              _buildServicesCard(context, ble),
            ],
          ),
        ),
      ),
    );
  }
}