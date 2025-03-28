import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/register_screen.dart';
import 'screens/set_location_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthWrapper(), // Use AuthWrapper as the home screen
      routes: {
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/home': (context) => HomeScreen(),
        '/map': (context) => MapScreen(),
        '/set_location': (context) => SetLocationScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show a loading indicator
        } else if (snapshot.hasData) {
          return DashboardScreen(); // User is authenticated
        } else {
          return LoginScreen(); // User is not authenticated
        }
      },
    );
  }
}