import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:garbage_classification/firebase_options.dart';
import 'package:garbage_classification/screen_selector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const MyApp());
}


Future<void> _initializeFirebase() async {
  final firebaseOptions = DefaultFirebaseOptions.maybeCurrentPlatform;

  if (firebaseOptions == null) {
    debugPrint(
      'Firebase initialization skipped: '
      '${DefaultFirebaseOptions.unsupportedPlatformMessage}',
    );
    return;
  }

  await Firebase.initializeApp(options: firebaseOptions);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScreenSelector(),
    );
  }
}
