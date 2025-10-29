import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BleConnectionState { disconnected, connecting, connected, disconnecting }

class BleController extends ChangeNotifier {
  // MODIFIÉ : On stocke les ScanResult pour avoir accès au RSSI.
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // --- AJOUTS POUR LE FILTRAGE ---
  String _filterText = "";

  // Getter qui retourne la liste des appareils filtrée.
  List<ScanResult> get filteredScanResults {
    if (_filterText.isEmpty) {
      return scanResults;
    } else {
      // Filtre les résultats dont le nom de l'appareil contient le texte du filtre (insensible à la casse)
      return scanResults
          .where((result) => result.device.platformName
              .toLowerCase()
              .contains(_filterText.toLowerCase()))
          .toList();
    }
  }

  // Méthode pour mettre à jour le texte du filtre depuis l'UI.
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
      debugPrint("État de l'adaptateur Bluetooth : $state");
      if (state != BluetoothAdapterState.on) {
        _resetConnection();
      }
      notifyListeners();
    });
  }

  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    bool granted = statuses[Permission.bluetoothScan]!.isGranted &&
                   statuses[Permission.bluetoothConnect]!.isGranted &&
                   statuses[Permission.location]!.isGranted;
    if (!granted) {
      debugPrint("Permissions manquantes !");
    }
    return granted;
  }

  void startScan() async {
    if (!await checkPermissions() || isScanning || _adapterState != BluetoothAdapterState.on) {
      debugPrint("Impossible de scanner : Permissions manquantes, scan en cours ou Bluetooth éteint.");
      return;
    }

    scanResults.clear(); // MODIFIÉ : Vider la liste des résultats de scan.
    isScanning = true;
    notifyListeners();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      // MODIFIÉ : Logique pour ajouter/mettre à jour les résultats dans la liste.
      for (ScanResult r in results) {
        // Trouve l'index d'un résultat existant pour le même appareil.
        int index = scanResults.indexWhere((res) => res.device.remoteId == r.device.remoteId);
        if (index != -1) {
          // Si l'appareil est déjà dans la liste, on met à jour le résultat.
          scanResults[index] = r;
        } else {
          // Sinon, on l'ajoute.
          if(r.device.platformName.isNotEmpty) {
             scanResults.add(r);
          }
        }
      }
      notifyListeners();
    }, onError: (e) => debugPrint("Erreur de scan: $e"));

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10)); // Durée augmentée un peu

    isScanning = false;
    await _scanSubscription?.cancel();
    notifyListeners();
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    _scanSubscription?.cancel();
    notifyListeners();
  }

  // Le reste des méthodes (connect, disconnect, etc.) reste inchangé.
  Future<void> connect(BluetoothDevice device) async { /* ... code inchangé ... */ }
  Future<void> disconnect() async { /* ... code inchangé ... */ }
  Future<void> _discoverServices() async { /* ... code inchangé ... */ }
  void _resetConnection() { /* ... code inchangé ... */ }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    super.dispose();
  }
}