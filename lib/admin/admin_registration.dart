import 'dart:convert';

import 'package:bnm_edu/main/global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

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
  bool _isLoading = false;

  // ======= ВАЛИДАТОРЫ =======
  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Введите имя пользователя';

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    if (value.length < 8) return 'Minimum 8 symbols';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add a capital letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Add a lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add a number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(value))
      return 'Add special character';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Incorrect email';
    return null;
  }

  String? validateBirthDate(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Enter your date of birth';
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(value.trim())) return 'Format: YYYY-MM-DD';
    return null;
  }

  String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter city';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your phone number';
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{6,}$');
    if (!phoneRegex.hasMatch(value.trim())) return 'Incorrect phone';
    return null;
  }

  String? validateCourse(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter the rate';
    return null;
  }

  String? validateFather(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter fathers name';
    return null;
  }

  String? validateMother(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter mothers name';
    return null;
  }

  // ======= ОТПРАВКА ФОРМЫ =======
  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse('https://$ip/api/auth/register');

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
          if (_selectedRole == 'admin' && token != null)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пользователь успешно зарегистрирован')),
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
          SnackBar(content: Text(data['message'] ?? 'Registration error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ======= ПОЛЕ ФОРМЫ =======
  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Color.fromARGB(40, 202, 138, 213),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ======= UI =======
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildTextField(
                controller: _usernameController,
                label: 'Username',
                validator: validateUsername,
              ),
              buildTextField(
                controller: _passwordController,
                label: 'Password',
                obscure: true,
                validator: validatePassword,
              ),
              buildTextField(
                controller: _emailController,
                label: 'Email',
                validator: validateEmail,
              ),
              buildTextField(
                controller: _birthDateController,
                label: 'Birth Date (YYYY-MM-DD)',
                validator: validateBirthDate,
              ),
              buildTextField(
                controller: _cityController,
                label: 'City',
                validator: validateCity,
              ),
              buildTextField(
                controller: _phoneController,
                label: 'Phone',
                validator: validatePhone,
              ),
              buildTextField(
                controller: _courseController,
                label: 'Course',
                validator: validateCourse,
              ),
              if (_selectedRole == 'user') ...[
                buildTextField(
                  controller: _fatherController,
                  label: "Father's Name",
                  validator: validateFather,
                ),
                buildTextField(
                  controller: _motherController,
                  label: "Mother's Name",
                  validator: validateMother,
                ),
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
                onPressed: _isLoading ? null : registerUser,
                icon: Icon(Icons.person_add),
                label: Text(_isLoading ? 'Registering...' : 'Register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
