import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:memory_game_app/Layouts/page_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memory_game_app/screens/signup.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseDatabase.instance.useDatabaseEmulator('10.0.2.2', 9000);
  await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Card Game',
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: const Color.fromARGB(255, 27, 27, 58),
          brightness: Brightness.dark,
        ),
      ),
      // home: const PageLayout(title: 'Flutter Demo Home Page'),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading...");
          }

          if (!snapshot.hasData) {
            return const SignupPage();
          }

          final user = snapshot.data!;
          return PageLayout(title: "Hello");
        },
      ),
    );
  }
}
