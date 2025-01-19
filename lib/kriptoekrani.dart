// ignore_for_file: prefer_const_constructors, prefer_interpolation_to_compose_strings, unnecessary_set_literal

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:starbankproject/kriptografik.dart';
import 'package:starbankproject/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_dialogs/widgets/buttons/icon_outline_button.dart';
import 'package:material_dialogs/material_dialogs.dart';
import 'package:starbankproject/profilsayfasi.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class kriptoEkrani extends StatefulWidget {
  @override
  State<kriptoEkrani> createState() => kriptoEkraniState();
}

class kriptoEkraniState extends State<kriptoEkrani> {
  List<String> kriptoBaslikList = [];
  List<String> kriptoFiyatList = [];



  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Map<String, double> oncekiFiyatList = {};
  Map<String, IconData> kriptoIconList = {};
  Future<void> kriptoBilgiGetirMethod() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.binance.com/api/v3/ticker/price'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<String> kriptoNameList = [];
        List<String> kriptoPriceList = [];

        setState(() {
          kriptoBaslikList.clear();
          kriptoFiyatList.clear();

          for (var item in data) {
            final symbol = item['symbol'].toString().toUpperCase();
            final currentPrice = double.tryParse(item['price']) ?? 0.0;

            // Önceki fiyat ile karşılaştır
            if (oncekiFiyatList.containsKey(symbol)) {
              double previousPrice = oncekiFiyatList[symbol]!;
              if (currentPrice > previousPrice) {
                kriptoIconList[symbol] = Icons.arrow_upward; // Yükseldi
              } else if (currentPrice < previousPrice) {
                kriptoIconList[symbol] = Icons.arrow_downward; // Düştü
              } else {
                kriptoIconList[symbol] = Icons.remove; // Değişmedi
              }
            } else {
              kriptoIconList[symbol] =
                  Icons.remove; // İlk yüklemede ikon yatay çizgi olur
            }

            // Yeni fiyatı sakla
            oncekiFiyatList[symbol] = currentPrice;

            kriptoNameList.add(symbol);
            kriptoPriceList.add(currentPrice.toString());
          }

          cryptos = data;
          kriptoBaslikList = kriptoNameList;
          kriptoFiyatList = kriptoPriceList;
        });
      } else {
        throw Exception('Failed to load crypto data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veri yüklenemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    kriptoBilgiGetirMethod();
    timer = Timer.periodic(const Duration(seconds: 2), (Timer t) {
      kriptoBilgiGetirMethod();
    });
    kartBilgiGetir();
  }

  CollectionReference userRefHistory =
      FirebaseFirestore.instance.collection('accountTransactionHistory');
  String userNameSurname = "";
  Future<void> kullaniciBilgiGetir() {
    CollectionReference users =
        FirebaseFirestore.instance.collection('userValues');
    return users
        .where('userID', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((QuerySnapshot snapshot) {
      snapshot.docs.forEach((doc) {
        setState(() {
          userNameSurname = doc.get('userName');
        });
      });
    }).catchError((error) => print("Failed to fetch users: $error"));
  }

  void guncelleDataMethod(
      String documentId, String newValue, String deleteDocID) async {
    //Para değerini güncelleyen method.
    CollectionReference users =
        FirebaseFirestore.instance.collection('userCreditCards');

    try {
      await users.doc(documentId).update({'userCreditBalance': newValue});
      satisMethod(deleteDocID).whenComplete(() {});
    } catch (e) {
      print("Failed to update data: $e");
    }
  }

  kontrolVeGuncelleMethodForeign(
      String cardNumber, String newBalancecalc) async {
    //Para değerini güncelleyen method.
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('userCreditCards')
        .where('userCreditCardNumber', isEqualTo: cardNumber)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        DocumentReference documentRef = FirebaseFirestore.instance
            .collection('userCreditCards')
            .doc(doc.get('userCreditCardsID'));
        try {
          await documentRef.update({
            'userCreditBalance': newBalancecalc.toString(),
          });
        } catch (Er) {}
      }

      Fluttertoast.showToast(
          msg: "Kripto yüklendi!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 7, 15, 34),
          textColor: Colors.white,
          fontSize: 16.0);
      kartBilgiGetir().whenComplete(() {
        Navigator.pop(context);
      });
    }
  }

  var uuid = Uuid();
  Future<void> kontrolVeGuncelleMethod(String cardNumber, String newBalanceSent,
      String newBalanceSender, String docIDSender) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('userCreditCards')
        .where('userCreditCardNumber', isEqualTo: cardNumber)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        DocumentReference documentRef = FirebaseFirestore.instance
            .collection('userCreditCards')
            .doc(doc.get('userCreditCardsID'));

        try {
          int newBalancecalc = int.parse(doc.get('userCreditBalance')) +
              int.parse(newBalanceSent);
          await documentRef.update({
            'userCreditBalance': newBalancecalc.toString(),
          }).whenComplete(() async {
            print("Updated successfully.");
            /////////////////////////
            DocumentReference documentRefR = FirebaseFirestore.instance
                .collection('userCreditCards')
                .doc(docIDSender);

            try {
              await documentRefR.update({
                'userCreditBalance': newBalanceSender,
              }).whenComplete(() async {
                /////////////////////////
                String generateID = uuid.v4();
                DocumentReference userRefHistorydoc =
                    userRefHistory.doc(generateID);
                DateTime now = DateTime.now();
                String formattedDate =
                    DateFormat('kk:mm:ss \n EEE d MMM').format(now);

                await userRefHistorydoc.set({
                  //Gelen para giden para bilgilerini görebilmemiz için accountTransactionHistory tablosuna veri kaydeder.
                  'amount': txtMoneyController.text,
                  'cardNumberTransaction': userCreditCardNumberList[
                      userCreditCardNumberList
                          .indexOf(_selectedItem.toString())],
                  'userIDTransactionSender':
                      FirebaseAuth.instance.currentUser!.uid,
                  'explane': txtExplaneController.text,
                  'state': "0",
                  'historyID': generateID,
                  'transactionDate': formattedDate
                }).whenComplete(() async {
                  String generateID = uuid.v4();
                  userRefHistorydoc = userRefHistory.doc(generateID);
                  await userRefHistorydoc.set({
                    'amount': txtMoneyController.text,
                    'cardNumberTransaction': txtIBANController.text,
                    'userIDTransactionSender': doc.get('userID'),
                    'explane': txtExplaneController.text,
                    'state': "1",
                    'historyID': generateID,
                    'transactionDate': formattedDate
                  });
                });
                ////////////////////////////
              });
              print("Updated successfully.");
            } catch (e) {
              print("Error updating: $e");
            }
            ////////////////////////////
            Fluttertoast.showToast(
                msg: "Para gönderildi!",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Color.fromARGB(255, 7, 15, 34),
                textColor: Colors.white,
                fontSize: 16.0);
            kartBilgiGetir().whenComplete(() {
              Navigator.pop(context);
            });
          });
        } catch (e) {
          print("Error updating: $e");
        }
        print("??: " + docIDSender);
      }
    } else {
      Fluttertoast.showToast(
          msg: "IBAN numarası bulunamadı!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 14, 20, 35),
          textColor: Colors.white,
          fontSize: 16.0);
      print("No documents found with the specified email.");
    }
  }

  Future<void> cikisYap() async {
    //Çıkış yap methodu.
    await FirebaseAuth.instance.signOut().whenComplete(() {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MyApp()));
    });
  }

  String chooseExchangeAmount = "";
  String chooseExchangeName = "";
  List<String> userCreditBalanceList = [];
  List<String> userCreditCardNumberList = [];
  List<String> userCreditCardsIDList = [];
  List<String> userCreditCvvNumberList = [];
  List<String> userCreditLastDateList = [];
  List<String> userNameList = [];

  Future<void> kartBilgiGetir() {
    //Sayfa ilk açıldıgı anda kullanıcının kart bilgileri bu method ile yüklenir.
    userCreditBalanceList = [];
    userCreditCardNumberList = [];
    userCreditCardsIDList = [];
    userCreditCvvNumberList = [];
    userCreditLastDateList = [];
    userNameList = [];
    CollectionReference users =
        FirebaseFirestore.instance.collection('userCreditCards');
    return users
        .where('userID', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((QuerySnapshot snapshot) {
      snapshot.docs.forEach((doc) {
        setState(() {
          userCreditBalanceList.add(doc.get('userCreditBalance'));
          userCreditCardNumberList.add(doc.get('userCreditCardNumber'));
          userCreditCardsIDList.add(doc.get('userCreditCardsID'));
          userCreditCvvNumberList.add(doc.get('userCreditCvvNumber'));
          userCreditLastDateList.add(doc.get('userCreditLastDate'));
          userNameList.add(doc.get('userName'));
        });
      });
    }).catchError((error) => print("Failed to fetch users: $error"));
  }

  Future<void> kaldirMethod(String docId) async {
    //Kredi kartı kaldırma methodu.
    try {
      await FirebaseFirestore.instance
          .collection('userCreditCards')
          .doc(docId)
          .delete();

      Fluttertoast.showToast(
          msg: "Kartınız kaldırıldı!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 14, 20, 35),
          textColor: Colors.white,
          fontSize: 16.0);
      kartBilgiGetir().whenComplete(() {
        Navigator.pop(context);
      });
    } catch (e) {
      print('Belge silinirken bir hata oluştu: $e');
    }
  }

  Future<void> satisMethod(String docId) async {
    //Döviz satma methodu.
    try {
      await FirebaseFirestore.instance
          .collection('foreignTransaction')
          .doc(docId)
          .delete();
      Navigator.pop(context);
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: "Kripto satıldı!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 14, 20, 35),
          textColor: Colors.white,
          fontSize: 16.0);
      kartBilgiGetir();
    } catch (e) {
      print('Belge silinirken bir hata oluştu: $e');
    }
  }

  CollectionReference userRef =
      FirebaseFirestore.instance.collection('userCreditCards');
  Future<void> kartEkleMethod(
    //Kullanıcıya ait bir kart eklemek için kullanılan method.
    String userCreditBalanceParameter,
    String userIDParameter,
    String userNameParameter,
  ) async {
    String randomID = uuid.v1();
    DocumentReference userRefdoc = userRef.doc(randomID);
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
    }).whenComplete(() {
      Fluttertoast.showToast(
          msg: "Kartınız oluşturuldu!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 14, 20, 35),
          textColor: Colors.white,
          fontSize: 16.0);
    });
  }

  List cryptos = [];
  Timer? timer;
  double totalAmount = 0;
  TextEditingController txtManyCurrenciesController = TextEditingController();
  TextEditingController txtIBANController = TextEditingController();
  TextEditingController txtMoneyController = TextEditingController();
  TextEditingController txtExplaneController = TextEditingController();
  final _key = GlobalKey<ExpandableFabState>();
  String? _selectedItem;
  String? _selectedItemForeign;
  @override
  Widget build(BuildContext context) {
    //TASARIM KODLARI
    return Scaffold(
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _key,
        type: ExpandableFabType.up,
        childrenAnimation: ExpandableFabAnimation.none,
        distance: 70,
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.white.withOpacity(0.9),
        ),
        children: [
          Row(children: [
            Text('Profil'),
            SizedBox(width: 20),
            FloatingActionButton.small(
              heroTag: null,
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => profilEkrani()));
              },
              child: Icon(Icons.person),
            ),
          ]),
          Row(
            children: [
              Text('Kripto İşlemleri'),
              SizedBox(width: 20),
              FloatingActionButton.small(
                heroTag: null,
                onPressed: () {
                  totalAmount = 0;
                  showBarModalBottomSheet(
                      // expand: true,
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                          color: Colors.white,
                          height: MediaQuery.of(context).size.height / 1.2,
                          child: StatefulBuilder(builder:
                              (BuildContext context, StateSetter setStatef) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  margin: EdgeInsets.all(5),
                                  height: 30,
                                  color: Color.fromARGB(149, 29, 38, 63),
                                  width: MediaQuery.of(context).size.width,
                                  child: Text(
                                    "Yatırılacak Hesabı Seçin",
                                    style: GoogleFonts.arima(
                                        fontSize: 20, color: Colors.white),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: MediaQuery.of(context).size.width,
                                  child: DropdownButton<String>(
                                    value:
                                        _selectedItemForeign, // Sets the selected item
                                    hint: Text(
                                      "Hesap Seçin",
                                      style: GoogleFonts.arima(),
                                    ), // Hint text when nothing is selected
                                    items: userCreditCardNumberList
                                        .map((String item) {
                                      return DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            "Hesap: " +
                                                item +
                                                " - " +
                                                userCreditBalanceList[
                                                    userCreditCardNumberList
                                                        .indexOf(item)] +
                                                " TL"),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setStatef(() {
                                        _selectedItemForeign = newValue;
                                      });
                                      //  Navigator.pop(context);
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  margin: EdgeInsets.all(5),
                                  height: 30,
                                  color: Color.fromARGB(149, 29, 38, 63),
                                  width: MediaQuery.of(context).size.width,
                                  child: Text(
                                    "Güncel Borsalar",
                                    style: GoogleFonts.arima(
                                        fontSize: 20, color: Colors.white),
                                  ),
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height / 2.5,
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('foreignTransaction')
                                        .where('userID',
                                            isEqualTo: FirebaseAuth
                                                .instance.currentUser!.uid)
                                        .snapshots(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<QuerySnapshot> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        return Center(
                                            child: Text(
                                                'Hiçbir kripto alınmadı!'));
                                      }

                                      return ListView(
                                        children: snapshot.data!.docs
                                            .map((DocumentSnapshot document) {
                                          Map<String, dynamic> data = document
                                              .data()! as Map<String, dynamic>;

                                          totalAmount += double.parse(
                                              data['foreignTotalAmount']
                                                  .toString());

                                          return Container(
                                              height: 30,
                                              alignment: Alignment.center,
                                              margin:
                                                  EdgeInsets.only(bottom: 4),
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              child: Row(
                                                children: [
                                                  Container(
                                                      height: 30,
                                                      color: Color.fromARGB(
                                                          156, 117, 179, 119),
                                                      alignment:
                                                          Alignment.center,
                                                      margin: EdgeInsets.only(
                                                          bottom: 4),
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              2,
                                                      child: Text(
                                                          data['foreignName']
                                                              .toString()
                                                              .toUpperCase())),
                                                  Container(
                                                      height: 30,
                                                      color: Color.fromARGB(
                                                          255, 111, 189, 113),
                                                      alignment:
                                                          Alignment.center,
                                                      margin: EdgeInsets.only(
                                                          bottom: 4),
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              3,
                                                      child: Text(
                                                          data['foreignTotal']
                                                                  .toString() +
                                                              " adet")),
                                                  Container(
                                                    height: 30,
                                                    color: Color.fromARGB(
                                                        255, 149, 169, 150),
                                                    alignment: Alignment.center,
                                                    margin: EdgeInsets.only(
                                                        bottom: 4),
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            6.7,
                                                    child: InkWell(
                                                      onTap: () {
                                                        double resultcalc = (double.parse(
                                                                    data['foreignTotal']
                                                                        .toString()) *
                                                                double.parse(kriptoFiyatList[kriptoBaslikList.indexOf(data[
                                                                        'foreignName']
                                                                    .toString()
                                                                    .toUpperCase())])) +
                                                            double.parse(userCreditBalanceList[
                                                                userCreditCardNumberList
                                                                    .indexOf(
                                                                        _selectedItemForeign!)]);

                                                        double resultcalcEarning = (double.parse(kriptoFiyatList[kriptoBaslikList.indexOf(data[
                                                                            'foreignName']
                                                                        .toString()
                                                                        .toUpperCase())]
                                                                    .toString()) *
                                                                double.parse(data[
                                                                        'foreignTotal']
                                                                    .toString())) -
                                                            double.parse(data[
                                                                    'foreignTotalAmount']
                                                                .toString());
//////////////
                                                        Dialogs.materialDialog(
                                                            msg: 'Satmak istiyor musunuz ' +
                                                                data['foreignTotal']
                                                                    .toString() +
                                                                ' adet? ' +
                                                                "\n Bu işlemden elde ettiğiniz kazançlar: " +
                                                                resultcalcEarning
                                                                    .toString() +
                                                                " TL",
                                                            title: "SATIŞ",
                                                            color: Colors.white,
                                                            context: context,
                                                            actions: [
                                                              IconsOutlineButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                text: 'Kapat',
                                                                iconData: Icons
                                                                    .cancel_outlined,
                                                                textStyle: TextStyle(
                                                                    color: Colors
                                                                        .grey),
                                                                iconColor:
                                                                    Colors.grey,
                                                              ),
                                                              IconsOutlineButton(
                                                                color: const Color
                                                                    .fromARGB(
                                                                    88,
                                                                    255,
                                                                    193,
                                                                    7),
                                                                onPressed: () {
                                                                  guncelleDataMethod(
                                                                      userCreditCardsIDList[
                                                                          userCreditCardNumberList.indexOf(
                                                                              _selectedItemForeign!)],
                                                                      resultcalc
                                                                          .toString(),
                                                                      data['foreignID']
                                                                          .toString());
                                                                },
                                                                text: 'SATIŞ',
                                                                iconData:
                                                                    Icons.sell,
                                                                textStyle: TextStyle(
                                                                    color: Colors
                                                                        .grey),
                                                                iconColor:
                                                                    Colors.grey,
                                                              ),
                                                            ]);
                                                        ///////////
                                                      },
                                                      child: Icon(
                                                        Icons.sell,
                                                        color: Color.fromARGB(
                                                            255, 38, 19, 131),
                                                        size: 17,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ));
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: 7,
                                ),
                                Divider(
                                  thickness: 2,
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  alignment: Alignment.center,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Dialogs.materialDialog(
                                          msg: 'TOPLAM VARLIK TUTARINIZ: ' +
                                              totalAmount.toString(),
                                          title: "TOPLAM VARLIK TUTARI",
                                          color: Colors.white,
                                          context: context,
                                          actions: [
                                            IconsOutlineButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              text: 'Kapat',
                                              iconData: Icons.cancel_outlined,
                                              textStyle:
                                                  TextStyle(color: Colors.grey),
                                              iconColor: Colors.grey,
                                            ),
                                          ]);
                                    },
                                    icon: Icon(Icons.graphic_eq, size: 18),
                                    label: Text(
                                        "Toplam varlıkları görmek için tıklayın"),
                                  ),
                                )
                              ],
                            );
                          })));
                },
                child: Icon(Icons.money_sharp),
              ),
            ],
          ),
          Row(
            children: [
              Text('Kart Hesap İşlemleri'),
              SizedBox(width: 20),
              FloatingActionButton.small(
                heroTag: null,
                onPressed: () {
                  showBarModalBottomSheet(
                      // expand: true,
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                          color: Colors.white,
                          height: MediaQuery.of(context).size.height / 1.2,
                          child: StatefulBuilder(builder:
                              (BuildContext context, StateSetter setStatef) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  margin: EdgeInsets.all(5),
                                  height: 30,
                                  color: Color.fromARGB(149, 29, 38, 63),
                                  width: MediaQuery.of(context).size.width,
                                  child: Text(
                                    "Kart Hesap İşlemleri",
                                    style: GoogleFonts.arima(
                                        fontSize: 20, color: Colors.white),
                                  ),
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height / 1.3,
                                  child: StreamBuilder(
                                    stream: FirebaseFirestore.instance
                                        .collection('accountTransactionHistory')
                                        .where('userIDTransactionSender',
                                            isEqualTo: FirebaseAuth
                                                .instance.currentUser!.uid)
                                        .snapshots(),
                                    builder: (context,
                                        AsyncSnapshot<QuerySnapshot> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        return Center(child: Text("Veri yok!"));
                                      }

                                      // Map the data into a list of widgets
                                      final resultStream =
                                          snapshot.data!.docs.map((doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        return Column(children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                data['transactionDate']
                                                    .toString(),
                                                softWrap:
                                                    true, // Metin alanına sığmadığında alt satıra geçmesini sağlar
                                                maxLines: null,
                                              ),
                                              Column(
                                                children: [
                                                  Text(data['state']
                                                              .toString() ==
                                                          "0"
                                                      ? "Gelen Para"
                                                      : "Giden Para"),
                                                  Text("** " +
                                                      data['cardNumberTransaction']
                                                          .toString()
                                                          .substring(
                                                              data['cardNumberTransaction']
                                                                      .toString()
                                                                      .length -
                                                                  4)),
                                                ],
                                              ),
                                              Text(
                                                data['state'].toString() == "0"
                                                    ? "+" + data['amount']
                                                    : "-" + data['amount'],
                                                style: TextStyle(
                                                    color: data['state']
                                                                .toString() ==
                                                            "0"
                                                        ? Colors.green
                                                        : Colors.red),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 20,
                                          )
                                        ]);
                                      }).toList();

                                      return ListView(children: resultStream);
                                    },
                                  ),
                                )
                              ],
                            );
                          })));
                },
                child: Icon(Icons.credit_card),
              ),
            ],
          ),
          Row(
            children: [
              Text('Para transferi'),
              SizedBox(width: 20),
              FloatingActionButton.small(
                heroTag: null,
                onPressed: () {
                  showBarModalBottomSheet(
                    // expand: true,
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      color: Colors.white,
                      height: MediaQuery.of(context).size.height / 1.2,
                      child: StatefulBuilder(builder:
                          (BuildContext context, StateSetter setStatef) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              margin: EdgeInsets.all(5),
                              height: 30,
                              color: Color.fromARGB(190, 17, 41, 55),
                              width: MediaQuery.of(context).size.width,
                              child: Text(
                                "Hesap Seçin",
                                style: GoogleFonts.arima(
                                    fontSize: 20, color: Colors.white),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              margin: EdgeInsets.only(left: 10),
                              child: DropdownButton<String>(
                                value: _selectedItem, // Sets the selected item
                                hint: Text(
                                  "Hesap Seçin",
                                  style: GoogleFonts.arima(),
                                ), // Hint text when nothing is selected
                                items:
                                    userCreditCardNumberList.map((String item) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text("Hesap: " +
                                        item +
                                        " - " +
                                        userCreditBalanceList[
                                            userCreditCardNumberList
                                                .indexOf(item)] +
                                        " TL"),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setStatef(() {
                                    _selectedItem = newValue;
                                  });
                                  //  Navigator.pop(context);
                                },
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              alignment: Alignment.center,
                              margin: EdgeInsets.all(5),
                              height: 30,
                              color: Color.fromARGB(191, 17, 41, 55),
                              width: MediaQuery.of(context).size.width,
                              child: Text(
                                "Gönderilecek Hesabı Girin",
                                style: GoogleFonts.arima(
                                    fontSize: 20, color: Colors.white),
                              ),
                            ),
                            Container(
                              child: TextFormField(
                                maxLength: 16,
                                controller: txtIBANController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  icon: Icon(Icons.money),
                                  labelText: 'Hesap IBAN ı',
                                  labelStyle: TextStyle(
                                    color: Color(0xFF6200EE),
                                  ),
                                  helperText: 'Hesap IBANını girin',
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFF6200EE)),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              child: TextFormField(
                                controller: txtMoneyController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  icon: Icon(Icons.attach_money),
                                  labelText: 'Miktar',
                                  labelStyle: TextStyle(
                                    color: Color(0xFF6200EE),
                                  ),
                                  helperText: 'Gönderilecek miktar?',
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFF6200EE)),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              child: TextFormField(
                                controller: txtExplaneController,
                                decoration: InputDecoration(
                                  icon: Icon(Icons.text_fields),
                                  labelText: 'Açıklama',
                                  labelStyle: TextStyle(
                                    color: Color(0xFF6200EE),
                                  ),
                                  helperText: 'Lütfen açıklamayı giriniz?',
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFF6200EE)),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 25,
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              alignment: Alignment.center,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (txtIBANController.text != "" ||
                                      txtMoneyController.text != "" ||
                                      txtExplaneController.text != "") {
                                    int accountMoney = int.parse(
                                        userCreditBalanceList[
                                            userCreditCardNumberList.indexOf(
                                                _selectedItem.toString())]);
                                    int enteredMoney =
                                        int.parse(txtMoneyController.text);

                                    if (enteredMoney > accountMoney) {
                                      Fluttertoast.showToast(
                                          msg:
                                              "Hesabınızdaki tutar yeterli değil!",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.BOTTOM,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor:
                                              Color.fromARGB(255, 14, 20, 35),
                                          textColor: Colors.white,
                                          fontSize: 16.0);
                                    } else {
                                      int calcSenderBalanace =
                                          accountMoney - enteredMoney;
                                      print("-->" +
                                          calcSenderBalanace.toString());
                                      if (txtIBANController.text ==
                                          userCreditCardNumberList[
                                              userCreditCardNumberList.indexOf(
                                                  _selectedItem.toString())]) {
                                        Fluttertoast.showToast(
                                            msg:
                                                "Aynı hesaba gönderim yapamazsınız!",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.BOTTOM,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor:
                                                Color.fromARGB(255, 14, 20, 35),
                                            textColor: Colors.white,
                                            fontSize: 16.0);
                                      } else {
                                        kontrolVeGuncelleMethod(
                                                txtIBANController.text,
                                                enteredMoney.toString(),
                                                calcSenderBalanace.toString(),
                                                userCreditCardsIDList[
                                                    userCreditCardNumberList
                                                        .indexOf(_selectedItem
                                                            .toString())])
                                            .whenComplete(() {});
                                      }
                                    }
                                  } else {
                                    Fluttertoast.showToast(
                                        msg: "Lütfen boşluk bırakmayınız!",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor:
                                            Color.fromARGB(255, 14, 20, 35),
                                        textColor: Colors.white,
                                        fontSize: 16.0);
                                  }
                                },
                                icon: Icon(Icons.send, size: 18),
                                label: Text("PARA GÖNDER"),
                              ),
                            )
                          ],
                        );
                      }),
                    ),
                  );
                },
                child: Icon(Icons.attach_money_outlined),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 25,
            ),
            Container(
                margin: EdgeInsets.only(right: 15, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 9,
                        ),
                        Text(
                          "Kripto Varlıkları",
                          style: GoogleFonts.mukta(
                              fontSize: 23,
                              color: Color.fromARGB(255, 5, 15, 56)),
                        )
                      ],
                    ),
                  ],
                )),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10),
              height: MediaQuery.of(context).size.height - 100,
              child: kriptoFiyatList.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: kriptoFiyatList.length,
                      itemBuilder: (context, index) {
                        final symbol = kriptoBaslikList[index];
                        final price = kriptoFiyatList[index];
                        final IconData icon =
                            kriptoIconList[symbol] ?? Icons.remove;
                        Color bgColor = Colors.white;
                        if (icon == Icons.arrow_upward) {
                          bgColor =
                              Colors.green.withOpacity(0.5); // Yükselme rengi
                        } else if (icon == Icons.arrow_downward) {
                          bgColor = Colors.red.withOpacity(0.5); // Düşüş rengi
                        }
                        return AnimatedContainer(
                            duration:
                                const Duration(seconds: 1), // Animasyon süresi
                            curve: Curves.easeOut, // Yavaşça sönmesini sağlar
                            color: bgColor, // Arkaplan rengi

                            child: ListTile(
                              leading: Icon(
                                  kriptoIconList[symbol] ?? Icons.remove,
                                  color: kriptoIconList[symbol] ==
                                          Icons.arrow_upward
                                      ? Colors.green
                                      : kriptoIconList[symbol] ==
                                              Icons.arrow_downward
                                          ? Colors.red
                                          : Colors.grey),
                              title: Text(kriptoBaslikList[index]),
                              subtitle: Text(
                                '${kriptoFiyatList[index]} TRY',
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: Container(
                                  width: 80,
                                  child: Row(
                                    children: [
                                      Container(
                                          height: 35,
                                          width: 35,
                                          child: FloatingActionButton(
                                            onPressed: () {
                                              setState(() {
                                                chooseExchangeAmount =
                                                    kriptoFiyatList[index]
                                                        .toString();
                                                chooseExchangeName =
                                                    kriptoBaslikList[index]
                                                        .toString()
                                                        .toUpperCase();
                                              });
                                              showBarModalBottomSheet(
                                                  // expand: true,
                                                  context: context,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  builder: (context) =>
                                                      Container(
                                                          color: Colors.white,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height /
                                                              1.2,
                                                          child: StatefulBuilder(
                                                              builder: (BuildContext
                                                                      context,
                                                                  StateSetter
                                                                      setStatefr) {
                                                            String stateText =
                                                                "Kripto tutarını girin";
                                                            double calcForeign =
                                                                0;
                                                            return Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Container(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  margin:
                                                                      EdgeInsets
                                                                          .all(
                                                                              5),
                                                                  height: 30,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          190,
                                                                          17,
                                                                          41,
                                                                          55),
                                                                  width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  child: Text(
                                                                    "Hesap Seçin",
                                                                    style: GoogleFonts.arima(
                                                                        fontSize:
                                                                            20,
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  margin: EdgeInsets
                                                                      .only(
                                                                          left:
                                                                              10),
                                                                  child:
                                                                      DropdownButton<
                                                                          String>(
                                                                    value:
                                                                        _selectedItem, // Sets the selected item
                                                                    hint: Text(
                                                                      "Hesap Seçin",
                                                                      style: GoogleFonts
                                                                          .arima(),
                                                                    ), // Hint text when nothing is selected
                                                                    items: userCreditCardNumberList
                                                                        .map((String
                                                                            item) {
                                                                      return DropdownMenuItem<
                                                                          String>(
                                                                        value:
                                                                            item,
                                                                        child: Text("Hesap: " +
                                                                            item +
                                                                            " - " +
                                                                            userCreditBalanceList[userCreditCardNumberList.indexOf(item)] +
                                                                            " TL"),
                                                                      );
                                                                    }).toList(),
                                                                    onChanged:
                                                                        (String?
                                                                            newValue) {
                                                                      setStatefr(
                                                                          () {
                                                                        _selectedItem =
                                                                            newValue;
                                                                      });
                                                                      //  Navigator.pop(context);
                                                                    },
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 10,
                                                                ),
                                                                Container(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  margin:
                                                                      EdgeInsets
                                                                          .all(
                                                                              5),
                                                                  height: 30,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          190,
                                                                          17,
                                                                          41,
                                                                          55),
                                                                  width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  child: Text(
                                                                    "Seçili Kripto Kuru",
                                                                    style: GoogleFonts.arima(
                                                                        fontSize:
                                                                            20,
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 10,
                                                                ),
                                                                Container(
                                                                    height: 30,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    margin: EdgeInsets.only(
                                                                        bottom:
                                                                            4),
                                                                    width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width,
                                                                    child: Row(
                                                                      children: [
                                                                        Container(
                                                                            height:
                                                                                30,
                                                                            color: Color.fromARGB(
                                                                                156,
                                                                                117,
                                                                                179,
                                                                                119),
                                                                            alignment:
                                                                                Alignment.center,
                                                                            margin: EdgeInsets.only(bottom: 4),
                                                                            width: MediaQuery.of(context).size.width / 2 - 10,
                                                                            child: Text(kriptoFiyatList[index].toString().toUpperCase())),
                                                                        Container(
                                                                            height:
                                                                                30,
                                                                            color: Color.fromARGB(
                                                                                255,
                                                                                111,
                                                                                189,
                                                                                113),
                                                                            alignment:
                                                                                Alignment.center,
                                                                            margin: EdgeInsets.only(bottom: 4),
                                                                            width: MediaQuery.of(context).size.width / 2 - 10,
                                                                            child: Text(kriptoBaslikList[index].toString().toUpperCase()))
                                                                      ],
                                                                    )),
                                                                Container(
                                                                  height: 75,
                                                                  child:
                                                                      TextFormField(
                                                                    maxLength:
                                                                        5,
                                                                    controller:
                                                                        txtManyCurrenciesController,
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .number,
                                                                    decoration:
                                                                        InputDecoration(
                                                                      icon: Icon(
                                                                          Icons
                                                                              .money),
                                                                      labelText:
                                                                          'Miktar',
                                                                      labelStyle:
                                                                          TextStyle(
                                                                        color: Color(
                                                                            0xFF6200EE),
                                                                      ),
                                                                      helperText:
                                                                          stateText,
                                                                      enabledBorder:
                                                                          UnderlineInputBorder(
                                                                        borderSide:
                                                                            BorderSide(color: Color(0xFF6200EE)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child:
                                                                      ElevatedButton
                                                                          .icon(
                                                                    onPressed:
                                                                        () async {
                                                                      if (txtManyCurrenciesController
                                                                              .text !=
                                                                          "") {
                                                                        calcForeign =
                                                                            double.parse(txtManyCurrenciesController.text) *
                                                                                double.parse(kriptoFiyatList[index]);

                                                                        if (double.parse(userCreditBalanceList[userCreditCardNumberList.indexOf(_selectedItem!)]) >=
                                                                            calcForeign) {
                                                                          double
                                                                              newAmout =
                                                                              double.parse(userCreditBalanceList[userCreditCardNumberList.indexOf(_selectedItem!)]) - calcForeign;

///////////////////////
                                                                          String
                                                                              randomIDForeign =
                                                                              uuid.v1();
                                                                          CollectionReference
                                                                              userRefForeign =
                                                                              FirebaseFirestore.instance.collection('foreignTransaction');
                                                                          DocumentReference
                                                                              userRefdocForegn =
                                                                              userRefForeign.doc(randomIDForeign);

                                                                          await userRefdocForegn.set({
                                                                            'foreignID':
                                                                                randomIDForeign,
                                                                            'foreignName':
                                                                                kriptoBaslikList[index].toString().toUpperCase(),
                                                                            'foreignTotal':
                                                                                txtManyCurrenciesController.text,
                                                                            'userID':
                                                                                FirebaseAuth.instance.currentUser!.uid,
                                                                            'foreignTotalAmount':
                                                                                calcForeign
                                                                          }).whenComplete(() =>
                                                                              {
                                                                                kontrolVeGuncelleMethodForeign(_selectedItem!, newAmout.toString())
                                                                              });

//////////////////////////
                                                                        } else {
                                                                          Fluttertoast.showToast(
                                                                              msg: "Seçtiğiniz hesabınızda en fazla şu tutarda bakiye bulunmalıdır: " + calcForeign.toString() + " TL!",
                                                                              toastLength: Toast.LENGTH_SHORT,
                                                                              gravity: ToastGravity.BOTTOM,
                                                                              timeInSecForIosWeb: 1,
                                                                              backgroundColor: Color.fromARGB(255, 14, 20, 35),
                                                                              textColor: Colors.white,
                                                                              fontSize: 16.0);
                                                                        }

                                                                        setStatefr(
                                                                            () {
                                                                          stateText =
                                                                              "Toplam tutar: " + calcForeign.toString();
                                                                        });
                                                                      } else {
                                                                        Fluttertoast.showToast(
                                                                            msg:
                                                                                "Lütfen boşluk bırakmayınız!",
                                                                            toastLength: Toast
                                                                                .LENGTH_SHORT,
                                                                            gravity: ToastGravity
                                                                                .BOTTOM,
                                                                            timeInSecForIosWeb:
                                                                                1,
                                                                            backgroundColor: Color.fromARGB(
                                                                                255,
                                                                                14,
                                                                                20,
                                                                                35),
                                                                            textColor:
                                                                                Colors.white,
                                                                            fontSize: 16.0);
                                                                      }
                                                                    },
                                                                    icon: Icon(
                                                                        Icons
                                                                            .shopping_bag_sharp,
                                                                        size:
                                                                            18),
                                                                    label: Text(
                                                                        "Satın Al"),
                                                                  ),
                                                                )
                                                              ],
                                                            );
                                                          })));
                                            },
                                            backgroundColor: Colors
                                                .blue, // Buton arkaplan rengi
                                            child: const Text(
                                              "Al",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  grafikEkrani(
                                                symbol:
                                                    symbol, // Detay sayfasına sembolü gönderiyoruz
                                              ),
                                            ),
                                          );
                                        },
                                        child: Icon(Icons.graphic_eq),
                                      )
                                    ],
                                  )),
                              onTap: () {
                                /* Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CryptoDetailScreen(cryptoId: id),
                              ),
                            );*/
                              },
                            ));
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
