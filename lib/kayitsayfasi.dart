// ignore_for_file: prefer_const_constructors, unnecessary_set_literal

import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:starbankproject/main.dart';
import 'package:uuid/uuid.dart';

class kayitEkrani extends StatefulWidget {
  @override
  State<kayitEkrani> createState() => kayitEkraniState();
}

class kayitEkraniState extends State<kayitEkrani> {

  TextEditingController txtIDNumberController = TextEditingController();
  TextEditingController txtEmailController = TextEditingController();
  TextEditingController txtPhoneController = TextEditingController();
  TextEditingController txtNameSurnameController = TextEditingController();
  TextEditingController txtPasswordController = TextEditingController();
  TextEditingController txtRePasswordController = TextEditingController();


/////////////////////////////
  var uuid = Uuid();
  CollectionReference userRefCard =
      FirebaseFirestore.instance.collection('userCreditCards');
  Future<void> kartEkleMethod(//Kullanıcı kaydını oluşturduktan sonra hemen o kullanıcıya bir adet kart hesabı tanımlar (5000 TL)
    String userCreditBalanceParameter,
    String userIDParameter,
    String userNameParameter,
  ) async {
    String randomID = uuid.v1();
    DocumentReference userRefdoc = userRefCard.doc(randomID);
    Random random = Random();
    int randomCvv = 100 + random.nextInt(900);
    int randomMonth = 1 + random.nextInt(11);
    int randomYear = 25 + random.nextInt(10);

    int randomCreditNumber = random.nextInt(9) + 1;
    for (int i = 0; i < 15; i++) {
      randomCreditNumber = randomCreditNumber * 10 + random.nextInt(10);
    }

    await userRefdoc.set({
      'userCreditBalance': userCreditBalanceParameter,
      'userCreditCardNumber': randomCreditNumber.toString(),
      'userCreditCardsID': randomID,
      'userCreditCvvNumber': randomCvv.toString(),
      'userCreditLastDate':
          randomMonth.toString() + "/" + randomYear.toString(),
      'userID': userIDParameter,
      'userName': userNameParameter,
    }).whenComplete(() {});
  }

///////////////////////////////
  CollectionReference userRef =
      FirebaseFirestore.instance.collection('userValues');
  void kullaniciEkleMethod(String nameSurname, String email, String userPhone,
      String userIDNumber) async {// Auth. oluşturduktan sonra userValues vveritabanına kullanıcıların bilgilerini kaydeder.
    DocumentReference userRefdoc =
        userRef.doc(FirebaseAuth.instance.currentUser!.uid);

    await userRefdoc.set({
      'userName': nameSurname,
      'userMail': email,
      'userIDNumber': userIDNumber,
      'userID': FirebaseAuth.instance.currentUser!.uid,
      'userPhone': userPhone,
    }).whenComplete(() => {
          kartEkleMethod(
              "5000", FirebaseAuth.instance.currentUser!.uid, nameSurname),
          Fluttertoast.showToast(
              msg: "Kayıt tamamlandı!",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Color.fromARGB(255, 14, 20, 35),
              textColor: Colors.white,
              fontSize: 16.0),
          FirebaseAuth.instance.signOut(),
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => MyApp()))

          /* Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => homeScreen()))*/
        });
  }

  Future<void> kullaniciYaratMethod(String email, String password) async {//Kayıt ol butonuna basıldıgı anda Auth. kısmına kullanıcı ekler.
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .whenComplete(() => {
                kullaniciEkleMethod(txtNameSurnameController.text, email,
                    txtPhoneController.text, txtIDNumberController.text)
              });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        //  print('weak-password');
        Fluttertoast.showToast(
            msg: "Hatalı şifre formatı!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Color.fromARGB(255, 56, 14, 11),
            textColor: Colors.white,
            fontSize: 16.0);
      } else if (e.code == 'email-already-in-use') {
        Fluttertoast.showToast(
            msg: "Bu e-posta zaten kullanımda!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Color.fromARGB(255, 56, 14, 11),
            textColor: Colors.white,
            fontSize: 16.0);
      }
    } catch (e) {
      //    print(e);
    }
  }

  final _formKey = GlobalKey<FormState>();
  bool passwordEyes1 = true;
  bool passwordEyes2 = true;
  @override
  Widget build(BuildContext context) {//Tasarım kodları.
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/starBackSingup.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
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
                              SizedBox(height: 15),
                              Text(
                                "Kayıt Ol",
                                style: GoogleFonts.eduNswActFoundation(
                                    fontSize: 25, color: Colors.black),
                              ),
                              SizedBox(height: 8),
                              Text(
                                  "Finansal huzura açılan kapınız, Star Bankası",
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
                                controller: txtPhoneController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Telefon Numarası",
                                  prefixIcon: Icon(Icons.phone),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Telefon numaranızı giriniz';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                keyboardType: TextInputType.emailAddress,
                                controller: txtEmailController,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'E-postanızı girin';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: txtNameSurnameController,
                                decoration: InputDecoration(
                                  labelText: "Ad Soyad",
                                  prefixIcon: Icon(Icons.text_fields),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Adınızı soyadınızı giriniz';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: txtPasswordController,
                                obscureText: passwordEyes1,
                                decoration: InputDecoration(
                                  labelText: "Şifre",
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: InkWell(
                                      onTap: () {
                                        setState(() {
                                          passwordEyes1 = !passwordEyes1;
                                        });
                                      },
                                      child: Icon(Icons.visibility)),
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
                              TextFormField(
                                controller: txtRePasswordController,
                                obscureText: passwordEyes2,
                                decoration: InputDecoration(
                                  labelText: "Şifreyi Tekrar Gir",
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: InkWell(
                                      onTap: () {
                                        setState(() {
                                          passwordEyes2 = !passwordEyes2;
                                        });
                                      },
                                      child: Icon(Icons.visibility)),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Şifrenizi tekrar girin';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      if (txtPasswordController.text ==
                                          txtRePasswordController.text) {
                                        kullaniciYaratMethod(txtEmailController.text,
                                            txtPasswordController.text);
                                      } else {
                                        Fluttertoast.showToast(
                                            msg: "Şifreler uyuşmuyor!",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.BOTTOM,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor:
                                                Color.fromARGB(255, 56, 14, 11),
                                            textColor: Colors.white,
                                            fontSize: 16.0);
                                      }
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
                                    "Bir hesap oluşturun",
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
                                    Text("Zaten bir hesabınız var mı?"),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text("Giriş Yapın"),
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
