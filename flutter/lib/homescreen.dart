// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';

import 'package:automation_app/wifiscreen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late final Connectivity connectionObj;
  late final Stream<ConnectivityResult> subscription;
  bool ledOn = false;
  final numController = TextEditingController();

  // get http => null;

  @override
  void initState() {
    connectionObj = Connectivity();
    subscription = Connectivity().onConnectivityChanged;
    super.initState();
  }

  void showSnackMessage(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          child: Text(message),
        ),
        backgroundColor: color,
      ),
    );
  }

  Future<void> sendVarNum(String n) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.4.1/var?variable=$n"),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse["status"] == "success") {
          showSnackMessage(
            context,
            "Led Combination updated for number $n",
            Colors.green,
          );
        } else {
          showSnackMessage(
            context,
            "Failed to update Led Combination",
            Colors.red,
          );
        }
      } else {
        showSnackMessage(
          context,
          "Unexpected status code: ${response.statusCode}",
          Colors.red,
        );
      }
    } catch (e) {
      showSnackMessage(context, e.toString(), Colors.red);
    }

    setState(() {
      ledOn = n != 0;
    });
  }

  Future<void> toggleLed() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.4.1/led"));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        showSnackMessage(
          context,
          "Led turned ${jsonResponse['ledStatus'] ? "on" : "off"}",
          jsonResponse['ledStatus'] ? Colors.green : Colors.grey,
        );
        setState(() {
          ledOn = jsonResponse["ledStatus"];
        });
      } else {
        showSnackMessage(
          context,
          "Unexpected status code: ${response.statusCode}",
          Colors.green,
        );
      }
    } catch (e) {
      showSnackMessage(context, "Error toggling LED: $e", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.wifi),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return Wifiscreen();
              }));
            },
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: StreamBuilder<ConnectivityResult>(
            stream: subscription,
            builder: (context, snapshot) {
              if (snapshot.data != ConnectivityResult.wifi) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      decoration: BoxDecoration(color: Colors.red[700]),
                      padding: const EdgeInsets.all(8),
                      child: const Text(
                        "Please connect to wifi",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        toggleLed();
                      },
                      child: Icon(
                        Icons.lightbulb,
                        size: 100,
                        color: ledOn ? Colors.yellow[700] : Colors.grey,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: TextField(
                            keyboardType: TextInputType.number,
                            controller: numController,
                          )),
                          TextButton(
                              onPressed: () {
                                sendVarNum((numController.text));
                                log("Sending number ${int.parse(numController.text)}",
                                    name: "sendVarNum");
                              },
                              child: Icon(Icons.lightbulb,
                                  size: 40,
                                  color:
                                      ledOn ? Colors.yellow[700] : Colors.grey))
                        ],
                      ),
                    )
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class FilledButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const FilledButton({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}
