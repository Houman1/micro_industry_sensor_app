import 'package:flutter/material.dart';
import 'dart:convert' show utf8;
// import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key, required this.device});

  final BluetoothDevice device;

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  final String SERVICE_UUID = "put service UUID here";
  final String CHARACTERISTIC_UUID = "put characteristic UUID here";

  bool isReady = false;
  late Stream<List<int>> stream;

  @override
  void initState() {
    super.initState();
    isReady = false;
    connectToDevice();
  }

  connectToDevice() async {
    Timer(const Duration(seconds: 15), () {
      if (!isReady) {
        disconnectFromDevice();
        _Pop();
      }
    });
    await widget.device.connect();
    discoverServices();
  }

  disconnectFromDevice() {
    widget.device.disconnect();
  }

  discoverServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == SERVICE_UUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            stream = characteristic.lastValueStream;

            setState(() {
              isReady = true;
            });
          }
        }
      }
    }

    if (!isReady) {
      _Pop();
    }
  }


  _Pop() {
    Navigator.of(context).pop(true);
  }

  String _dataParser(List<int> dataFromDevice) {
    return utf8.decode(dataFromDevice);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Micro Industry Sensor App'),
        ),
        body: Container(
            child: !isReady
                ? const Center(
                    child: Text(
                      "Waiting...",
                      style: TextStyle(fontSize: 24, color: Colors.red),
                    ),
                  )
                : Container(
                    child: StreamBuilder<List<int>>(
                      stream: stream,
                      builder: (BuildContext context,
                          AsyncSnapshot<List<int>> snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.active) {
                          // Provide a default value (e.g., empty list) if snapshot.data is null
                          var currentValue = _dataParser(snapshot.data ?? []);

                          return Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                const Text('Current value from Sensor',
                                    style: TextStyle(fontSize: 14)),
                                //below is the value and the unit of the value shown.
                                Text('$currentValue L',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24))
                              ]));
                        } else {
                          return const Text('Check the stream');
                        }
                      },
                    ),
                  )),
      ),
    );
  }
}
