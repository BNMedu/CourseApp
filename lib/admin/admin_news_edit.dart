import 'dart:convert';

import 'package:bnm_edu/main/global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminAddNewsScreen extends StatefulWidget {
  final String token;
  const AdminAddNewsScreen({required this.token});

  @override
  _AdminAddNewsScreenState createState() => _AdminAddNewsScreenState();
}

class _AdminAddNewsScreenState extends State<AdminAddNewsScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final imageController = TextEditingController();
  final tagsController = TextEditingController();

  final tagSearchController = TextEditingController();

  bool loading = false;
  bool editMode = false;
  String editingId = '';

  List<Map<String, dynamic>> foundNews = [];

  // Поиск новостей по тегу
  Future<void> findNewsByTag() async {
    final tag = tagSearchController.text.trim();
    if (tag.isEmpty) return;
    setState(() => loading = true);

    final response = await http.get(
      Uri.parse('http://$ip:5000/api/news?tag=$tag'),
    );
    setState(() => loading = false);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        foundNews = List<Map<String, dynamic>>.from(data);
      });
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Новости не найдены')),
        );
      }
    } else {
      setState(() => foundNews = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${response.body}')),
      );
    }
  }

  // Заполнить поля для редактирования
  void fillForEdit(Map<String, dynamic> news) {
    setState(() {
      titleController.text = news['title'] ?? '';
      descController.text = news['description'] ?? '';
      imageController.text = news['image'] ?? '';
      tagsController.text = (news['tags'] as List?)?.join(', ') ?? '';
      editMode = true;
      editingId = news['_id'];
    });
  }

  // Добавить новость
  Future<void> submitNews() async {
    FocusScope.of(context).unfocus();
    setState(() => loading = true);

    final response = await http.post(
      Uri.parse('http://$ip:5000/api/news'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        '_id':
            DateTime.now().millisecondsSinceEpoch.toString(), // генерируем id
        'title': titleController.text,
        'description': descController.text,
        'image': imageController.text,
        'tags': tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      }),
    );

    setState(() => loading = false);

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('News was successfully published')),
      );
      clearFields();
      setState(() => editMode = false);
      findNewsByTag();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  // Редактировать новость
  Future<void> editNews() async {
    setState(() => loading = true);
    final response = await http.put(
      Uri.parse('http://$ip:5000/api/news/$editingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'title': titleController.text,
        'description': descController.text,
        'image': imageController.text,
        'tags': tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      }),
    );
    setState(() => loading = false);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('News updated successfully')),
      );
      clearFields();
      setState(() => editMode = false);
      findNewsByTag();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  // Удалить новость
  Future<void> deleteNews(String id) async {
    setState(() => loading = true);
    final response = await http.delete(
      Uri.parse('http://$ip:5000/api/news/$id'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );
    setState(() => loading = false);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('News deleted successfully')),
      );
      if (id == editingId) clearFields();
      setState(() => editMode = false);
      findNewsByTag();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  void clearFields() {
    titleController.clear();
    descController.clear();
    imageController.clear();
    tagsController.clear();
    setState(() {
      editingId = '';
      editMode = false;
    });
  }

  Widget buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, bool readOnly = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Color.fromARGB(40, 202, 138, 213),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin News'),
        centerTitle: true,
        elevation: 0,
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
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(18),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Container(
              width: 450,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.15),
                    Color.fromARGB(80, 202, 138, 213)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---- Поиск по тегу ----
                  buildTextField(tagSearchController, 'Поиск новостей по тегу'),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : findNewsByTag,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text('Найти новости по тегу'),
                    ),
                  ),
                  SizedBox(height: 18),

                  // ---- Список найденных новостей ----
                  if (foundNews.isNotEmpty)
                    Column(
                      children: [
                        Text(
                          'Результаты поиска:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        ...foundNews.map((news) => Card(
                              margin: EdgeInsets.symmetric(vertical: 7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blueAccent.withOpacity(0.15),
                                      Color.fromARGB(80, 202, 138, 213)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      news['title'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      news['description'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Теги: ${(news['tags'] as List?)?.join(', ') ?? ''}',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: loading
                                              ? null
                                              : () => fillForEdit(news),
                                          child: Text('Изменить'),
                                        ),
                                        TextButton(
                                          onPressed: loading
                                              ? null
                                              : () => deleteNews(news['_id']),
                                          child: Text(
                                            'Удалить',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        Divider(),
                      ],
                    ),

                  // ---- Поля для добавления/редактирования новости ----
                  buildTextField(titleController, 'Заголовок'),
                  buildTextField(descController, 'Описание', maxLines: 3),
                  buildTextField(
                      imageController, 'Ссылка на изображение (опционально)'),
                  buildTextField(tagsController, 'Теги (через запятую)'),
                  SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          loading ? null : (editMode ? editNews : submitNews),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: null,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ).copyWith(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>(
                          (states) => null,
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueAccent,
                              Color.fromARGB(255, 202, 138, 213)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          height: 50,
                          child: loading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3.2,
                                  ),
                                )
                              : Text(
                                  editMode
                                      ? 'Сохранить изменения'
                                      : 'Опубликовать',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  if (editMode) SizedBox(height: 10),
                  if (editMode)
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: loading ? null : clearFields,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Отмена',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
