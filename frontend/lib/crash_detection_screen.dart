import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;

class CrashDetectionScreen extends StatefulWidget {
  final String sessionId;
  const CrashDetectionScreen({super.key, required this.sessionId});

  @override
  State<CrashDetectionScreen> createState() => _CrashDetectionScreenState();
}

class _CrashDetectionScreenState extends State<CrashDetectionScreen> {
  List<double> _accelerometerValues = [0.0, 0.0, 0.0];
  List<double> _gyroscopeValues = [0.0, 0.0, 0.0];
  String _crashStatus = "No Crash Detected";

  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;
  Timer? _sensorTimer;

  @override
  void initState() {
    super.initState();
    _startListening();
    // Start a timer to send sensor data to the server every second.
    _sensorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _sendSensorData();
    });
  }

  void _startListening() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      setState(() {
        _accelerometerValues = [event.x, event.y, event.z];
        _checkForCrash();
      });
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      setState(() {
        _gyroscopeValues = [event.x, event.y, event.z];
        _checkForCrash();
      });
    });
  }

  void _checkForCrash() {
    // Using raw accelerometer values (assumed in G already, if not adjust accordingly)
    double ax = _accelerometerValues[0];
    double ay = _accelerometerValues[1];
    double az = _accelerometerValues[2];
    // Calculate total acceleration (if sensor returns in m/s², remove division by 9.81)
    double totalAcceleration = sqrt(ax * ax + ay * ay + az * az) / 9.81;

    double gx = _gyroscopeValues[0];
    double gy = _gyroscopeValues[1];
    double gz = _gyroscopeValues[2];
    double totalGyro = sqrt(gx * gx + gy * gy + gz * gz);

    // Adjust thresholds based on your sensor's output and calibration.
    if (totalAcceleration >= 4.5 && totalGyro >= 5) {
      _crashStatus = "Possible Crash Detected!";
    } else if (totalAcceleration >= 6) {
      _crashStatus = "Severe Crash Detected!";
    } else {
      _crashStatus = "No Crash Detected";
    }
  }

  // Function to send sensor data to the server
  Future<void> _sendSensorData() async {
    final sensorData = {
      "session_id": widget.sessionId,
      "accelerometer": {
        "x": _accelerometerValues[0],
        "y": _accelerometerValues[1],
        "z": _accelerometerValues[2],
      },
      "gyroscope": {
        "x": _gyroscopeValues[0],
        "y": _gyroscopeValues[1],
        "z": _gyroscopeValues[2],
      },
      "crash_status": _crashStatus,
      "timestamp": DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse("http://172.16.45.12:5000/session_data"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(sensorData),
      );
      print("Sensor data sent: ${response.body}");
    } catch (e) {
      print("Failed to send sensor data: $e");
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _gyroscopeSubscription.cancel();
    _sensorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash Detection'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: Text("Session: ${widget.sessionId}")),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Accelerometer Data:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'X: ${_accelerometerValues[0].toStringAsFixed(2)} m/s2\n'
                'Y: ${_accelerometerValues[1].toStringAsFixed(2)} m/s2\n'
                'Z: ${_accelerometerValues[2].toStringAsFixed(2)} m/s2',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Gyroscope Data:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'X: ${_gyroscopeValues[0].toStringAsFixed(2)} rad/s\n'
                'Y: ${_gyroscopeValues[1].toStringAsFixed(2)} rad/s\n'
                'Z: ${_gyroscopeValues[2].toStringAsFixed(2)} rad/s',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                _crashStatus,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _crashStatus.contains("No") ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
