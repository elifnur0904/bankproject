// ignore_for_file: prefer_const_constructors

import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:starbankproject/kayitsayfasi.dart';
import 'package:starbankproject/main.dart';

class girisEkrani extends StatefulWidget {
  @override
  State<girisEkrani> createState() => girisEkraniState();
}

class girisEkraniState extends State<girisEkrani> {
  bool passwordEyes = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> loginUser(String email, String sifre) async {
    //Kullanıcının o cihazda oturum(session) açmasına olanak sağlar.

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: sifre)
          .whenComplete(() {
        //  print("-------OK----");

        {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => MyApp()));
        }
        ;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Fluttertoast.showToast(
            msg: "Kullanıcı bulunamadı!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Color.fromARGB(255, 56, 14, 11),
            textColor: Colors.white,
            fontSize: 16.0);
      } else if (e.code == 'wrong-password') {
        Fluttertoast.showToast(
            msg: "Yanlış şifre!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Color.fromARGB(255, 56, 14, 11),
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        Fluttertoast.showToast(
            msg: "Giriş hatası!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Color.fromARGB(255, 56, 14, 11),
            textColor: Colors.white,
            fontSize: 16.0);
      }
    }
  }

  Future<void> controlIDNumberUser(String userIDNumberPar, String passwordPar) {
    //Kullanıcının girmiş oldugu TC numarasının emailini bulmak için kullanılan method
    CollectionReference users =
        FirebaseFirestore.instance.collection('userValues');

    return users
        .where('userIDNumber', isEqualTo: userIDNumberPar)
        .get()
        .then((QuerySnapshot snapshot) {
      snapshot.docs.forEach((doc) {
        loginUser(doc.get('userMail'), passwordPar);
      });
    }).catchError((error) => print("Kullanıcılar alınamadı: $error"));
  }

  TextEditingController txtIDNumberController =
      TextEditingController(); //TC girilen kutu
  TextEditingController txtPasswordController =
      TextEditingController(); //Şifre girilen kutu

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/starBack.png"),
                    fit: BoxFit.cover, // Tam ekrana sığacak şekilde ayarlandı
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width,
                                child: Text(
                                  "Star Bankası",
                                  style: GoogleFonts.eduNswActFoundation(
                                      fontSize: 45,
                                      color: Color.fromARGB(255, 5, 15, 56)),
                                ),
                              ),
                              SizedBox(height: 30),
                              Text(
                                "Giris Yap",
                                style: GoogleFonts.eduNswActFoundation(
                                    fontSize: 25, color: Colors.black),
                              ),
                              SizedBox(height: 8),
                              Text(
                                  "Finansal islemlerinize baslamadan önce lütfen giris yapın!",
                                  style: GoogleFonts.eduNswActFoundation(
                                      fontSize: 17, color: Colors.grey)),
                              SizedBox(height: 32),
                              TextFormField(
                                controller: txtIDNumberController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "T.C. NO",
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kimlik Numaranızı Girin';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: txtPasswordController,
                                obscureText: passwordEyes,
                                decoration: InputDecoration(
                                  labelText: "Şifre",
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: InkWell(
                                    onTap: () {
                                      setState(() {
                                        passwordEyes = !passwordEyes;
                                      });
                                    },
                                    child: Icon(Icons.visibility),
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Şifrenizi girin';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      controlIDNumberUser(
                                          txtIDNumberController.text,
                                          txtPasswordController.text);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(255, 5, 15, 56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    "Hesaba giriş yapın",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Hesabınız yok mu?"),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    kayitEkrani()));
                                      },
                                      child: Text("Üye Ol"),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ))));
  }
}
