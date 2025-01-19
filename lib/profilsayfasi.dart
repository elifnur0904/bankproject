import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class profilEkrani extends StatefulWidget {
  @override
  profilEkraniState createState() => profilEkraniState();
}

class profilEkraniState extends State<profilEkrani> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("USERID: " + FirebaseAuth.instance.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Sayfası'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore
            .collection('userValues')
            .doc(FirebaseAuth.instance.currentUser!.uid.toString())
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Kullanıcı bilgisi bulunamadı'));
          }

          var userData = snapshot.data!;
          return ListView(
            children: [
              profilDuzenleMethod(
                'Email',
                userData['userMail'],
                (newValue) => guncelleMethod('userMail', newValue),
              ),
              profilDuzenleMethod(
                'Ad Soyad',
                userData['userName'],
                (newValue) => guncelleMethod('userName', newValue),
              ),
              profilDuzenleMethod(
                'Telefon',
                userData['userPhone'],
                (newValue) => guncelleMethod('userPhone', newValue),
              ),
              profilDuzenleMethod(
                'T.C. NO',
                userData['userIDNumber'],
                (newValue) => guncelleMethod('userIDNumber', newValue),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget profilDuzenleMethod(
      String label, String value, Function(String) onUpdate) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: IconButton(
        icon: Icon(Icons.edit),
        onPressed: () async {
          String? newValue = await _showEditDialog(label, value);
          if (newValue != null && newValue.isNotEmpty) {
            onUpdate(newValue);
          }
        },
      ),
    );
  }

  Future<String?> _showEditDialog(String label, String currentValue) async {
    TextEditingController controller =
        TextEditingController(text: currentValue);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Düzenle $label'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter new $label'),
          ),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Kaydet'),
              onPressed: () => Navigator.pop(context, controller.text),
            ),
          ],
        );
      },
    );
  }

  void guncelleMethod(String fieldName, String newValue) {
    _firestore
        .collection('userValues')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      fieldName: newValue,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Başarıyla güncellendi')),
      );
      setState(() {});
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $error')),
      );
    });
  }
}
