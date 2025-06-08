import 'dart:convert';

import 'package:bnm_edu/main/global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Replace with your actual IP for backend if needed

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  int _currentIndex = 0;
  late Future<List<Map<String, String>>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = fetchAllNews();
  }

  Future<List<Map<String, String>>> fetchAdminNews() async {
    final url = Uri.parse('https://${ip}/api/news');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List news = data is List ? data : [];
      return news.map<Map<String, String>>((item) {
        return {
          'title': item['title'] ?? 'No title',
          'description': item['description'] ?? 'No description',
          'image': item['image'] ?? '',
        };
      }).toList();
    } else {
      throw Exception('Failed to load admin news');
    }
  }

  Future<List<Map<String, String>>> fetchProgrammingNews() async {
    final apiKey = '40658f3675234df8b7286c1871ea31bb'; // Your API key
    final url = Uri.parse(
        'https://newsapi.org/v2/everything?q=programming&language=en&sortBy=publishedAt&apiKey=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = data['articles'] as List;

      return articles.map<Map<String, String>>((article) {
        return {
          'title': article['title'] ?? 'No title',
          'description': article['description'] ?? 'No description',
          'image': article['urlToImage'] ?? '',
        };
      }).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<List<Map<String, String>>> fetchAllNews() async {
    try {
      final adminNews = await fetchAdminNews();
      final apiNews = await fetchProgrammingNews();
      return [...adminNews, ...apiNews]; // Admin news always first
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          centerTitle: true,
          title: Text("News", style: TextStyle(fontWeight: FontWeight.bold)),
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Map<String, String>>>(
            future: _newsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: Colors.white));
              } else if (snapshot.hasError) {
                return Center(
                    child: Text('Failed to load news',
                        style: TextStyle(color: Colors.white)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text('No news available',
                        style: TextStyle(color: Colors.white)));
              }

              final newsList = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  final news = newsList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                            child: news['image'] != null &&
                                    news['image']!.isNotEmpty
                                ? Image.network(
                                    news['image']!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      height: 200,
                                      color: Colors.grey[300],
                                      alignment: Alignment.center,
                                      child: Icon(Icons.broken_image, size: 50),
                                    ),
                                  )
                                : Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    child: Icon(Icons.broken_image, size: 50),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  news['title'] ?? '',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  news['description'] ?? '',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
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
          currentIndex: _currentIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == _currentIndex) return;
            setState(() => _currentIndex = index);
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
