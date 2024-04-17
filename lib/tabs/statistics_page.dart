//import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {

  String washer = "";
  DateTime selectedDate = DateTime.now();
  late String emailAddress = "";
  Map<String, String> scopyFullName = {'039':'7C692K039', '073':'KG391K073', '098':'5C692K098',  '153':'5G391K153', '166':'6C692K166',
    '180':'5G391K180', '219':'1C664K219', '256':'7G391K257', '257':'7G391k257', '259':'7G391K259', '333':'2G348K333', '379':'1C665K379', '390':'2G348K390',
    '405':'2G348K405', '407':'2G348K407', '515':'1C666K515', '694':'5G348K694'};
  Map<String, dynamic> patientAndExamInformation = {"id":"", "환자번호":"", '이름':"", '성별':"", '나이':"", "Room":"", "생일":"", "의사":"", "날짜":"", "시간":"",
    "위검진_외래" : "검진", "위수면_일반":"수면", "위조직":"0", "CLO":false, "위절제술":"0", "위응급":false, "PEG":false, "위내시경기계":<String>[], "위세척기계":<String>[], "위내시경세척시간":<String>[],
    "대장검진_외래":"외래", "대장수면_일반":"수면", "대장조직":"0", "대장절제술":"0", "대장응급":false, "대장내시경기계":<String>[], "대장세척기계":<String>[], "대장내시경세척시간":<String>[],
    "sig기계":"", "sig조직":"0","sig절제술":"0","sig응급":false,
  };
  Map<String, String>washingMachinesFullName = {'1호기':"G0423102/1", '2호기':'G0423103/1', '3호기':'G0423104/1','4호기':'G0417099/1','5호기':'I0210032/1'};
  String selectedDoctor = "김신일"; // 기본값 설정
  List<String> doctors = ['이병수', '권순범', '김신일', '한융희', '이기섭'];
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // 초기 선택된 날짜
      firstDate: DateTime(2023), // 선택 가능한 가장 이른 날짜
      lastDate: DateTime(2100), // 선택 가능한 가장 늦은 날짜
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked; // 선택된 날짜로 상태 업데이트
      });
    }
  }

  Future<void> showEmailDialog(BuildContext context, String title) async {
    TextEditingController emailController = TextEditingController(text: emailAddress);
    TextEditingController dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(selectedDate));

    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('메일 보내시겠습니까?'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('보낼 메일 주소를 입력하세요.'),
                  TextField(
                    controller: emailController,
                  ),
                  SizedBox(height: 8), // 간격 추가
                  Text('날짜를 선택하세요.'),
                  TextField(
                    controller: dateController,
                    decoration: InputDecoration(suffixIcon: Icon(Icons.calendar_today)),
                    readOnly: true, // 편집을 방지합니다.
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                          dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                  )
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                  onPressed: () {
                    setState(() {
                      emailAddress = emailController.text;
                    });
                    _sendEmailForDailyReport(emailAddress, title, selectedDate);
                    Navigator.of(context).pop();
                  },
                  child: Text('보내기')
              )
            ],
          );
        }
    );
  }


  List<dynamic> sortRecordsByDateTime(List<dynamic> records) {

    records.sort((a, b) {
      print ('a:$a');
      print ('b:$b');

      DateTime dateTimeA = a['시간'] == String? DateTime.parse(a['시간']) : DateTime.parse(a['시간'][records.indexOf(a)]);
      DateTime dateTimeB = b['시간'] == String? DateTime.parse(b['시간']) : DateTime.parse(b['시간'][records.indexOf(b)]);
      // DateTime 객체를 비교하여 정렬합니다.
      return dateTimeA.compareTo(dateTimeB);
    });
    return records;
  }

  Future<void> makingExcelFileEndoscopyWahserDailyReport(String date) async {
    final workbook = xls.Workbook();
    final worksheet = workbook.worksheets[0];
    worksheet.name = '내시경세척기록';

    final xls.Style globalstyle = workbook.styles.add('style');
    globalstyle.hAlign = xls.HAlignType.center;
    globalstyle.vAlign = xls.VAlignType.center;

    worksheet.getRangeByName('A1').setText('등록번호');
    worksheet.getRangeByName('B1').setText('이름');
    worksheet.getRangeByName('C1').setText('담당의');
    worksheet.getRangeByName('D1').setText('내시경고유번호');
    worksheet.getRangeByName('E1').setText('시간');
    worksheet.getRangeByName('F1').setText('세척기번호');
    worksheet.getRangeByName('G1').setText('소독실무자');

    Map<String, String?>data = {"등록번호":"", "이름":"", "담당의":"", "내시경고유번호":"", "시간":"", "세척기번호":"", "소독실무자":""};
    List dataSet = [];

    final firestore = FirebaseFirestore.instance;

    QuerySnapshot querySnapshot = await firestore
        .collection('patients')
        .where('날짜', isEqualTo: date.substring(0, 10))
        .get();

    for (var doc in querySnapshot.docs) {
      if ((doc['위내시경기계'] is String) && (doc['대장내시경기계'] is String)){
        if ((doc['위내시경기계'] !="" && doc['대장내시경기계']=="")) {
          data = {"등록번호":"", "이름":"", "담당의":"", "내시경고유번호":"", "시간":"", "세척기번호":"", "소독실무자":""};
          data["등록번호"] = doc['환자번호'];
          data['이름'] = doc['이름'];
          data['담당의'] = doc['의사'];
          data['내시경고유번호'] = scopyFullName[doc['위내시경기계']]!;
          data['시간'] = doc['위내시경세척시간'];
          data['세척기번호'] = washingMachinesFullName[doc['위세척기계']];
          data['소독실무자'] = washer;
          dataSet.add(data);
        }
        if ((doc['위내시경기계'] =="" && doc['대장내시경기계'] !="")) {
          data = {"등록번호":"", "이름":"", "담당의":"", "내시경고유번호":"", "시간":"", "세척기번호":"", "소독실무자":""};
          data["등록번호"] = doc['환자번호'];
          data['이름'] = doc['이름'];
          data['담당의'] = doc['의사'];
          data['내시경고유번호'] = scopyFullName[doc['대장내시경기계']];
          data['시간'] = doc['대장내시경세척시간'];
          data['세척기번호'] = washingMachinesFullName[doc['대장세척기계']];
          data['소독실무자'] = washer;
          dataSet.add(data);
        }
        if ((doc['위내시경기계'] !="" && doc['대장내시경기계'] !="")) {
          if (scopyFullName[doc['위내시경기계']] != null) {
            data = {"등록번호":"", "이름":"", "담당의":"", "내시경고유번호":"", "시간":"", "세척기번호":"", "소독실무자":""};
            data["등록번호"] = doc['환자번호'];
            data['이름'] = doc['이름'];
            data['담당의'] = doc['의사'];
            data['소독실무자'] = washer;
            data['내시경고유번호'] = scopyFullName[doc['위내시경기계']];
            data['시간'] = doc['위내시경세척시간'];
            data['세척기번호'] = washingMachinesFullName[doc['위세척기계']];
            dataSet.add(data);
          }
          if(scopyFullName[doc['대장내시경기계']] != null) {
            data = {"등록번호":"", "이름":"", "담당의":"", "내시경고유번호":"", "시간":"", "세척기번호":"", "소독실무자":""};
            data["등록번호"] = doc['환자번호'];
            data['이름'] = doc['이름'];
            data['담당의'] = doc['의사'];
            data['소독실무자'] = washer;
            data['내시경고유번호'] = scopyFullName[doc['대장내시경기계']];
            data['시간'] = doc['대장내시경세척시간'];
            data['세척기번호'] = washingMachinesFullName[doc['대장세척기계']];
            dataSet.add(data);
          }
        }
      }

      if ((doc['위내시경기계'] is List) && !doc['위내시경기계'].isEmpty) {
        if (doc['위내시경기계'][0] !="" && doc['위내시경기계'][0] !="없음") {
          for (var scope in doc['위내시경기계']) {
            data = {
              "등록번호": "",
              "이름": "",
              "담당의": "",
              "내시경고유번호": "",
              "시간": "",
              "세척기번호": "",
              "소독실무자": ""
            };
            data["등록번호"] = doc['환자번호'];
            data['이름'] = doc['이름'];
            data['담당의'] = doc['의사'];
            int index = doc['위내시경기계'].indexOf(scope);
            data['내시경고유번호'] = scopyFullName[scope];
            data['시간'] = doc['위내시경세척시간'][index];
            data['세척기번호'] = washingMachinesFullName[doc['위세척기계'][index]];
            data['소독실무자'] = washer;
            dataSet.add(data);
          }
        }
        try {
          if ((doc['대장내시경기계'] is List) && !doc['대장내시경기계'].isEmpty) {
            if (doc['대장내시경기계'][0] != "" && doc['대장내시경기계'][0] != "없음") {
              for (var scope in doc['대장내시경기계']) {
                data = {
                  "등록번호": "",
                  "이름": "",
                  "담당의": "",
                  "내시경고유번호": "",
                  "시간": "",
                  "세척기번호": "",
                  "소독실무자": ""
                };
                data["등록번호"] = doc['환자번호'];
                data['이름'] = doc['이름'];
                data['담당의'] = doc['의사'];
                int index = doc['대장내시경기계'].indexOf(scope);
                data['내시경고유번호'] = scopyFullName[scope];
                data['시간'] = doc['대장내시경세척시간'][index];
                data['세척기번호'] = washingMachinesFullName[doc['대장세척기계'][index]];
                data['소독실무자'] = washer;
                dataSet.add(data);
              }
            }
          }
        } catch(e) {
          print ('여기는 대장:$e');
        }

      }
    }

    if (dataSet.isNotEmpty) {
      //dataSet = sortRecordsByDateTime(dataSet);
      int row = 2;
      for (Map<String, String?> data in dataSet) {
        String colName = "A";        
        for(var key in data.keys.toList()) {
          String cellAdress = colName + row.toString();
          if (key == '시간') {
            worksheet.getRangeByName(cellAdress).setText(data[key]?.split(" ")[1]);
          } else {
            worksheet.getRangeByName(cellAdress).setText(data[key]);
          }
          worksheet.getRangeByName(cellAdress).cellStyle = globalstyle;
          colName = getNextColumnName(colName);
        }
        row++;
      }
    }
    for (int i = 1; i <= data.length; i++) {
      worksheet.autoFitColumn(i);
    }

    Directory? appDirectory = await getApplicationDocumentsDirectory();
    final fileName = appDirectory.path + '/수검자별내시경세척및소독일지('+date+').xlsx';
    final excelData = workbook.saveAsStream();
    workbook.dispose();

    final file = await File(fileName).create(recursive: true);

    await file.writeAsBytes(excelData, flush: true);

  }

  Future<void> makingExcelFileforRawData(String date) async {

    final workbook = xls.Workbook();
    final worksheet = workbook.worksheets[0];
    worksheet.name = '기본데이터';

    final xls.Style globalstyle = workbook.styles.add('style');
    globalstyle.hAlign = xls.HAlignType.center;
    globalstyle.vAlign = xls.VAlignType.center;

    worksheet.getRangeByName('B1').setText('Room');
    worksheet.getRangeByName('C1').setText('환자번호');
    worksheet.getRangeByName('D1').setText('이름');
    worksheet.getRangeByName('E1').setText('성별');
    worksheet.getRangeByName('F1').setText('나이');
    worksheet.getRangeByName('G1').setText('생일');
    worksheet.getRangeByName('H1').setText('의사');
    worksheet.getRangeByName('I1').setText('날짜');
    worksheet.getRangeByName('J1').setText('시간');
    worksheet.getRangeByName('K1').setText('위검진_외래');
    worksheet.getRangeByName('L1').setText('위수면_일반');
    worksheet.getRangeByName('M1').setText('위조직');
    worksheet.getRangeByName('N1').setText('CLO');
    worksheet.getRangeByName('O1').setText('위절제술');
    worksheet.getRangeByName('P1').setText('위응급');
    worksheet.getRangeByName('Q1').setText('PEG');
    worksheet.getRangeByName('R1').setText('위내시경기계');
    worksheet.getRangeByName('S1').setText('위세척기계');
    worksheet.getRangeByName('T1').setText('위내시경세척시간');
    worksheet.getRangeByName('U1').setText('대장검진_외래');
    worksheet.getRangeByName('V1').setText('대장수면_일반');
    worksheet.getRangeByName('W1').setText('대장조직');
    worksheet.getRangeByName('X1').setText('대장절제술');
    worksheet.getRangeByName('Y1').setText('대장응급');
    worksheet.getRangeByName('Z1').setText('대장내시경기계');
    worksheet.getRangeByName('AA1').setText('대장세척기계');
    worksheet.getRangeByName('AB1').setText('대장내시경세척시간');
    worksheet.getRangeByName('AC1').setText('sig기계');
    worksheet.getRangeByName('AD1').setText('sig조직');
    worksheet.getRangeByName('AE1').setText('sig절제술');
    worksheet.getRangeByName('AF1').setText('sig응급');
    worksheet.getRangeByName('AG1').setText('sig세척기계');
    worksheet.getRangeByName('AH1').setText('sig세척시간');
    worksheet.getRangeByName('B1:AF1').cellStyle = globalstyle;
    worksheet.getRangeByName('A1').setText('id');

    final firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore.collection('patients').where(
        '날짜', isEqualTo: date.substring(0, 10)).get();
    if (querySnapshot.docs.isNotEmpty) {
      int row = 2;
      for (var doc in querySnapshot.docs) {
        String colName = "A";
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        for (int j = 0; j < data.length; j++) {
          String cellAdress = colName + row.toString();
          String categoryName = worksheet
              .getRangeByName(colName + '1'.toString())
              .text!;
          if (scopyFullName.containsKey(data[categoryName])) {
            String fullName = scopyFullName[data[categoryName]]!;
            worksheet.getRangeByName(cellAdress).setText(fullName);
          } else {
            if (categoryName == "위조직" || categoryName == "위절제술" ||
                categoryName == "대장조직" || categoryName == "대장절제술" ||
                categoryName == "sig조직" || categoryName == "sig절제술") {
              try {
                worksheet.getRangeByName(cellAdress).setNumber(
                    double.parse(data[categoryName]));
              } catch (e) {
                print('excel cell에 데이터 삽입 에러(위조직 ~ sig 절제술($e)');
              }
            } else {
              if (data[categoryName] is List){
                String finalValue = "";
                for (var value in data[categoryName]) {
                  finalValue = finalValue + value + ',';
                  finalValue.replaceRange(finalValue.length-1, finalValue.length , "");
                }
                if (finalValue.endsWith(',')) {
                  finalValue = finalValue.substring(0, finalValue.length - 1);
                }
                worksheet.getRangeByName(cellAdress).setValue(finalValue);
              } else {
                worksheet.getRangeByName(cellAdress).setValue(data[categoryName]);
              }

            }
          }
          worksheet.getRangeByName(cellAdress).cellStyle = globalstyle;
          colName = getNextColumnName(colName);
        }
        row++;
      }
    }

    for (int i = 1; i <= patientAndExamInformation.length; i++) {
      worksheet.autoFitColumn(i);
    }
    Directory? appDirectory = await getApplicationDocumentsDirectory();
    final fileName = appDirectory.path + '/내시경검사와세척기본데이터('+date+').xlsx';
    final excelData = workbook.saveAsStream();
    workbook.dispose();

    final file = await File(fileName).create(recursive: true);

    await file.writeAsBytes(excelData, flush: true);
  }

  String getNextColumnName(String currentName) {
    // 문자열을 역순으로 배열로 변환합니다. (처리 용이성을 위해)
    List<String> chars = currentName.split('').reversed.toList();
    bool carry = true; // 증가시킬 때 다음 자리수로 넘어가야하는지 여부

    // 각 문자에 대해 반복
    for (int i = 0; i < chars.length; i++) {
      // 현재 문자의 ASCII 코드
      int code = chars[i].codeUnitAt(0);

      // carry가 true이면 현재 문자를 증가시킵니다.
      if (carry) {
        if (code == 'Z'.codeUnitAt(0)) {
          chars[i] = 'A'; // 'Z' 다음은 'A'이며, 다음 자리수로 넘어갑니다.
        } else {
          chars[i] = String.fromCharCode(code + 1); // 현재 문자를 증가
          carry = false; // 더 이상의 증가 없이 종료
        }
      }
    }

    // 모든 자리가 'Z'에서 증가된 경우 ('ZZ' -> 'AAA') 새로운 'A'를 추가합니다.
    if (carry) {
      chars.add('A');
    }

    // 배열을 역순으로 되돌리고 문자열로 합칩니다.
    return chars.reversed.join('');
  }

  Future<void> _sendEmailForDailyReport(String emailAddress, String title, DateTime date) async {
    print ('email:$emailAddress');
    Directory? appDirectory = await getApplicationDocumentsDirectory();
    final String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
    if (title == "내시경검사와세척기본데이터") {
      await makingExcelFileforRawData(formattedDate);
    }
    if (title == "수검자별내시경세척및소독일지") {
      await makingExcelFileEndoscopyWahserDailyReport(formattedDate);
    }


    final email = Email(
      body: '오늘 하루도 수고했어요.  늘 감사합니다^^',
      subject: '$title($formattedDate)',
      recipients: [emailAddress, 'alienpro@naver.com'],
      attachmentPaths: ['${appDirectory.path}/$title($formattedDate).xlsx'],
    );
    String platformResponse;

    try {
      await FlutterEmailSender.send(email);
      platformResponse = "메일을 성공적으로 전송했습니다.";
    } catch (error) {
      platformResponse = error.toString();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('메일 전송 결과'),
          content: Text(platformResponse),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
          ],
        );
      },
    );

    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text(platformResponse),
    // ));
  }

  Future<void> _selectDateForDoc(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  void fetchDataByDoctorAndDateRange(String doctor, DateTime start, DateTime end) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String startString = DateFormat('yyyy-MM-dd').format(start);
    String endString = DateFormat('yyyy-MM-dd').format(end);

    var querySnapshot = await firestore.collection('patients')
        .where('의사', isEqualTo: doctor)
        .where('날짜', isGreaterThanOrEqualTo: startString)
        .where('날짜', isLessThanOrEqualTo: endString)
        .get();

    int stomachCheckup = 0, stomachOutpatient = 0, colonOutpatient = 0, colonCheckup = 0;

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['위검진_외래'] == "검진") stomachCheckup++;
      if (data['위검진_외래'] == "외래") stomachOutpatient++;
      if (data['대장검진_외래'] == "검진") colonCheckup++;
      if (data['대장검진_외래'] == "외래") colonOutpatient++;
    }

    int totalScopes = stomachCheckup + stomachOutpatient + colonOutpatient + colonCheckup;
    showResultsDialog(doctor, totalScopes, stomachCheckup, stomachOutpatient, colonCheckup, colonOutpatient);
  }

  void showResultsDialog(String doctor, int total, int stomachCheckup, int stomachOutpatient, int colonCheckup, int colonOutpatient) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
              child: Text(
                  "조회 결과($doctor)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 2.0,
                        color: Colors.blueGrey.withOpacity(0.5),
                      ),
                    ],
                  ),
              ),
          ),
          content: SingleChildScrollView(
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('항목')),
                DataColumn(label: Text('수량')),
              ],
              rows: <DataRow>[
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('위내시경 검진')),
                    DataCell(Text('$stomachCheckup')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('위내시경 외래')),
                    DataCell(Text('$stomachOutpatient')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('대장내시경 검진')),
                    DataCell(Text('$colonCheckup')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('대장내시경 외래')),
                    DataCell(Text('$colonOutpatient')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(
                        Text(
                            '총 내시경 개수',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                        )),
                    DataCell(
                        Text(
                            '$total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                        )),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("닫기"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }







  @override
  Widget build(BuildContext context) {

    String formattedSelectedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    return Scaffold(
      body: SingleChildScrollView(
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                SizedBox(width: 10,),
                Expanded(
                  child: ElevatedButton(
                      onPressed: () => showEmailDialog(context, '내시경검사와세척기본데이터'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Row의 크기를 자식들의 크기에 맞게 조절
                        children: <Widget>[
                          Text('기본자료'), // 텍스트 위젯
                          SizedBox(width: 8), // 텍스트와 아이콘 사이의 공간
                          Icon(Icons.email), // 메일 아이콘
                        ],
                      ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(const Color(0xFFb3cde0)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // 모서리를 둥글지 않게 설정
                        ),
                      ),
                      fixedSize: MaterialStateProperty.all(Size.fromHeight(50)),
                    ),
                  ),
                ),
                SizedBox(width: 10,),
                Expanded(
                    child: ElevatedButton(
                      onPressed: ()=> showEmailDialog(context, '수검자별내시경세척및소독일지'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Row의 크기를 자식들의 크기에 맞게 조절
                        children: <Widget>[
                          Text('세척&소독일지'), // 텍스트 위젯
                          SizedBox(width: 8), // 텍스트와 아이콘 사이의 공간
                          Icon(Icons.email), // 메일 아이콘
                        ],
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(const Color(0xFFb3cde0)),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15), // 모서리를 둥글지 않게 설정
                          ),
                        ),
                        fixedSize: MaterialStateProperty.all(Size.fromHeight(50)),
                      ),
                    ),
                ),
                SizedBox(width: 10,),
              ],
            ),
            SizedBox(height: 10,),
            Divider(color: Colors.indigo,),
            SizedBox(height: 10,),
            Center(
              child: Text(
                  '과장님별 통계',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blueGrey,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 2.0,
                        color: Colors.blueGrey.withOpacity(0.5),
                      ),
                    ],

                  ),
              ),
            ),
            Center(
              child: Row(
                children: [
                  SizedBox(width: 10,),
                  TextButton(
                    onPressed: () => _selectDateForDoc(context, true), // true for start date
                    child: Text(
                        '시작: ${DateFormat('yyyy-MM-dd').format(startDate)}',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                    ),
                  ),
                  SizedBox(width: 10,),
                  DropdownButton<String>(
                    value: selectedDoctor,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDoctor = newValue!;
                      });
                    },
                    items: doctors.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 20,
                            ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(width: 10,),
                  TextButton(
                    onPressed: () => _selectDateForDoc(context, false), // false for end date
                    child: Text(
                        '종료: ${DateFormat('yyyy-MM-dd').format(endDate)}',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                    ),

                  )
                ],
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  fetchDataByDoctorAndDateRange(selectedDoctor, startDate, endDate);
                },
                child: Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(const Color(0xFFb3cde0)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // 모서리를 둥글지 않게 설정
                    ),
                  ),
                  fixedSize: MaterialStateProperty.all(Size.fromHeight(50)),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Divider(color: Colors.indigo,),
            // ElevatedButton(
            //     onPressed: () => makingExcelFileEndoscopyWahserDailyReport(DateFormat('yyyy-MM-dd').format(selectedDate)),
            //     child: Text('엑셀')
            // ),
            // ElevatedButton(
            //     onPressed: () async {
            //       final firestore = FirebaseFirestore.instance;
            //       final id = "ab074022-2f72-45cd-b14c-1dcbc284866a";
            //       QuerySnapshot querySnapshot = await firestore.collection('patients').get();
            //       for (var doc in querySnapshot.docs) {
            //         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            //         if (data['위내시경기계'] is String) {
            //           String tempData = data['위내시경기계'];
            //           data['위내시경기계'] = [];
            //           data['위내시경기계'].add(tempData);
            //         }
            //         if (data['위세척기계'] is String) {
            //           String tempData = data['위세척기계'];
            //           data['위세척기계'] = [];
            //           data['위세척기계'].add(tempData);
            //         }
            //         if (data['위내시경세척시간'] is String) {
            //           String tempData = data['위내시경세척시간'];
            //           data['위내시경세척시간'] = [];
            //           data['위내시경세척시간'].add(tempData);
            //         }
            //         if (data['대장내시경기계'] is String) {
            //           String tempData = data['대장내시경기계'];
            //           data['대장내시경기계'] = [];
            //           data['대장내시경기계'].add(tempData);
            //         }
            //         if (data['대장세척기계'] is String) {
            //           String tempData = data['대장세척기계'];
            //           data['대장세척기계'] = [];
            //           data['대장세척기계'].add(tempData);
            //         }
            //         if (data['대장내시경세척시간'] is String) {
            //           String tempData = data['대장내시경세척시간'];
            //           data['대장내시경세척시간'] = [];
            //           data['대장내시경세척시간'].add(tempData);
            //         }
            //         data['sig세척기계']= "";
            //         data['sig세척시간']="";
            //
            //         await firestore.collection('patients').doc(doc.id).update(data);
            //       }
            //
            //
            //     },
            //     child: Text('데이터변환')
            // )

          ],
        ),
      ),
    );
  }
}
