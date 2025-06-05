import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminAddNewsScreen extends StatefulWidget {
  final String token;
  const AdminAddNewsScreen({required this.token});

  @override
  _AdminAddNewsScreenState createState() => _AdminAddNewsScreenState();
}

class _AdminAddNewsScreenState extends State<AdminAddNewsScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController imageController = TextEditingController();

  bool loading = false;

  Future<void> submitNews() async {
    setState(() => loading = true);

    final response = await http.post(
      Uri.parse('http://localhost:5000/admin/news'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'title': titleController.text,
        'description': descController.text,
        'image': imageController.text,
      }),
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Новость успешно добавлена')),
      );
      titleController.clear();
      descController.clear();
      imageController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить новость')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Заголовок'),
            ),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: 'Описание'),
            ),
            TextField(
              controller: imageController,
              decoration: InputDecoration(labelText: 'URL изображения (необязательно)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : submitNews,
              child: loading ? CircularProgressIndicator() : Text('Опубликовать'),
            ),
          ],
        ),
      ),
    );
  }
}
