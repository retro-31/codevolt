import 'package:flutter/material.dart';
import 'crash_detection_screen.dart';
import 'fatigue_screen.dart';

class DetectionScreen extends StatefulWidget {
  final String sessionId;

  const DetectionScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  _DetectionScreenState createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  // 0: Crash Detection, 1: Fatigue Detection
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Pass sessionId to CrashDetectionScreen
    List<Widget> detectionWidgets = [
      CrashDetectionScreen(sessionId: widget.sessionId),
      FatigueScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Mode'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove extra back arrow
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffe0f7fa), Color(0xff80deea)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: detectionWidgets[_currentIndex],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.car_crash, "Crash", 0),
              _buildNavItem(Icons.warning, "Fatigue", 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool selected = index == _currentIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected ? Colors.blue : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
