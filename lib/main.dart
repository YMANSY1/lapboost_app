import 'package:flutter/material.dart';
import 'package:lapboost_app/screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LapboostApp());
}

class LapboostApp extends StatelessWidget {
  const LapboostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
