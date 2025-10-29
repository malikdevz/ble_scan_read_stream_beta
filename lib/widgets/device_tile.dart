import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceTile extends StatelessWidget {
  // MODIFIÉ : On attend un ScanResult pour avoir le RSSI
  final ScanResult result;
  final VoidCallback onTap;

  const DeviceTile({super.key, required this.result, required this.onTap});

  // Fonction pour déterminer la couleur de l'icône du signal
  Color _getSignalColor(int rssi) {
    if (rssi > -70) {
      return Colors.green; // Signal fort
    } else if (rssi > -90) {
      return Colors.orange; // Signal moyen
    } else {
      return Colors.red; // Signal faible
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utilise platformName qui est souvent plus fiable
    final deviceName = result.device.platformName.isEmpty
        ? 'Unknown Device'
        : result.device.platformName;

    return ListTile(
      title: Text(deviceName),
      subtitle: Text(result.device.remoteId.toString()),
      // Affiche l'icône de signal avec la couleur et la valeur RSSI
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.signal_cellular_alt,
            color: _getSignalColor(result.rssi),
          ),
          const SizedBox(width: 8),
          Text('${result.rssi} dBm'),
        ],
      ),
      onTap: onTap,
    );
  }
}