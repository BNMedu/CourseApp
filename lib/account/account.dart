import 'dart:convert';
import 'dart:io';

import 'package:bnm_edu/account/change_password.dart';
import 'package:bnm_edu/account/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main/global.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? username, role, birthDate, city, phone, course;
  String? father, mother;
  String? avatarUrl;
  String? errorMessage;
  int _currentIndex = 2;
  File? _newAvatar;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchAccountData();
  }

  Future<void> fetchAccountData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Используем Uri.https и логируем ответ
    final uri = Uri.https(ip!, '/api/users/profile');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    print('GET $uri → ${response.statusCode}\n${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        username = data['username'];
        role = data['role'];
        birthDate = data['birthDate'];
        city = data['city'];
        phone = data['phone'];
        course = data['course'];
        father = data['parentNames']?['father'];
        mother = data['parentNames']?['mother'];
        avatarUrl = data['avatarUrl'];
        errorMessage = null;
      });
    } else {
      setState(() {
        errorMessage = 'Ошибка ${response.statusCode}: ${response.body}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }
  }

  Widget buildInfoTile(IconData icon, String label, String value) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.blueAccent),
          title: Text(label),
          subtitle: Text(value),
        ),
        Divider(),
      ],
    );
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newAvatar = File(picked.path));
      await _uploadAvatar();
    }
  }

  Future<void> _uploadAvatar() async {
    setState(() => _uploading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || _newAvatar == null) return;

    final uri = Uri.https(ip!, '/api/users/avatar');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('avatar', _newAvatar!.path),
    );
    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonResp = jsonDecode(respStr);
      setState(() {
        avatarUrl = jsonResp['avatarUrl'];
        _newAvatar = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Аватарка обновлена!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки аватарки')),
      );
    }
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
          elevation: 0,
          centerTitle: true,
          title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                if (errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    color: Colors.red.shade100,
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 12,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blueAccent,
                              backgroundImage: _newAvatar != null
                                  ? FileImage(_newAvatar!)
                                  : (avatarUrl != null && avatarUrl!.isNotEmpty
                                      ? NetworkImage(avatarUrl!) as ImageProvider
                                      : null),
                              child: (avatarUrl == null && _newAvatar == null)
                                  ? Icon(Icons.person, size: 60, color: Colors.white)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _uploading ? null : _pickAvatar,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.camera_alt,
                                      color: Colors.blueAccent, size: 22),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          username ?? 'Loading...',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        if (role != null)
                          Text('Role: $role', style: TextStyle(color: Colors.grey[600])),
                        SizedBox(height: 20),
                        Divider(),
                        if (birthDate != null)
                          buildInfoTile(Icons.cake, "Birthdate", birthDate!),
                        if (city != null)
                          buildInfoTile(Icons.location_city, "City", city!),
                        if (phone != null)
                          buildInfoTile(Icons.phone, "Phone", phone!),
                        if (course != null)
                          buildInfoTile(Icons.book, "Course", course!),
                        if (father != null && mother != null)
                          buildInfoTile(Icons.family_restroom, "Parents",
                              "$father & $mother"),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(
                                  username: username,
                                  birthDate: birthDate,
                                  city: city,
                                  phone: phone,
                                  course: course,
                                  father: father,
                                  mother: mother,
                                ),
                              ),
                            );
                            if (updated == true) fetchAccountData();
                          },
                          icon: Icon(Icons.edit),
                          label: Text("Edit Profile"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ChangePasswordScreen())),
                          icon: Icon(Icons.lock),
                          label: Text("Change Password"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('token');
                            Navigator.pushReplacementNamed(context, '/');
                          },
                          icon: Icon(Icons.logout),
                          label: Text("Log Out"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
