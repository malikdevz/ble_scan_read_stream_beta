import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BleConnectionState { disconnected, connecting, connected, disconnecting }

class BleController extends ChangeNotifier {
  // --- PRINCIPLES VARIABLES ---
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  String scanStateLabel = "Click on Start Scan button to detect nearby BLE devices!";
  bool blePermissions = true;
  int mtu = 0;
  int retry_connection=3;
  bool isOnRetry=false;
  bool showfeebck=false;

  // --- STREAMS ET FILTERS ---
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  String _filterText = "";
  String deviceTypeFilter = 'All';

  // --- CONSTANTES  ---
  static const AUDIO_UUID = '0000110B-0000-1000-8000-00805F9B34FB';

  // --- BLUETOOTH STATE---
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothDevice? connectedDevice;
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  List<BluetoothService> services = [];

  // --- GETTERS ---
  BluetoothAdapterState get adapterState => _adapterState;
  BleConnectionState get connectionState => _connectionState;

  // --- CONSTRUCTOR ---
  BleController() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      debugPrint("Bluetooth state changed: $state");

      if (state != BluetoothAdapterState.on) {
        _resetConnection();
      }

      checkPermissions().then((_) => notifyListeners());
      notifyListeners();
    });
  }

  // --- FILTERS ---
  void updateDeviceTypeFilter(String filter) {
    deviceTypeFilter = filter;
    notifyListeners();
  }
   void updateFilter(String text) {
    print(text);
    _filterText = text;
    notifyListeners();
  }

  List<ScanResult> get filteredScanResults {
    var results = scanResults;
    // by nom
    if (_filterText.isNotEmpty) {
      results = results
          .where((r) => r.device.name.toLowerCase().contains(_filterText.toLowerCase()))
          .toList();
      //we should not apply filter by name for device without name
      results=results+scanResults
          .where((r) => r.device.platformName.isEmpty)
          .toList();
    }

    // by device type
    if (deviceTypeFilter == 'Audio Devices') {
      results = results
          .where((r) => r.advertisementData.serviceUuids.contains(AUDIO_UUID))
          .toList();
    } else if (deviceTypeFilter == 'Smartwatches') {
      results = results
          .where((r) => r.device.name.toLowerCase().contains('watch'))
          .toList();
    }

    return results;
  }

  // --- PERMISSIONS ---
  Future<bool> checkAndAskPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final granted = statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted &&
        statuses[Permission.location]!.isGranted;

    if (!granted) {
      debugPrint("Missing one or more permissions!");
    }

    return granted;
  }

  Future<void> checkPermissions() async {
    final scanGranted = await Permission.bluetoothScan.isGranted;
    final connectGranted = await Permission.bluetoothConnect.isGranted;
    final locationGranted = await Permission.location.isGranted;

    blePermissions = scanGranted && connectGranted && locationGranted;

    if (!blePermissions) {
      debugPrint("User didn't allow one or more necessary permissions");
    } else {
      debugPrint("All permissions granted");
    }
  }

  void requestPermission() async {
    blePermissions = await checkAndAskPermissions();
    notifyListeners();
  }

  // --- SCAN ---
  void startScan() async {
    // Réinitialise filtres
    updateDeviceTypeFilter('All');
    updateFilter("");

    if (!await checkAndAskPermissions() || isScanning || _adapterState != BluetoothAdapterState.on) {
      debugPrint("Can't start scan: missing permissions, already scanning, or Bluetooth disabled.");
      return;
    }

    scanResults.clear();
    isScanning = true;
    scanStateLabel = "Scan in progress...";
    notifyListeners();

    // Écoute les résultats du scan
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });

    // Lance le scan pendant 10 secondes
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    // Surveille la fin du scan via le stream officiel
    FlutterBluePlus.isScanning.listen((scanning) {
      isScanning = scanning;
      if (!scanning) {
        final count = scanResults.length;
        scanStateLabel = "Scan complete: $count devices found.";
        _scanSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    _scanSubscription?.cancel();
    scanStateLabel = "Click on Start Scan button to detect nearby BLE devices!";
    notifyListeners();
  }

  // --- CONNECT / DESCONNECT---
  Future<void> connect(BluetoothDevice device) async {
    _connectionState = BleConnectionState.connecting;
    notifyListeners();

    try {
      await device.connect();
      mtu = await device.mtu.first;
      if(connectedDevice != device && connectedDevice != null){
        retry_connection=3;
      }
      connectedDevice = device;
      _connectionState = BleConnectionState.connected;

      _connectionStateSubscription = device.connectionState.listen((state) {

        if (state == BluetoothConnectionState.disconnected) {
          if(retry_connection > 0){
            try{
              retry_connection--;
              isOnRetry=true;
              notifyListeners();
              //connection lost retry to connect
              connect(device);
              Future.delayed(const Duration(seconds:3), (){
                isOnRetry=false;
                notifyListeners();
              });
            }catch(e){
              print(e);
            }
            
          }else{
            _resetConnection();
          }
          
        }
      });

      await _discoverServices();
    } catch (e) {
      debugPrint("Failed to connect: $e");
      showfeebck=true;
      Future.delayed(const Duration(seconds:5), (){
        showfeebck=false;
        notifyListeners();
      });
      _resetConnection();
    }

    notifyListeners();
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      _connectionState = BleConnectionState.disconnecting;
      await connectedDevice!.disconnect();
       _connectionState = BleConnectionState.disconnected;
      connectedDevice=null;
      retry_connection=0;
      _resetConnection();
       notifyListeners();
    }
  }

  Future<void> _discoverServices() async {
    if (connectedDevice == null) return;
    services = await connectedDevice!.discoverServices();
    notifyListeners();
  }

  void _resetConnection() {
    if (_connectionState == BleConnectionState.disconnected) return;

    connectedDevice = null;
    services.clear();
    _connectionState = BleConnectionState.disconnected;
    _connectionStateSubscription?.cancel();
    notifyListeners();
  }

  // --- CLEAN ---
  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    super.dispose();
  }
}
