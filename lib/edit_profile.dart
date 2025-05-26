import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';

class EditProfileScreen extends StatefulWidget {
  final String? username, birthDate, city, phone, course, father, mother;

  EditProfileScreen({
    this.username,
    this.birthDate,
    this.city,
    this.phone,
    this.course,
    this.father,
    this.mother,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController usernameController;
  late TextEditingController birthDateController;
  late TextEditingController cityController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.username);
    birthDateController = TextEditingController(text: widget.birthDate);
    cityController = TextEditingController(text: widget.city);
    phoneController = TextEditingController(text: widget.phone);
  }

  Future<void> updateProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('http://${ip}:5000/account/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        "username": usernameController.text,
        "birthDate": birthDateController.text,
        "city": cityController.text,
        "phone": phoneController.text,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${data['message'] ?? 'Unknown error'}')),
      );
    }
  }

  Widget buildField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Field "$label" cannot be empty';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Edit Profile"),
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
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      buildField("Username", usernameController),
                      buildField("Birthdate", birthDateController),
                      buildField("City", cityController),
                      buildField("Phone", phoneController),
                      SizedBox(height: 10),
                      Text("Course: ${widget.course ?? 'not specified'}"),
                      Text("Father: ${widget.father ?? 'not specified'}"),
                      Text("Mother: ${widget.mother ?? 'not specified'}"),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            updateProfile();
                          }
                        },
                        child: Text("Save"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
