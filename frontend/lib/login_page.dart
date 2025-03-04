import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:auth/utils/hash_helper.dart';
// Import DetectionDashboard from its file
import 'detection_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      String password = _passwordController.text;
      String hashedPassword = HashHelper.hashPassword(password);

      Map<String, String> requestData = {
        "email": email,
        "password": hashedPassword,
      };

      try {
        final response = await http.post(
          Uri.parse("http://172.16.45.12:5000/login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestData),
        );

        Map<String, dynamic> responseData = jsonDecode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          String sessionId = responseData['session_id'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ ${responseData['message'] ?? 'Login successful'}"),
            ),
          );
          // Navigate to the DetectionDashboard, passing the session ID.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DetectionScreen(sessionId: sessionId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Login Failed: ${responseData['message'] ?? response.body}"),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Error: Could not connect to server")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.isEmpty ? "Enter your email" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (value) => value!.isEmpty ? "Enter a password" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
