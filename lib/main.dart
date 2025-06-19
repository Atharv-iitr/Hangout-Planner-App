import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hangout_planner/Pages/first_deg.dart';
import 'package:hangout_planner/Pages/friends.dart';
import 'package:hangout_planner/Pages/home.dart';
import 'package:hangout_planner/Pages/invites.dart';
import 'package:hangout_planner/Pages/login_page.dart';
import 'package:hangout_planner/Pages/make_plan.dart';
import 'package:hangout_planner/Pages/notification.dart';
import 'package:hangout_planner/Pages/search.dart';
import 'package:hangout_planner/Pages/planspage.dart';
import 'package:hangout_planner/Pages/otp_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.hasData ? const HomePage() : const LoginPage();
        },
      ),
      routes: {
  '/planspage': (context) => const PlansPage(),
  '/home': (context) => const HomePage(),
  '/invitespage': (context) => const InvitesPage(),
  '/friendspage': (context) => const FriendsPage(),
  '/Notificationpage': (context) => const NotificationsPage(),
  '/makeplan': (context) => MakePlan(),
  '/login': (context) => const LoginPage(),
  '/search': (context) => const SearchPage(),
  '/firstdeg': (context) => const FirstDeg(planTitle: '', planDesc: ''),
  '/otp': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    return OTPPage(
      phoneNumber: args['phoneNumber'],
      isRegistration: args['isRegistration'] ?? false,
      username: args['username'],
      password: args['password'],
      name: args['name'],
    );
  },
},
    );
  }
}