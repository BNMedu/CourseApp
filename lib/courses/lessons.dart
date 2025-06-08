import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main/global.dart';
import 'analytics.dart';
import 'lesson.dart';

class CourseDetailScreen extends StatefulWidget {
  final String course; // Example: "Web Development"

  CourseDetailScreen({required this.course});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final List<String> lessons = List.generate(51, (index) => 'web_$index');
  List<String> completedLessons = [];
  String? userRole;

  // Mapping display names to internal keys
  final Map<String, String> courseNameMap = {
    "Web Development": "web",
    "Mobile Development": "mobile",
    "Game Design": "game",
    "UI/UX Basics": "uiux"
  };

  String get courseKey => courseNameMap[widget.course] ?? widget.course;

  @override
  void initState() {
    super.initState();
    fetchProgress();
    fetchUserRole();
  }

  Future<List<String>> fetchApprovedLessons() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("https://$ip/api/users/profile"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final answers = data['answers'] ?? [];
      final approvedLessons = answers
          .where((a) => a['teacherFeedback'] == 'approved')
          .map<String>((a) => a['lessonId'].toString())
          .toList();
      return approvedLessons;
    }

    return [];
  }

  Future<void> fetchProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;
    final response = await http.get(
      Uri.parse("https://$ip/api/courses/progress/me"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final progress = data['progress'][courseKey];
      completedLessons = List<String>.from(progress?['lessonsCompleted'] ?? []);
      final approved = await fetchApprovedLessons();
      completedLessons.addAll(approved);
      completedLessons = completedLessons.toSet().toList(); // Убираем дубли
      completedLessons = completedLessons.toSet().toList();
      setState(() {});
    } else {
      print("Failed to fetch progress: ${response.body}");
    }
  }

  Future<void> fetchUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse("https://$ip/api/account"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        userRole = data['role'];
      });
    } else {
      print('Failed to load user role: ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> fetchLessonData(String lessonId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = Uri.parse("https://$ip/api/courses/$lessonId");
    print("Requesting lesson: $lessonId, URL: $url");
    try {
      final response = await http.get(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('Response code: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print("Failed to load lesson: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            widget.course,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.bar_chart_rounded, color: Colors.white70),
              tooltip: 'Analytics',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProgressAnalyticsScreen(course: courseKey),
                  ),
                );
              },
            )
          ],
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: kToolbarHeight + 32),
          child: Column(
            children: [
              if (userRole == 'teacher')
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/teacher-answers');
                    },
                    icon: Icon(Icons.assignment_turned_in),
                    label: Text("Student answers"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: lessons.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final lessonId = lessons[index];
                    final isCompleted = completedLessons.contains(lessonId);

                    return InkWell(
                      onTap: () async {
                        final data = await fetchLessonData(lessonId);
                        if (data != null) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LessonScreen(
                                lessonId: lessonId,
                                videoUrl: data['videoUrl'] ?? '',
                                questions: List<Map<String, dynamic>>.from(
                                    data['questions'] ?? []),
                                title: data['title'] ?? '',
                                description: data['description'] ?? '',
                              ),
                            ),
                          );
                          fetchProgress(); // Refresh progress
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lesson not found')),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isCompleted
                              ? Colors.green.withOpacity(0.85)
                              : Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(2, 2),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: isCompleted
                                  ? Colors.green
                                  : Colors.deepPurple.withOpacity(0.8),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Lesson ${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isCompleted
                                    ? Colors.white
                                    : Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
          currentIndex: 1,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 0) Navigator.pushReplacementNamed(context, '/home');
            if (index == 1) Navigator.pushReplacementNamed(context, '/courses');
            if (index == 2) Navigator.pushReplacementNamed(context, '/account');
          },
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'News'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Courses'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }
}
