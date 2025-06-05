import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main/global.dart';

class AdminEditScreen extends StatefulWidget {
  @override
  _AdminEditScreenState createState() => _AdminEditScreenState();
}

class _AdminEditScreenState extends State<AdminEditScreen> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final birthDateController = TextEditingController();
  final cityController = TextEditingController();
  final phoneController = TextEditingController();
  bool isTwoFactorEnabled = false;
  bool userLoaded = false;

  Future<void> fetchUser() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://$ip:5000/account-by-email?email=$email'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        usernameController.text = data['username'] ?? '';
        birthDateController.text = data['birthDate'] ?? '';
        cityController.text = data['city'] ?? '';
        phoneController.text = data['phone'] ?? '';
        isTwoFactorEnabled = data['security']['twoFactorEnabled'] ?? false;
        userLoaded = true;
      });
    } else {
      setState(() => userLoaded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not found")),
      );
    }
  }

  Future<void> saveChanges() async {
    final email = emailController.text.trim();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final body = {
      "email": email,
      "username": usernameController.text,
      "birthDate": birthDateController.text,
      "city": cityController.text,
      "phone": phoneController.text,
      "twoFactorEnabled": isTwoFactorEnabled
    };

    final response = await http.put(
      Uri.parse('http://$ip:5000/admin/update-user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update user")),
      );
    }
  }

  Widget buildInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit User"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
      body: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  buildInput("User Email", emailController),
                  ElevatedButton(
                    onPressed: fetchUser,
                    child: Text("Load User"),
                  ),
                  if (userLoaded) ...[
                    SizedBox(height: 10),
                    buildInput("Username", usernameController),
                    buildInput("Birth Date", birthDateController),
                    buildInput("City", cityController),
                    buildInput("Phone", phoneController),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("2FA Enabled", style: TextStyle(fontSize: 16)),
                        Switch(
                          value: isTwoFactorEnabled,
                          onChanged: (v) => setState(() => isTwoFactorEnabled = v),
                          activeColor: Colors.blueAccent,
                        )
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: saveChanges,
                      child: Text("Save Changes"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
