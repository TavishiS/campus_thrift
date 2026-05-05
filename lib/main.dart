import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the auto-generated file
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const CampusThriftApp());
}

class CampusThriftApp extends StatelessWidget {
  const CampusThriftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusThrift',
      debugShowCheckedModeBanner: false,
      // FORCE DARK THEME GLOBALLY
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark, 
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        // Removed useMaterial3: true as it is deprecated and defaults to true natively now
      ),
      // The StreamBuilder listens to Auth state changes in real-time
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the stream has a valid User object, they are logged in
          if (snapshot.hasData) {
            return const HomeScreen(); 
          }
          // Otherwise, show the Login/Register screen
          return const LoginScreen(); 
        },
      ),
    );
  }
}