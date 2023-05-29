import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project/logic/auth_logic.dart';
import 'package:project/logic/chat_provider.dart';
import 'package:project/logic/home_provider.dart';
import 'package:project/logic/profile_provider.dart';
import 'package:project/pages/splashpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  runApp(MyApp(
    sharedPreferences: sharedPreferences,
  ));
}

class MyApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);
  final SharedPreferences sharedPreferences;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;
  MyApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthLogic(
              firebaseFirestore: firebaseFirestore,
              sharedPreferences: sharedPreferences,
              googleSignIn: GoogleSignIn(),
              firebaseAuth: FirebaseAuth.instance),
        ),
        Provider<ProfileLogic>(
          create: (context) => ProfileLogic(
              sharedPreferences: sharedPreferences,
              firebaseStorage: firebaseStorage,
              firebaseFirestore: firebaseFirestore),
        ),
        Provider<HomeLogic>(
          create: (context) => HomeLogic(firebaseFirestore: firebaseFirestore),
        ),
        Provider<ChatLogic>(
          create: (context) => ChatLogic(
              sharedPreferences: sharedPreferences,
              firebaseStorage: firebaseStorage,
              firebaseFirestore: firebaseFirestore),
        ),
      ],
      child: ValueListenableBuilder(
        valueListenable: themeNotifier,
        builder: (context, ThemeMode currentMode, index) {
          return MaterialApp(
            themeMode: currentMode,
            darkTheme: ThemeData.dark(),
            debugShowCheckedModeBanner: false,
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
