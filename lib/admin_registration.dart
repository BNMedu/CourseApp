import 'dart:convert';

import 'package:bnm_edu/global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _courseController = TextEditingController();
  final _fatherController = TextEditingController();
  final _motherController = TextEditingController();

  String _selectedRole = 'user';

  Future<void> registerUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final url = Uri.parse('http://$ip:5000/register');

    final Map<String, dynamic> body = {
      "username": _usernameController.text.trim(),
      "password": _passwordController.text.trim(),
      "email": _emailController.text.trim(),
      "birthDate": _birthDateController.text.trim(),
      "city": _cityController.text.trim(),
      "phone": _phoneController.text.trim(),
      "course": _courseController.text.trim(),
      "role": _selectedRole,
    };

    if (_selectedRole == 'user') {
      body["parentNames"] = {
        "father": _fatherController.text.trim(),
        "mother": _motherController.text.trim(),
      };
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_selectedRole == 'admin' && token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User registered successfully')),
        );
        _usernameController.clear();
        _passwordController.clear();
        _emailController.clear();
        _birthDateController.clear();
        _cityController.clear();
        _phoneController.clear();
        _courseController.clear();
        _fatherController.clear();
        _motherController.clear();
        setState(() => _selectedRole = 'user');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget buildTextField(TextEditingController controller, String label,
      {bool obscure = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Color.fromARGB(40, 202, 138, 213),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register User'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Color.fromARGB(255, 202, 138, 213)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            buildTextField(_usernameController, 'Username'),
            buildTextField(_passwordController, 'Password', obscure: true),
            buildTextField(_emailController, 'Email'),
            buildTextField(_birthDateController, 'Birth Date (YYYY-MM-DD)'),
            buildTextField(_cityController, 'City'),
            buildTextField(_phoneController, 'Phone'),
            buildTextField(_courseController, 'Course'),
            if (_selectedRole == 'user') ...[
              buildTextField(_fatherController, 'Father\'s Name'),
              buildTextField(_motherController, 'Mother\'s Name'),
            ],
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color.fromARGB(30, 202, 138, 213),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  items: ['user', 'teacher', 'admin'].map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: registerUser,
              icon: Icon(Icons.person_add),
              label: Text('Register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
