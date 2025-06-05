import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main/global.dart';

class TeacherAnswersScreen extends StatefulWidget {
  @override
  _TeacherAnswersScreenState createState() => _TeacherAnswersScreenState();
}

class _TeacherAnswersScreenState extends State<TeacherAnswersScreen> {
  List<dynamic> answers = [];
  bool isLoading = true;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchAnswers();
  }

  Future<void> fetchAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse("http://$ip:5000/teacher/answers"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        answers = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Не удалось загрузить ответы: ${response.body}")),
      );
    }
  }

  void _handleBottomNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/courses');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/account');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Answers"),
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : answers.isEmpty
              ? Center(child: Text("Нет отправленных ответов"))
              : ListView.builder(
                  itemCount: answers.length,
                  itemBuilder: (context, index) {
                    final item = answers[index];
                    return Card(
                      margin: EdgeInsets.all(10),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(
                            "${item['username']} — Урок ${item['lessonId']}"),
                        subtitle: Text("Оценка: ${item['score']}"),
                        trailing: item['teacherFeedback'] == 'approved'
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : IconButton(
                                icon: Icon(Icons.check,
                                    color: Colors.orangeAccent),
                                tooltip: 'Approve',
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final token = prefs.getString('token');

                                  final response = await http.post(
                                    Uri.parse(
                                        "http://$ip:5000/teacher/approve-answer"),
                                    headers: {
                                      'Authorization': 'Bearer $token',
                                      'Content-Type': 'application/json'
                                    },
                                    body: jsonEncode({
                                      'email': item['email'],
                                      'lessonId': item['lessonId']
                                    }),
                                  );

                                  if (response.statusCode == 200) {
                                    setState(() {
                                      item['teacherFeedback'] = 'approved';
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Approved')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Failed to approve')),
                                    );
                                  }
                                },
                              ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Color.fromARGB(255, 202, 138, 213)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          onTap: _handleBottomNavTap,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'News'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Answers'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }
}
