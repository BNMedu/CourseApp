import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';

class LoginController {
  // Сохраняем токен в локальное хранилище
  Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Авторизация пользователя
  Future<bool> loginUser(BuildContext context, String username, String password) async {
    final url = Uri.parse('http://${ip}:5000/login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        String token = responseBody['token'];
        String role = responseBody['role'];

        await saveToken(token);

        // Навигация по ролям
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/adminHome');
        } else if (role == 'teacher') {
          Navigator.pushReplacementNamed(context, '/teacher-answers');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }

        return true;
      } else {
        final responseBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['message'] ?? 'Login failed')),
        );
        return false;
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка подключения к серверу $error")),
      );
      return false;
    }
  }
}
