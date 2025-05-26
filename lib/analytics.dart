import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';

class ProgressAnalyticsScreen extends StatefulWidget {
  final String course;

  const ProgressAnalyticsScreen({required this.course});

  @override
  _ProgressAnalyticsScreenState createState() =>
      _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState extends State<ProgressAnalyticsScreen> {
  int totalLessons = 50;
  int completedLessons = 0;
  List<String> completedLessonList = [];

  Future<void> fetchProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final response = await http.get(
      Uri.parse("http://$ip:5000/progress"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final courseProgress = data['progress'][widget.course];
      print("DEBUG course: ${widget.course}");
      print("DEBUG full response: ${response.body}");
      print("DEBUG course: ${widget.course}"); // Должно быть 'web'


      if (courseProgress == null) {
        setState(() {
          completedLessons = 0;
          completedLessonList = [];
        });
        return;
      }

      final rawLessons =
          List<String>.from(courseProgress['lessonsCompleted'] ?? []);
      final uniqueLessons = rawLessons.toSet().toList();

      final int fetchedCompletedCount =
          data['analytics']?['completedLessonsCount'] ?? uniqueLessons.length;

      setState(() {
        completedLessons = fetchedCompletedCount;
        completedLessonList = uniqueLessons;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProgress();
  }

  @override
  Widget build(BuildContext context) {
    double percent = completedLessons / totalLessons * 100;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Course Analytics",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
          padding: const EdgeInsets.only(
              top: kToolbarHeight + 32, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Progress in ${widget.course}",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: completedLessons.toDouble(),
                          color: Colors.green,
                          title: '$completedLessons done',
                          radius: 80,
                          titleStyle: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: (totalLessons - completedLessons).toDouble(),
                          color: Colors.grey.shade300,
                          title: '${totalLessons - completedLessons} left',
                          radius: 80,
                          titleStyle: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Completed: ${percent.toStringAsFixed(1)}%",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                "Всего пройдено уроков: $completedLessons",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 20),
              if (completedLessonList.isNotEmpty)
                Text(
                  "Lessons: ${completedLessonList.join(", ")}",
                  style: TextStyle(color: Colors.white70),
                ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Back",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
