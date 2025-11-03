import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../controllers/ble_controller.dart';

class DeviceDetailScreen extends StatefulWidget {
  final ScanResult result;

  const DeviceDetailScreen({super.key, required this.result});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  BluetoothDevice? device;
  List<BluetoothService> services = [];
  bool isConnected = false;
  bool isConnectable=false;
  bool onConnecting=false;
  String connectionStateLabel ="Disconnected";
  int mtu = 0;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  @override
  void initState() {
    super.initState();
    device = widget.result.device;
    isConnectable=widget.result.advertisementData.connectable;
    _listenToConnection(); // 👈 écouter l’état dès le départ
  }



  void _listenToConnection() {
    _connectionSub = device!.connectionState.listen((state) {
      setState(() => isConnected = state == BluetoothConnectionState.connected);

      if (state == BluetoothConnectionState.disconnected) {
        setState(() => connectionStateLabel ="Disconnected");
        setState(() => isConnected = false);
        _getServices();
        //here we can retry to reconnect
        /*ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device disconnected'),
            backgroundColor: Colors.red,
          ),
        );*/
      }
    });
  }

  Future<void> _connectToDevice() async {
    if(isConnectable){
      try{
        setState(() => onConnecting = true);
        setState(() => connectionStateLabel ="Connecting...please wait!");
        await device!.connect(timeout: const Duration(seconds: 5));
        mtu = await device!.mtu.first;
        setState(() => onConnecting = false);
        setState(() => isConnected = true);
        setState(() => connectionStateLabel = "Connected");
        _getServices();
      }catch(e){
        setState(() => onConnecting = false);
        setState(() => isConnected = false);
        debugPrint('❌ Connection failed: $e');
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      setState(() => connectionStateLabel = "Disconnecting...please wait!");
      await device!.disconnect();
      setState(() => isConnected = false);
      setState(() => connectionStateLabel = "Disconnected!");
      _getServices();
    } catch (e) {
      debugPrint('⚠️ Disconnect error: $e');
    }
  }

  Future<void> _getServices() async {
    final s = await device!.discoverServices();
    setState(() => services = s);
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceName =device!.platformName.isEmpty ? 'Unknown Device' : device!.platformName;
    final ble = context.watch<BleController>();
    

    return Scaffold(
      appBar: AppBar(
        title: Text(deviceName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Bloc d’état et boutons ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueGrey.shade200),
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('${device!.remoteId}',
                        style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 13, color: Colors.blue)),
                    const SizedBox(height: 8),
                    Text('RSSI: ${widget.result.rssi} dBm',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    if (mtu != 0)
                      Text('MTU Size: $mtu bytes',
                          style: const TextStyle(fontSize: 14)),

                    const SizedBox(height: 16),
                    if(isConnectable)
                      Text(
                        connectionStateLabel,
                        style: TextStyle(
                          color: onConnecting ? Colors.grey:isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if(!isConnectable)
                        Text(
                          "This device is an advertising only (probably a beacons, trackers, or broadcasting) no possible connection",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                    const SizedBox(height: 8),
                    if(isConnectable)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                      onPressed: onConnecting ? null: isConnected ? _disconnect : _connectToDevice,
                      child: Text(onConnecting ? 'PLEASE WAIT': isConnected ? 'DISCONNECT' : 'CONNECT TO DEVICE'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---Device services ---
              if(isConnectable && isConnected)
                Text(
                  "Services list",
                    textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

              const SizedBox(height: 16),

              // --- Liste des services découverts ---
              ...services.map(_buildServiceTile).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTile(BluetoothService service) {
    return ExpansionTile(
      title: Text(
        'Service UUID => ${service.uuid}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: service.characteristics.map(_buildCharacteristicTile).toList(),
    );
  }

  Widget _buildCharacteristicTile(BluetoothCharacteristic c) {
    return ListTile(
      title: Text('Characteristic UUID => ${c.uuid}'),
      subtitle: Row(
        children: [
          if (c.properties.read)
            TextButton(onPressed: () async => await c.read(), child: const Text('Read')),
          if (c.properties.write)
            TextButton(onPressed: () async => await c.write([0x01]), child: const Text('Write')),
          if (c.properties.notify)
            TextButton(
              onPressed: () async => await c.setNotifyValue(!c.isNotifying),
              child: const Text('Subscribe'),
            ),
        ],
      ),
    );
  }
}
