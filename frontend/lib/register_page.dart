import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:auth/utils/hash_helper.dart'; // Update with your project name

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      String password = _passwordController.text;
      String hashedPassword = HashHelper.hashPassword(password); // Hash the password

      // Create JSON object
      Map<String, String> requestData = {
        "email": email,
        "password": hashedPassword
      };

      try {
        final response = await http.post(
          Uri.parse("http://172.16.45.12:5000/register"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestData),
        );

        // Decode the response
        Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ ${responseData['message'] ?? 'Registration successful'}")),
          );
          Navigator.pop(context); // Navigate back to the home (or login) page
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Registration Failed: ${responseData['message'] ?? response.body}")),
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
      appBar: AppBar(title: const Text("Register")),
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
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm Password"),
                validator: (value) {
                  if (value!.isEmpty) return "Confirm your password";
                  if (value != _passwordController.text) return "Passwords do not match";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
