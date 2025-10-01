import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_bite_try1/screens/deliveryPerson/delivery_person_home_Screen.dart';
import 'package:share_bite_try1/screens/donors/home_screenDonor.dart';
import 'package:share_bite_try1/screens/introduction_screen.dart';
import 'package:share_bite_try1/screens/ngos/NGOHomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareBite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool isLoading = true;
  bool isAuthenticated = false;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      // Check if user is signed in with Firebase Auth
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // User is signed in, now check if their data exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          // User data exists, they're fully authenticated
          setState(() {
            isAuthenticated = true;
            userData = userDoc.data();
            isLoading = false;
          });
          return;
        } else {
          // Firebase Auth user exists but no Firestore data
          // This might happen if registration wasn't completed
          await FirebaseAuth.instance.signOut();
        }
      }

      // User is not authenticated or incomplete registration
      setState(() {
        isAuthenticated = false;
        isLoading = false;
      });

    } catch (e) {
      print('Error checking authentication: $e');
      setState(() {
        isAuthenticated = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SplashScreen();
    }

    if (isAuthenticated && userData != null) {
      return RoleBasedHomeScreen(userRole: userData!['role']);
    }

    return const IntroductionPage();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: size.height * 0.25,
                    width: size.width * 0.6,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // App name
            const Text(
              'ShareBite',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(57, 81, 68, 1.0),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Share food, spread kindness',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 50),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.fromRGBO(57, 81, 68, 1.0),
              ),
              strokeWidth: 3,
            ),

            const SizedBox(height: 20),

            Text(
              'Checking authentication...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleBasedHomeScreen extends StatelessWidget {
  final String userRole;

  const RoleBasedHomeScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    switch (userRole) {
      case "Donor":
        return const DonorHomeScreen();
      case "NGO":
        return const NGOHomeScreen();
      case "Delivery Partner":
        return const DeliveryHomeScreen();
      default:
      // Fallback to donor screen if role is unrecognized
        return const DonorHomeScreen();
    }
  }
}