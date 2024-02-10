import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:plugin_wifi_connect/plugin_wifi_connect.dart';
import 'package:wifi_iot/wifi_iot.dart';
// import 'package:plugin_wifi_connect/plugin_wifi_connect.dart';

import 'package:wifi_scan/wifi_scan.dart';

class Wifiscreen extends StatefulWidget {
  const Wifiscreen({Key? key}) : super(key: key);

  @override
  _WifiscreenState createState() => _WifiscreenState();
}

class _WifiscreenState extends State<Wifiscreen> {
  List<WiFiAccessPoint> accessPoints = [];
  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  final connectivity = Connectivity();

  void _startListeningToScannedResults() async {
    // check platform support and necessary requirements
    final can =
        await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    switch (can) {
      case CanGetScannedResults.yes:
        // listen to onScannedResultsAvailable stream
        subscription =
            WiFiScan.instance.onScannedResultsAvailable.listen((results) {
          // update accessPoints
          setState(() => accessPoints = results);
        });
        // ...
        break;
      // ... handle other cases of CanGetScannedResults values
      default:
        // show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(can.toString()),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  void connectWifi(WiFiAccessPoint apn) async {
    // final connection = await PluginWifiConnect.connect(apn.ssid, saveNetwork: true);
    // final connection = await WiFiForIoTPlugin.connect(apn.ssid,
    //     password: "ece@123ece", withInternet: true, bssid: apn.bssid);
    final connection =
        await PluginWifiConnect.connectToSecureNetwork(apn.ssid, "ece@123ece");
    await WiFiForIoTPlugin.forceWifiUsage(true);
  }

  @override
  void initState() {
    _startListeningToScannedResults();
    super.initState();
  }

// make sure to cancel subscription after you are done
  @override
  dispose() {
    super.dispose();
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Wifi Networks"),
      ),
      body: ListView.builder(
        itemCount: accessPoints.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(accessPoints[index].ssid),
            subtitle: Text(accessPoints[index].bssid),
            leading: Icon(Icons.wifi),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Selected network: ${accessPoints[index].ssid}",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              connectWifi(accessPoints[index]);
            },
          );
        },
      ),
    );
  }
}
