import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BleConnectionState { disconnected, connecting, connected, disconnecting }

class BleController extends ChangeNotifier {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  String scanStateLabel = "Click on StartScan button to detect nearby BLE devices!";
  String deviceConnectState="Disconnectd";
  //BluetoothDevice device;
  bool blePermissions = true; // Assume true initially, will be checked.


  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // --- AJOUTS POUR LE FILTRAGE ---
  String _filterText = "";
  String deviceTypeFilter = 'All';

  void updateDeviceTypeFilter(String filter) {
    deviceTypeFilter = filter;
    notifyListeners();
  }

  // Dans filteredScanResults :
  List<ScanResult> get filteredScanResults {
    var results = scanResults;
    
    // Filtre par nom
    if (_filterText.isNotEmpty) {
      results = results.where((r) => r.device.name.toLowerCase().contains(_filterText.toLowerCase())).toList();
    }

    // Filtre par type
    if (deviceTypeFilter == 'Audio Devices') {
      results = results.where((r) => r.advertisementData.serviceUuids.contains('0000110B-0000-1000-8000-00805F9B34FB')).toList();
    } else if (deviceTypeFilter == 'Smartwatches') {
      results = results.where((r) => r.device.name.toLowerCase().contains('watch')).toList();
    }

    return results;
  }


  /*List<ScanResult> get filteredScanResults {
    if (_filterText.isEmpty) {
      return scanResults;
    } else {
      return scanResults
          .where((result) => result.device.platformName
              .toLowerCase()
              .contains(_filterText.toLowerCase()))
          .toList();
    }
  }*/

  void updateFilter(String text) {
    _filterText = text;
    notifyListeners();
  }

  // --- Le reste de la classe (gestion de la connexion, état, etc.) ---
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  BluetoothDevice? connectedDevice;
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  List<BluetoothService> services = [];

  BluetoothAdapterState get adapterState => _adapterState;
  BleConnectionState get connectionState => _connectionState;

  BleController() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      debugPrint("On start Bluetooth state: $state");
      if (state != BluetoothAdapterState.on) {
        _resetConnection(); // Now correctly inside the class
      }
      checkPermissions().then((_) { // Use then with _ as we don't need the return value here
        notifyListeners();
      });
      notifyListeners();
    });
  }

  // Check and ask for permissions
  Future<bool> checkAndAskPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    bool granted = statuses[Permission.bluetoothScan]!.isGranted &&
                   statuses[Permission.bluetoothConnect]!.isGranted &&
                   statuses[Permission.location]!.isGranted;
    if (!granted) {
      debugPrint("Missing permissions !");
    }
    return granted;
  }

  // Use to check permission without ask for them
  Future<void> checkPermissions() async {
    bool scanGranted = await Permission.bluetoothScan.isGranted;
    bool connectGranted = await Permission.bluetoothConnect.isGranted;
    bool locationGranted = await Permission.location.isGranted;

    if (!scanGranted || !connectGranted || !locationGranted) {
      debugPrint("Users didn't allow one or more necessary permissions");
      blePermissions = false;
    } else {
      debugPrint("All permissions granted");
      blePermissions = true;
    }
  }

  // Marked as async
  void requestPermission() async {
    bool result = await checkAndAskPermissions();
    blePermissions = result; // No need for ternary if it's already a bool
    notifyListeners();
  }

  void startScan() async {
    //initialise filter and search by name
    deviceTypeFilter='All';
    updateFilter("");
    if (!await checkAndAskPermissions() || isScanning || _adapterState != BluetoothAdapterState.on) {
      debugPrint("Can't scan, no permissions or there is other scan on process or ble is disabled");
      return;
    }
    scanResults.clear();
    isScanning = true;
    scanStateLabel = "Scan on process....";
    notifyListeners();

    // Start listening for scan results FIRST
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });

    // Then start the scan itself
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    // The scan will automatically stop after 10 seconds due to the timeout
    // We can then update the UI state.
    // It's better to listen to FlutterBluePlus.isScanning stream for accurate state,
    // but for simplicity, we'll use a delayed future matching the scan timeout.
    // A more robust solution would be to listen to FlutterBluePlus.isScanning.
    Future.delayed(const Duration(seconds: 11), () { // A little after the scan timeout
      if (isScanning) { // Only update if still scanning (not manually stopped)
        isScanning = false;
        int nbrDevicesFounded = scanResults.length;
        scanStateLabel = "Scan Terminated, $nbrDevicesFounded Devices founded";
        _scanSubscription?.cancel(); // Cancel subscription when scan is done
        notifyListeners();
      }
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    _scanSubscription?.cancel(); // Ensure subscription is cancelled
    scanStateLabel = "Click on StartScan button to detect nearby BLE devices!";
    notifyListeners();
  }

  // Le reste des méthodes (connect, disconnect, etc.)
  Future<void> connect(BluetoothDevice device) async {
    // ... code inchangé ...
    /*_connectionState = BleConnectionState.connecting;
    notifyListeners();
    try {
      await device.connect();
      connectedDevice = device;
      _connectionState = BleConnectionState.connected;
      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _resetConnection();
        }
      });
      await _discoverServices();
    } catch (e) {
      debugPrint("Failed to connect: $e");
      _resetConnection();
    }
    notifyListeners();*/
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      _connectionState = BleConnectionState.disconnecting;
      notifyListeners();
      await connectedDevice!.disconnect();
      _resetConnection();
    }
    notifyListeners();
  }

  Future<void> _discoverServices() async {
    if (connectedDevice == null) return;
    services = await connectedDevice!.discoverServices();
    notifyListeners();
  }

  void _resetConnection() {
    connectedDevice = null;
    services.clear();
    _connectionState = BleConnectionState.disconnected;
    _connectionStateSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    super.dispose();
  }
}