import 'dart:convert';
import 'dart:io';
import 'package:ansung_endo/tabs/washing_room.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String washer = "";
  String emailAddress = "";
  final TextEditingController _washerController = TextEditingController();
  final TextEditingController _emailAdressController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  final Map<String, String> GSFmachine = {'073': 'KG391K073', '180': '5G391K180', '153': '5G391K153', '256': '7G391K256', '257': '7G391k257',
    '259': '7G391K259', '407': '2G348K407', '405': '2G348K405', '390': '2G348K390', '333': '2G348K333', '694': '5G348K694'};
  final Map<String, String> CSFmachine = {'039': '7C692K039', '166': '6C692K166', '098': '5C692K098', '219': '1C664K219', '379': '1C665K379', '515': '1C666K515',};

  @override
  void initState() {
    super.initState();
    _loadEtc();
  }

  _loadEtc() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      washer = (prefs.getString('washer') ?? "");
      emailAddress = (prefs.getString('emailAddress') ?? "");
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

  _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isStart ? _startDate : _endDate))
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
  }

  _savePatientsData() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('날짜를 설정해주세요.')));
      return;
    }

    try {
      String startDateString = DateFormat('yyyy-MM-dd').format(_startDate!);
      String endDateString = DateFormat('yyyy-MM-dd').format(_endDate!);

      print('Start Date: $startDateString');
      print('End Date: $endDateString');

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('날짜', isGreaterThanOrEqualTo: startDateString)
          .where('날짜', isLessThanOrEqualTo: endDateString)
          .get();

      List<Map<String, dynamic>> patients = querySnapshot.docs.map((doc) {
        print('Document data: ${doc.data()}');
        return doc.data() as Map<String, dynamic>;
      }).toList();

      if (patients.isEmpty) {
        print('No patients found for the given date range.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No patients data found for the given date range.')));
        return;
      }

      String jsonPatients = jsonEncode(patients);

      Directory directory = await getApplicationDocumentsDirectory();
      File file = File('${directory.path}/patients.json');
      await file.writeAsString(jsonPatients);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Patients data saved as JSON.')));
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save patients data.')));
    }
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
              onPressed: () => _showEditDialog('emailAddress', "Email 수정", _emailAdressController),
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
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _selectDate(context, true),
                  child: Text(
                    _startDate == null ? '시작 날짜' : DateFormat('yyyy-MM-dd').format(_startDate!),
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
                  onPressed: () => _selectDate(context, false),
                  child: Text(
                    _endDate == null ? '마지막 날짜' : DateFormat('yyyy-MM-dd').format(_endDate!),
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
              ],
            ),
            ElevatedButton(
              onPressed: _savePatientsData,
              child: Text(
                '환자 데이터 저장',
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
          ],
        ),
      ),
    );
  }
}
