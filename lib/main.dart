import 'package:bnm_edu/account/account.dart';
import 'package:bnm_edu/account/settings.dart';
import 'package:bnm_edu/admin/admin_panel.dart';
import 'package:bnm_edu/courses/courses.dart';
import 'package:bnm_edu/login/forgot_password.dart';
import 'package:bnm_edu/login/login.dart';
import 'package:bnm_edu/login/reset_password.dart';
import 'package:bnm_edu/main/auth_service.dart';
import 'package:bnm_edu/news/news.dart';
import 'package:bnm_edu/teacher/teacher_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для SystemChrome
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ОБЯЗАТЕЛЬНО!

  // Только портретная ориентация
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // Можно убрать если не нужен "вверх ногами"
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()..loadToken()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Стартовый экран
      routes: {
        '/': (context) => LoginScreen(), // Логин
        '/home': (context) => NewsScreen(),
        '/adminHome': (context) => AddCourseScreen(), // Главный экран
        '/courses': (context) => CoursesScreen(),
        '/account': (context) => AccountScreen(),
        '/forgotPassword': (context) => ForgotPasswordScreen(),
        '/resetPassword': (context) => ResetPasswordScreen(),
        '/teacher-answers': (context) => TeacherAnswersScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
