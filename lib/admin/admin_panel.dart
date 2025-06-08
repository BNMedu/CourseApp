import 'dart:convert';

import 'package:bnm_edu/account/account.dart';
import 'package:bnm_edu/admin/admin_edit.dart';
import 'package:bnm_edu/admin/admin_news_edit.dart';
import 'package:bnm_edu/admin/admin_registration.dart';
import 'package:bnm_edu/main/global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddCourseScreen extends StatefulWidget {
  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _idController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _courseTitleController = TextEditingController();
  final _videoUrlController = TextEditingController();

  final _questionTextController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());
  int _correctAnswerIndex = 0;

  final List<Map<String, dynamic>> _questions = [];

  void addQuestion() {
    if (_questionTextController.text.isEmpty ||
        _optionControllers.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fill all question fields')),
      );
      return;
    }

    _questions.add({
      "questionText": _questionTextController.text.trim(),
      "options": _optionControllers.map((c) => c.text.trim()).toList(),
      "correctAnswerIndex": _correctAnswerIndex,
    });

    _questionTextController.clear();
    for (var c in _optionControllers) {
      c.clear();
    }
    setState(() {});
  }

  Future<void> submitCourse() async {
    if (_idController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _courseTitleController.text.isEmpty ||
        _videoUrlController.text.isEmpty ||
        _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all course fields')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final url = Uri.parse('https://$ip/api/courses/');
    final body = {
      "_id": _idController.text.trim(),
      "title": _titleController.text.trim(),
      "description": _descriptionController.text.trim(),
      "courseTitle": _courseTitleController.text.trim(),
      "videoUrl": _videoUrlController.text.trim(),
      "questions": _questions,
      "targetAge": "12-18",
      "category": "Programming"
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course added successfully')),
        );
        _idController.clear();
        _titleController.clear();
        _descriptionController.clear();
        _courseTitleController.clear();
        _videoUrlController.clear();
        _questions.clear();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Color.fromARGB(40, 202, 138, 213),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildNavIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.deepPurple, size: 28),
          ),
          SizedBox(height: 6),
          Text(label,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Add Course'),
        centerTitle: true,
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
            buildTextField(_idController, 'Course ID'),
            buildTextField(_titleController, 'Lesson Title'),
            buildTextField(_descriptionController, 'Lesson Description',
                maxLines: 3),
            buildTextField(_courseTitleController, 'Course Title'),
            buildTextField(_videoUrlController, 'Video URL'),
            SizedBox(height: 12),
            Divider(),
            Text('Add Question',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            buildTextField(_questionTextController, 'Question Text'),
            for (int i = 0; i < 4; i++)
              buildTextField(_optionControllers[i], 'Option ${i + 1}'),
            SizedBox(height: 10),
            DropdownButton<int>(
              value: _correctAnswerIndex,
              items: List.generate(4, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text('Correct answer: Option ${index + 1}'),
                );
              }),
              onChanged: (val) => setState(() => _correctAnswerIndex = val!),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: addQuestion,
              child: Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 202, 138, 213),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),
            Text('Questions added: ${_questions.length}'),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: submitCourse,
              icon: Icon(Icons.upload),
              label: Text('Submit Course'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            SizedBox(height: 30),

            // Navigation block
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              margin: EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueAccent,
                      Color.fromARGB(255, 202, 138, 213)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Wrap(
                  spacing: 28,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildNavIcon(
                      icon: Icons.person_add,
                      label: 'Register',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterScreen()),
                        );
                      },
                    ),
                    _buildNavIcon(
                      icon: Icons.edit,
                      label: 'Edit User',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AdminEditScreen()),
                        );
                      },
                    ),
                    _buildNavIcon(
                      icon: Icons.add_box,
                      label: 'Add Course',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("You are already here")),
                        );
                      },
                    ),
                    _buildNavIcon(
                      icon: Icons.account_box,
                      label: 'Account',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AccountScreen()),
                        );
                      },
                    ),
                    _buildNavIcon(
                      icon: Icons.newspaper,
                      label: 'Edit News',
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token');
                        if (token == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No token found')),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminAddNewsScreen(token: token),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
