import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;

  const DeviceTile({super.key, required this.result, required this.onTap});

  // SIGNAL STRENGH COLOR
  Color _getSignalColor(int rssi) {
    if (rssi > -70) {
      return Colors.green; // STRONG 
    } else if (rssi > -90) {
      return Colors.orange; // MIDDLE
    } else {
      return Colors.red; // WEAK
    }
  }

  @override
  Widget build(BuildContext context) {
    //GET PLATFORMNAME
    final deviceName = result.device.platformName.isEmpty
        ? 'Unknown Device'
        : result.device.platformName;

    return ListTile(
      title: Text(deviceName),
      subtitle: Text(result.device.remoteId.toString()),
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