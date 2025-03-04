import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FatigueScreen extends StatefulWidget {
  @override
  _FatigueScreenState createState() => _FatigueScreenState();
}

class _FatigueScreenState extends State<FatigueScreen> {
  String prediction = "No data yet";
  int score = 0;
  final int threshold = 3; // Set your threshold here
  Timer? _pollingTimer;

  // Replace with your actual Flask endpoint URL.
  final String endpointUrl = "http://172.16.45.12:5001/latest_score";

  @override
  void initState() {
    super.initState();
    // Start polling the server every second
    _pollingTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      _fetchFatigueData();
    });
  }

  Future<void> _fetchFatigueData() async {
    try {
      final response = await http.get(Uri.parse(endpointUrl));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          prediction = data['prediction'] ?? "No prediction";
          score = data['score'] ?? 0;
        });
      } else {
        print("Error fetching data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayMessage =
        (score < threshold) ? "You're awake!" : "Warning: Fatigue detected!";
    return Scaffold(
      appBar: AppBar(
        title: Text('Fatigue Detection'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Fatigue Score: $score',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              displayMessage,
              style: TextStyle(
                fontSize: 28,
                color: (score < threshold) ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Prediction: $prediction',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
