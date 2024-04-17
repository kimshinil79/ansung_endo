import 'package:ansung_endo/tabs/washing_room.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  String washer = "";
  String emailAddress = "";
  final TextEditingController _washerController = TextEditingController();
  final TextEditingController _emailAdressController = TextEditingController();

  final Map<String, String> GSFmachine = {'073':'KG391K073', '180':'5G391K180', '153':'5G391K153','256':'7G391K256','257':'7G391k257',
    '259':'7G391K259','407':'2G348K407', '405':'2G348K405','390':'2G348K390', '333':'2G348K333', '694':'5G348K694'};
  final Map<String, String> CSFmachine = {'039':'7C692K039', '166':'6C692K166', '098':'5C692K098', '219':'1C664K219', '379':'1C665K379', '515':'1C666K515',};


  @override
  void initState() {
    super.initState();
    _loadEtc();
  }

  _loadEtc() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      washer = (prefs.getString('washer')?? "");
      emailAddress = (prefs.getString('emailAddress')?? "");
    });
  }

  _updateWasher(String textData, TextEditingController controller) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(textData, controller.text);
    setState(() {
      if (textData == 'washer') {
        washer = controller.text;
      }
      if (textData == 'emailAddress') {
        emailAddress = controller.text;
      }
    });
  }

  _showEditDialog(String textData, String title, TextEditingController controller) async {
    if (textData == 'washer') {
      controller.text = washer;
    }
    if (textData == 'emailAddress') {
      controller.text = emailAddress;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: title.split(" ")[0]),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 대화 상자 닫기
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                _updateWasher(textData, controller); // 값 저장 후 업데이트
                Navigator.of(context).pop(); // 대화 상자 닫기
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              ElevatedButton(
                  onPressed: () => _showEditDialog('washer', '소독실무자 수정', _washerController),
                  child: Text(
                      '소독실무자: $washer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                  ),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // 모서리를 둥글지 않게 설정
                      ),
                    ),
                  ),
              ),
              ElevatedButton(
                  onPressed:() =>  _showEditDialog('emailAddress', "Email 수정", _emailAdressController),
                  child: Text(
                    'Email: $emailAddress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // 모서리를 둥글지 않게 설정
                      ),
                    ),
                  ),
              ),
            // ElevatedButton(
            //     onPressed: () async{
            //       FirebaseFirestore firestore = FirebaseFirestore.instance;
            //       DocumentReference docRef = firestore.collection('scopes').doc('CSF');
            //       try {
            //         // 'GSF' 문서의 'GSF' 필드를 GSFmachine Map으로 업데이트합니다.
            //         await docRef.update({
            //           'CSF': CSFmachine, // 전체 Map을 'GSF' 필드에 저장
            //         });
            //
            //         print("GSF Machine data updated successfully.");
            //       } catch(e) {
            //         print (e);
            //       }
            //     },
            //     child: Text('내시경 종류 추가/삭제'),
            // )
          ],
        ),
      )
    );
  }
}