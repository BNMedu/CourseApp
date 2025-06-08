import 'dart:convert';

import 'package:bnm_edu/main/global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isTwoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    fetchTwoFactorStatus();
  }

  Future<void> fetchTwoFactorStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse("https://$ip/api/users/profile"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        isTwoFactorEnabled = data['security']['twoFactorEnabled'] ?? false;
      });
    }
  }

  Future<void> updateTwoFactorStatus(bool newValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;
    final response = await http.put(
      Uri.parse("https://$ip/api/users/profile"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"twoFactorEnabled": newValue}),
    );

    if (response.statusCode == 200) {
      setState(() {
        isTwoFactorEnabled = newValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Settings saved")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Security Settings"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Color.fromARGB(255, 202, 138, 213)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Two-Factor Authentication",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: isTwoFactorEnabled,
                      onChanged: (value) {
                        updateTwoFactorStatus(value);
                      },
                      activeColor: Colors.blueAccent,
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "If enabled, a one-time code will be sent to your email upon login.",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
