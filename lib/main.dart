import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:habittracker/firebase_options.dart';
import 'package:habittracker/screen/home_view.dart';
import 'package:habittracker/screen/login_view.dart';
import 'package:habittracker/screen/profile_view.dart';
import 'package:habittracker/screen/signup_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF87CEEB), // Sky Blue
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthGate(),
        '/login': (context) => LoginView(),
        '/signup': (context) => SignupView(),
        '/home': (context) => HomeView(),
        '/profile': (context) => ProfileView(),
      },
      onGenerateRoute: (settings) {
        final routeBuilders = <String, WidgetBuilder>{
          '/': (context) => AuthGate(),
          '/login': (context) => LoginView(),
          '/signup': (context) => SignupView(),
          '/home': (context) => HomeView(),
          '/profile': (context) => ProfileView(),
        };

        final builder = settings.name != null
            ? routeBuilders[settings.name]
            : null;
        if (builder != null) {
          return MaterialPageRoute(builder: builder, settings: settings);
        }

        // Fallback to login to avoid null-assert in framework's default onGenerateRoute
        return MaterialPageRoute(
          builder: (_) => LoginView(),
          settings: settings,
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return LoginView();
        }
        return HomeView();
      },
    );
  }
}
