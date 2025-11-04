# Flutter BLE Scanner by Malik

This project is a mobile application developed with Flutter that allows scanning, connecting to, and interacting with nearby Bluetooth Low Energy (BLE) devices.

**Author:** malik

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [Application Logic](#application-logic)
- [Contributing](#contributing)
- [License](#license)

## Overview

The application provides a simple interface to detect and display information about surrounding BLE devices. Users can filter devices by type, search by name, and connect to connectable devices to discover and interact with their services and characteristics.

## Features

*   **Scan for BLE Devices**: Detects nearby BLE devices and displays their name, ID, and signal strength (RSSI).
*   **Permission Management**: Checks and requests the necessary permissions for Bluetooth and location services.
*   **Filtering and Searching**:
    *   Filters devices by predefined categories (All, Audio Devices, Smartwatches).
    *   Searches for devices by their name.
*   **Connection and Disconnection**: Connects to connectable BLE devices and manages the connection state.
*   **Automatic Reconnection**: Attempts to automatically reconnect if the connection is lost.
*   **Service Discovery**: Displays the services and characteristics of a connected device.
*   **Characteristic Interaction**: Allows reading, writing, and subscribing to notifications from characteristics.
*   **Reactive UI**: The user interface updates in real-time based on the scan state, connection status, and permissions.

## Prerequisites

To build and run this project, you will need:
*   Flutter SDK (version 3.0.0 or higher)
*   A code editor like Android Studio or VS Code
*   A physical Android or iOS device with Bluetooth enabled (emulators may not fully support all BLE features).

## Installation

1.  **Clone the repository:**
    ```bash
    git clone <REPOSITORY_URL>
    cd ble_scanner
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```

## Project Structure

The project is structured as follows for better organization and maintainability:

```
lib/
├── controllers/
│   └── ble_controller.dart     # Business logic for BLE management
├── screens/
│   ├── device_detail_screen.dart # Screen for device details
│   └── scan_screen.dart        # Main screen for scanning devices
├── widgets/
│   └── device_tile.dart        # Widget to display a device in the list
└── main.dart                 # Application entry point
```

## Dependencies

This project uses the following packages:

*   **`flutter_blue_plus`**: For managing Bluetooth Low Energy functionalities.
*   **`provider`**: For application state management.
*   **`permission_handler`**: For handling runtime permissions.
*   **`cupertino_icons`**: For iOS-style icons.

All dependencies are listed in the `pubspec.yaml` file.

## Application Logic

The application's architecture is based on the `Provider` pattern for state management.

### `BleController`

This is the core of the application. This class, which extends `ChangeNotifier`, handles:
*   The state of the Bluetooth adapter.
*   The scanning process (start, stop, results).
*   Permission management.
*   Connecting, disconnecting, and automatically reconnecting to a device.
*   Discovering services and characteristics.
*   Search filters.

### Screens

*   **`ScanScreen`**: The main screen that allows the user to start and stop the scan, apply filters, and view the list of detected devices. It reacts to state changes from the `BleController`.
*   **`DeviceDetailScreen`**: Displays detailed information about a selected device, allows connecting/disconnecting, and, once connected, lists and interacts with its services.

### Widgets

*   **`DeviceTile`**: A reusable widget that displays basic information of a scanned device (name, ID, signal strength) in a list.

## Contributing

Contributions are welcome. To contribute, please follow these steps:
1.  Fork the project.
2.  Create a feature branch (`git checkout -b feature/NewFeature`).
3.  Commit your changes (`git commit -m 'Add some NewFeature'`).
4.  Push to the branch (`git push origin feature/NewFeature`).
5.  Open a Pull Request.

## License

This project is distributed under the MIT License. See the `LICENSE` file for more details.