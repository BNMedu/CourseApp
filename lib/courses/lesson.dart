import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../main/global.dart';

class LessonScreen extends StatefulWidget {
  final String videoUrl;
  final List<Map<String, dynamic>> questions;
  final String title;
  final String description;
  final String lessonId;

  LessonScreen({
    required this.videoUrl,
    required this.questions,
    required this.title,
    required this.description,
    required this.lessonId,
  });

  @override
  _LessonScreenState createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late YoutubePlayerController _controller;
  final Map<int, String> selectedAnswers = {};
  final TextEditingController projectUrlController = TextEditingController();
  List<String> projectLinks = [];

  bool answerAccepted = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    final videoId =
        YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? '';
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
      ),
    );
    checkIfAnswered();
  }

  Future<void> checkIfAnswered() async {
    setState(() {
      loading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(
          'http://$ip:5000/api/courses/check-answer?lessonId=${widget.lessonId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      answerAccepted = data['answered'] == true;
    }
    setState(() {
      loading = false;
    });
  }

  void addProjectLink() {
    final url = projectUrlController.text.trim();
    if (url.isNotEmpty && !projectLinks.contains(url)) {
      setState(() {
        projectLinks.add(url);
        projectUrlController.clear();
      });
    }
  }

  void removeProjectLink(String url) {
    setState(() {
      projectLinks.remove(url);
    });
  }

  void submitQuiz() async {
    int correct = 0;
    List<Map<String, String>> userAnswers = [];

    for (int i = 0; i < widget.questions.length; i++) {
      final correctAnswerIndex = widget.questions[i]['correctAnswerIndex'];
      final correctText = widget.questions[i]['options'][correctAnswerIndex];
      final userAnswer = selectedAnswers[i];

      if (userAnswer == correctText) correct++;

      userAnswers.add({
        'question': widget.questions[i]['questionText'],
        'selected': userAnswer ?? '',
        'correct': correctText,
      });
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Result"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Correct answers: $correct / ${widget.questions.length}"),
              SizedBox(height: 10),
              ...userAnswers.map((e) => Text(
                    "Q: ${e['question']}\n✓ ${e['correct']}\n✎ ${e['selected']}\n",
                  )),
              if (projectLinks.isNotEmpty) ...[
                Divider(),
                Text(
                  "Project Links:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...projectLinks.map((link) => Text(link)),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://$ip:5000/api/courses/submit-answer'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'lessonId': widget.lessonId,
        'score': correct,
        'answers': userAnswers,
        'projectLinks': projectLinks,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        answerAccepted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Results submitted")),
      );
    } else if (response.statusCode == 409) {
      setState(() {
        answerAccepted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Answer already accepted")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Важно!
      appBar: AppBar(
        title: Text("Lesson"),
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
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      kToolbarHeight,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purpleAccent, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: YoutubePlayerScaffold(
                            controller: _controller,
                            aspectRatio: 16 / 9,
                            builder: (context, player) => player,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.description,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    // ==== "Answer accepted" ниже описания ====
                    if (answerAccepted) ...[
                      SizedBox(height: 26),
                      Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 30),
                            SizedBox(width: 12),
                            Text(
                              "Answer accepted",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                    // ==== Тест и проекты только если ответ не сдан ====
                    if (!answerAccepted) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lesson Quiz:",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            ...List.generate(widget.questions.length, (index) {
                              final q = widget.questions[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q['questionText'],
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  ...List.generate(q['options'].length,
                                      (optIndex) {
                                    final option = q['options'][optIndex];
                                    return RadioListTile<String>(
                                      title: Text(option),
                                      value: option,
                                      groupValue: selectedAnswers[index],
                                      onChanged: (value) {
                                        setState(() {
                                          selectedAnswers[index] = value!;
                                        });
                                      },
                                    );
                                  }),
                                  SizedBox(height: 10),
                                ],
                              );
                            }),
                            SizedBox(height: 20),
                            Divider(),
                            Text(
                              "Submit your project links (if any):",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: projectUrlController,
                                    decoration: InputDecoration(
                                      hintText:
                                          "Paste your project link here...",
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: addProjectLink,
                                  child: Text("Add Link"),
                                ),
                              ],
                            ),
                            if (projectLinks.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  ...projectLinks.map((link) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Row(
                                          children: [
                                            Expanded(
                                                child: Text(link,
                                                    style: TextStyle(
                                                        fontSize: 14))),
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red, size: 20),
                                              onPressed: () =>
                                                  removeProjectLink(link),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: submitQuiz,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "Check answers",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
