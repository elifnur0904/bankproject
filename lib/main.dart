import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:starbankproject/anaekran.dart';
import 'package:starbankproject/firebase_options.dart';
import 'package:starbankproject/girissayfasi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Star Bankası',
      home: SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late bool loginState;
  void girisKontrolMethod() {
    //Oturum açıkmı değilmi kontrol methodu
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('Kullanıcı şu anda çıkış yapmış durumda!');
        setState(() {
          loginState = false;
        });
      } else {
        setState(() {
          loginState = true;
        });
        print('Kullanıcı oturum açtı!');
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    girisKontrolMethod();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !loginState
          ? girisEkrani()
          : anaSayfa(), //Oturum açık değilse signin sayfasına yönlendirir. Açıksa anasayfaya(homepage) yönlendirir.
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      // Navigate to the Home Screen after 3 seconds
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MyHomePage(title: 'Star Bank')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.blue,
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Image.asset(
          'assets/images/star.png',
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
