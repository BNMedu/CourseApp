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
  final newEmailController = TextEditingController();
  final usernameController = TextEditingController();
  final birthDateController = TextEditingController();
  final cityController = TextEditingController();
  final phoneController = TextEditingController();
  final courseController = TextEditingController();
  final fatherController = TextEditingController();
  final motherController = TextEditingController();

  final List<String> roles = ['admin', 'teacher', 'user'];
  String? selectedRole;

  bool isTwoFactorEnabled = false;
  bool userLoaded = false;
  bool isLoading = false;

  // Validation error messages
  String? emailError;
  String? newEmailError;
  String? usernameError;
  String? birthDateError;
  String? cityError;
  String? phoneError;
  String? courseError;
  String? fatherError;
  String? motherError;

  // ========================= VALIDATORS =========================
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Invalid email format';
    return null;
  }

  String? validateNewEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Invalid new email format';
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter username';
    return null;
  }

  String? validateBirthDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter birth date';
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(value.trim())) return 'Format: YYYY-MM-DD';
    return null;
  }

  String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter city';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter phone number';
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{6,}$');
    if (!phoneRegex.hasMatch(value.trim())) return 'Invalid phone number';
    return null;
  }

  String? validateCourse(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter course';
    return null;
  }

  String? validateFather(String? value) {
    if (value == null || value.trim().isEmpty) return "Enter father's name";
    return null;
  }

  String? validateMother(String? value) {
    if (value == null || value.trim().isEmpty) return "Enter mother's name";
    return null;
  }

  // ========================= LOAD USER =========================
  Future<void> fetchUser() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://$ip/api/users/account-by-email?email=$email'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        usernameController.text = data['username'] ?? '';
        birthDateController.text = data['birthDate'] ?? '';
        cityController.text = data['city'] ?? '';
        phoneController.text = data['phone'] ?? '';
        courseController.text = data['course'] ?? '';
        selectedRole = data['role'] ?? 'user';
        fatherController.text = data['parentNames']?['father'] ?? '';
        motherController.text = data['parentNames']?['mother'] ?? '';
        isTwoFactorEnabled = data['security']?['twoFactorEnabled'] ?? false;
        userLoaded = true;
        newEmailController.clear();
      });
    } else {
      setState(() => userLoaded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not found")),
      );
    }
  }

  // ========================= VALIDATE ALL FIELDS =========================
  bool validateAll() {
    setState(() {
      newEmailError = validateNewEmail(newEmailController.text);
      usernameError = validateUsername(usernameController.text);
      birthDateError = validateBirthDate(birthDateController.text);
      cityError = validateCity(cityController.text);
      phoneError = validatePhone(phoneController.text);
      courseError = validateCourse(courseController.text);
      fatherError = validateFather(fatherController.text);
      motherError = validateMother(motherController.text);
    });

    return newEmailError == null &&
        usernameError == null &&
        birthDateError == null &&
        cityError == null &&
        phoneError == null &&
        courseError == null &&
        fatherError == null &&
        motherError == null;
  }

  // ========================= SAVE CHANGES =========================
  Future<void> saveChanges() async {
    if (!validateAll()) return;

    final email = emailController.text.trim();
    final newEmail = newEmailController.text.trim();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final body = {
      "email": email,
      "username": usernameController.text,
      "birthDate": birthDateController.text,
      "city": cityController.text,
      "phone": phoneController.text,
      "course": courseController.text,
      "role": selectedRole,
      "parentNames": {
        "father": fatherController.text,
        "mother": motherController.text,
      },
      "twoFactorEnabled": isTwoFactorEnabled
    };

    if (newEmail.isNotEmpty) {
      body["newEmail"] = newEmail;
    }

    setState(() => isLoading = true);

    final response = await http.put(
      Uri.parse('https://$ip/api/admin/update-user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(body),
    );

    setState(() => isLoading = false);

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

  Widget buildInput(
      String label, TextEditingController controller, String? error,
      {TextInputType? keyboardType, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: error,
          ),
          onChanged: (_) {
            setState(() {
              if (label == "New Email") newEmailError = null;
              if (label == "Username") usernameError = null;
              if (label == "Birth Date") birthDateError = null;
              if (label == "City") cityError = null;
              if (label == "Phone") phoneError = null;
              if (label == "Course") courseError = null;
              if (label == "Father's Name") fatherError = null;
              if (label == "Mother's Name") motherError = null;
            });
          },
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget buildEmailInputForSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Email"),
        SizedBox(height: 4),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !userLoaded,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: emailError,
          ),
          onChanged: (_) {
            setState(() {
              emailError = null;
            });
          },
        ),
        SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            setState(() {
              emailError = validateEmail(emailController.text);
            });
            if (emailError == null) fetchUser();
          },
          child: Text("Load User"),
        ),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Email for search (top)
                  buildEmailInputForSearch(),
                  if (userLoaded) ...[
                    SizedBox(height: 10),
                    buildInput("Username", usernameController, usernameError),
                    buildInput(
                        "Birth Date", birthDateController, birthDateError,
                        keyboardType: TextInputType.datetime),
                    buildInput("City", cityController, cityError),
                    buildInput("Phone", phoneController, phoneError,
                        keyboardType: TextInputType.phone),
                    buildInput("Course", courseController, courseError),
                    // Role
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Role"),
                        SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: roles
                              .map((role) => DropdownMenuItem(
                                  value: role, child: Text(role)))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value;
                            });
                          },
                        ),
                        SizedBox(height: 12),
                      ],
                    ),
                    buildInput("Father's Name", fatherController, fatherError),
                    buildInput("Mother's Name", motherController, motherError),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("2FA Enabled", style: TextStyle(fontSize: 16)),
                        Switch(
                          value: isTwoFactorEnabled,
                          onChanged: (v) =>
                              setState(() => isTwoFactorEnabled = v),
                          activeColor: Colors.blueAccent,
                        )
                      ],
                    ),
                    // NEW EMAIL (at the end)
                    buildInput("New Email", newEmailController, newEmailError,
                        keyboardType: TextInputType.emailAddress),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : saveChanges,
                      child: Text(isLoading ? "Saving..." : "Save Changes"),
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
