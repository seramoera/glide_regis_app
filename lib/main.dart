import 'package:flutter/material.dart';
import 'package:org_registration_app/screens/user/user_shell.dart';
import 'package:org_registration_app/services/app_database.dart';
import 'package:org_registration_app/services/auth_service.dart';
import 'package:org_registration_app/screens/splash_screen.dart';
import 'package:org_registration_app/screens/auth/login_screen.dart';
import 'package:org_registration_app/screens/registration_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize your local DB if you still use it
  await AppDatabase.instance.init();

  runApp(const GlideRegisApp());
}

class GlideRegisApp extends StatefulWidget {
  const GlideRegisApp({super.key});

  @override
  State<GlideRegisApp> createState() => _GlideRegisAppState();
}

class _GlideRegisAppState extends State<GlideRegisApp> {
  final auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Org Registration',
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: Colors.black,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent,
              brightness: Brightness.dark,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF121212),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          home: auth.currentUser == null
              ? SplashScreen(
                  onStart: (context) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(auth: auth),
                      ),
                    );
                  },
                )
              : FutureBuilder<bool>(
                  future: auth.hasUserRegistration(
                      auth.currentUser!.uid), //  already updated
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text("Error loading user data"));
                    }
                    if (snapshot.hasData && snapshot.data == true) {
                      return UserShell(auth: auth); //  already registered
                    } else {
                      return const RegistrationScreen(); //  needs registration
                    }
                  },
                ),
        );
      },
    );
  }
}
