import 'dart:convert';

import 'package:bnm_edu/login/twoFactorVerify.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main/global.dart';

class LoginController {
  // Сохраняем токен в локальное хранилище
  Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Авторизация пользователя с 2FA
  Future<bool> loginUser(BuildContext context, String username, String password) async {
    final url = Uri.parse('http://$ip:5000/login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['twoFactorRequired'] == true) {
          final email = responseBody['email'];

          // отправка 2FA кода на почту
          await http.post(
            Uri.parse('http://$ip:5000/send-2fa-code'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email}),
          );

          // переход на экран ввода кода
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TwoFactorVerifyScreen(email: email),
            ),
          );

          return true;
        }

        // Если 2FA не требуется — сохраняем токен и заходим
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['message'] ?? 'Login failed')),
        );
        return false;
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection error: $error")),
      );
      return false;
    }
  }
}
