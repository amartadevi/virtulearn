import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/services/routes.dart';
import 'package:learn_smart/screens/welcome_screen.dart';
import 'package:learn_smart/screens/login_screen.dart';
import 'package:learn_smart/screens/registration_screen.dart';
import 'providers/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: AppProviders.providers(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LMS App',
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => WelcomeScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegistrationScreen()),
        ...AppRoutes.routes,
      ],
    );
  }
}
