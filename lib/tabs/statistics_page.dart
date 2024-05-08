//import 'dart:html';

//import 'dart:html';

import 'package:ansung_endo/providers/patient_model_provider.dart';
import 'package:provider/provider.dart';
import 'package:ansung_endo/widgets/sort_detail.dart';
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

class ResultData {
  Map<String, int> totalDetailSummaries;
  List<PatientSummary> summaries;

  ResultData(this.totalDetailSummaries, this.summaries);
}


class PatientSummary {
  String name;
  String patientNumber;
  String doctor;
  String summary;
  Map<String, dynamic> fullPatientInformation;

  PatientSummary(this.name, this.patientNumber, this.doctor, this.summary, this.fullPatientInformation);
}

class StatisticsPage extends StatefulWidget {
  final TabController? tabController;

  StatisticsPage({this.tabController});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  String washer = "";
  DateTime selectedDate = DateTime.now();

  late String emailAddress = "";
  Map<String, String> scopyFullName = {'039':'7C692K039', '073':'KG391K073', '098':'5C692K098',  '153':'5G391K153', '166':'6C692K166',
    '180':'5G391K180', '219':'1C664K219', '256':'7G391K257', '257':'7G391k257', '259':'7G391K259', '333':'2G348K333', '379':'1C665K379', '390':'2G348K390',
    '405':'2G348K405', '407':'2G348K407', '515':'1C666K515', '694':'5G348K694'};
  Map<String, dynamic> patientAndExamInformation = {"id":"", "환자번호":"", '이름':"", '성별':"", '나이':"", "Room":"", "생일":"", "의사":"", "날짜":"", "시간":"",
    "위검진_외래" : "검진", "위수면_일반":"수면", "위조직":"0", "CLO":false, "위절제술":"0", "위응급":false, "PEG":false,
    "위내시경":{},
    "대장검진_외래":"외래", "대장수면_일반":"수면", "대장조직":"0", "대장절제술":"0", "대장응급":false,
    "대장내시경":{},
    "sig": {}, "sig조직":"0","sig절제술":"0","sig응급":false,
  };
  Map<String, String>washingMachinesFullName = {'1호기':"G0423102", '2호기':'G0423103', '3호기':'G0423104','4호기':'G0417099','5호기':'I0210032'};
  String selectedDoctor = "김신일"; // 기본값 설정
  List<String> doctors = ['이병수', '권순범', '김신일', '한융희', '이기섭'];
  DateTime now = DateTime.now();
  DateTime startDateForDocSummary = DateTime.now();
  DateTime endDateForDocSummary = DateTime.now();
  DateTime startDateForExamSummary = DateTime.now();
  DateTime endDateForExamSummary = DateTime.now();
  DateTime startDateForRoomSummary = DateTime.now();
  DateTime endDateForRoomSummary = DateTime.now();
  DateTime startDateForDetailQuery = DateTime.now();
  DateTime endDateForDetailQuery = DateTime.now();
  DateTime summaryDate = DateTime.now();
  bool? period = false;
  bool todayResult = false;
  bool eachDocSummary = false;
  bool examSummary = false;
  bool roomSummary = false;
  bool detailQuery = false;

  @override
  void initState() {
    super.initState();
    startDateForDocSummary = DateTime(now.year, now.month, 1);
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
            title: Text('메일 보내기'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('보낼 메일 주소를 입력하세요.'),
                  TextField(
                    controller: emailController,
                  ),
                  SizedBox(height: 8), // 간격 추가
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text('날짜를 선택하세요.'),
                      Checkbox(
                          //tristate: true,
                          value: period,
                          onChanged:(bool? newValue) {
                            setState(() {
                              period = newValue;
                            });
                          }
                      )
                    ],
                  ),

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
      //print ('${data['이름']} / ${data['이름'].runtimeType}  / ${data['위내시경'].runtimeType} / ${data['대장내시경'].runtimeType} / ${data['sig'].runtimeType}');
      if (doc['위내시경'].isNotEmpty) {
        for (var gsfScope in doc['위내시경'].keys.toList()) {
          data = {"등록번호":"", "이름":"", "담당의":"", "내시경고유번호":"", "시간":"", "세척기번호":"", "소독실무자":""};
          data["등록번호"] = doc['환자번호'];
          data['이름'] = doc['이름'];
          data['담당의'] = doc['의사'];
          data['내시경고유번호'] = scopyFullName[gsfScope];
          data['시간'] = doc['위내시경'][gsfScope]['세척시간']?? "";
          data['세척기번호'] = washingMachinesFullName[doc['위내시경'][gsfScope]['세척기계']] ?? "";
          data['소독실무자'] = washer;
          dataSet.add(data);
        }
      }
      if (doc['대장내시경'].isNotEmpty) {
        for (var csfScope in doc['대장내시경'].keys.toList()) {
          data = {"등록번호":"", "이름":"", "담당의":"", "내시경고유번호":"", "시간":"", "세척기번호":"", "소독실무자":""};
          data["등록번호"] = doc['환자번호'];
          data['이름'] = doc['이름'];
          data['담당의'] = doc['의사'];
          data['내시경고유번호'] = scopyFullName[csfScope];
          data['시간'] = doc['대장내시경'][csfScope]['세척시간']?? "";
          data['세척기번호'] = washingMachinesFullName[doc['대장내시경'][csfScope]['세척기계']]?? "";
          data['소독실무자'] = washer;
          dataSet.add(data);
        }
      }
      if (doc['sig'].isNotEmpty) {
        for (var sigScope in doc['sig'].keys.toList()) {
          data = {"등록번호":"", "이름":"", "담당의":"", "내시경고유번호":"", "시간":"", "세척기번호":"", "소독실무자":""};
          data["등록번호"] = doc['환자번호'];
          data['이름'] = doc['이름'];
          data['담당의'] = doc['의사'];
          data['내시경고유번호'] = scopyFullName[sigScope];
          data['시간'] = doc['sig'][sigScope]['세척시간']?? "";
          data['세척기번호'] = washingMachinesFullName[doc['sig'][sigScope]['세척기계']]?? "";
          data['소독실무자'] = washer;
          dataSet.add(data);
        }
      }
      if (doc['위내시경'].isEmpty && doc['대장내시경'].isEmpty && doc['sig'].isEmpty) {
        data = {"등록번호":"", "이름":"", "담당의":"", "내시경고유번호":"", "시간":"", "세척기번호":"", "소독실무자":""};
        data["등록번호"] = doc['환자번호'];
        data['이름'] = doc['이름'];
        data['담당의'] = doc['의사']?? "";
        data['내시경고유번호'] = "";
        data['시간'] = "";
        data['세척기번호'] = "";
        data['소독실무자'] = washer;
        dataSet.add(data);
      }
    }

    if (dataSet.isNotEmpty) {
      //dataSet = sortRecordsByDateTime(dataSet);
      int row = 2;
      for (Map<String, String?> data in dataSet) {
        String colName = "A";        
        for(var key in data.keys.toList()) {
          String cellAdress = colName + row.toString();
          if (key == '시간'&& data[key] != "") {
            print ('뭐야이거:${data}');
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
      initialDate: isStart ? startDateForDocSummary : endDateForDocSummary,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDateForDocSummary = picked;
        } else {
          endDateForDocSummary = picked;
        }
      });
    }
  }

  Future<void> _selectDateForExam(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDateForExamSummary : endDateForExamSummary,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDateForExamSummary = picked;
        } else {
          endDateForExamSummary = picked;
        }
      });
    }
  }

  Future<void> _selectDateForEachPurpose(BuildContext context, String title,  bool isStart) async {

    DateTime? startDate;
    DateTime? endDate;

    if (title == "Doc") {
      startDate = startDateForDocSummary;
      endDate = endDateForDocSummary;
    }
    if (title == "Exam") {
      startDate = startDateForExamSummary;
      endDate = endDateForExamSummary;
    }
    if (title == "Room") {
      startDate = startDateForRoomSummary;
      endDate = endDateForRoomSummary;
    }
    if (title =="detailQuery") {
      startDate = startDateForDetailQuery;
      endDate = endDateForDetailQuery;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      if (title == "Doc") {
        setState(() {
          if (isStart) {
            startDateForDocSummary = picked;
          } else {
            endDateForDocSummary = picked;
          }
        });
      }
      if (title == "Exam") {
        setState(() {
          if (isStart) {
            startDateForExamSummary = picked;
          } else {
            endDateForExamSummary = picked;
          }
        });
      }
      if (title == "Room") {
        setState(() {
          if (isStart) {
            startDateForRoomSummary = picked;
          } else {
            endDateForRoomSummary = picked;
          }
        });
      }
      if (title =="detailQuery") {
        setState(() {
          if (isStart) {
            startDateForDetailQuery = picked;
          } else {
            endDateForDetailQuery = picked;
          }
        });
      }
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

    int stomachCheckup = 0, stomachOutpatient = 0, colonOutpatient = 0, colonCheckup = 0, colonPolyp = 0;

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['위검진_외래'] == "검진") stomachCheckup++;
      if (data['위검진_외래'] == "외래") stomachOutpatient++;
      if (data['대장검진_외래'] == "검진") colonCheckup++;
      if (data['대장검진_외래'] == "외래") colonOutpatient++;
      if (data['대장절제술'] !='0') colonPolyp++;
    }

    int totalScopes = stomachCheckup + stomachOutpatient + colonOutpatient + colonCheckup;
    showResultsDialog(doctor, totalScopes, stomachCheckup, stomachOutpatient, colonCheckup, colonOutpatient, colonPolyp);
  }

  void showResultsDialog(String doctor, int total, int stomachCheckup, int stomachOutpatient, int colonCheckup, int colonOutpatient, int colonPolyp) {
    final totalColon = colonCheckup+colonOutpatient;
    int PDR = 0;
    if (totalColon != 0) {
      PDR = (colonPolyp/totalColon*100).toInt();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
              child: Text(
                  "조회 결과 ($doctor)",
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
                    DataCell(Text('용종 발견률')),
                    DataCell(Text('$PDR%')),
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

  Widget buildRoomSummaryWidget(String startDate, String endDate) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('patients')
          .where('날짜', isGreaterThanOrEqualTo: startDate)
          .where('날짜', isLessThanOrEqualTo : endDate)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text("데이터를 불러오는 데 실패했습니다.");
        }
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text("환자 기록이 없습니다.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),),
          );
        }

        Map<String, Map<String, Map<String, dynamic>>> summaryForEachDate= {};

        for(var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String date = data['날짜'];
          String room = data['Room'];
          if (summaryForEachDate[date] == null) {
            summaryForEachDate[date] = {'1':{'위내시경':[], '대장내시경':[]}, '2':{'위내시경':[], '대장내시경':[]},'3':{'위내시경':[], '대장내시경':[]}};
          }
          if (data['위내시경'].isNotEmpty) {
            summaryForEachDate[date]![room]?['위내시경'].add(data);
          }
          if (data['대장내시경'].isNotEmpty) {
            summaryForEachDate[date]![room]?['대장내시경'].add(data);
          } else if (data['sig'].isNotEmpty) {
            summaryForEachDate[date]![room]?['대장내시경'].add(data);
          }

        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: buildRoomSummaryTable(summaryForEachDate),
            ),
            // SizedBox(
            //   height: 300,
            //   child: ListView.builder(
            //     itemCount: result.summaries.length,
            //     itemBuilder: (context, index) {
            //       return ListTile(
            //         title: Text('${result.summaries[index].name}(${result.summaries[index].patientNumber}) - ${result.summaries[index].doctor}'),
            //         subtitle: Text(result.summaries[index].summary),
            //       );
            //     },
            //   ),
            // ),
          ],
        );
      },
    );
  }

  Widget buildRoomSummaryTable(Map<String, Map<String, Map<String, dynamic>>> summaryForEachDate) {
    Map<String, Map<String, int>> totalRecordForEachRoom = {'1':{'위내시경':0, '대장내시경':0}, '2':{'위내시경':0, '대장내시경':0}, '3':{'위내시경':0, '대장내시경':0}};
    List<TableRow> rows = [
      TableRow( // 헤더
        children: [
          Text('날짜', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('1번방(위/대장)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('2번방(위/대장)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('3번방(위/대장)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ];

    summaryForEachDate.forEach((date, rooms) {
      List<Widget> rowChildren = [Text(date.substring(5), textAlign: TextAlign.center)]; // 날짜 열

      rooms.forEach((roomNumber, scopes) {
        int gsfCount = 0;
        int csfCount = 0;
        if (scopes['위내시경'] != null && scopes['위내시경'] is List) {
          gsfCount = scopes['위내시경'].length;
        }
        if (scopes['대장내시경'] != null && scopes['대장내시경'] is List) {
          csfCount = scopes['대장내시경'].length;
        }
        String scopesInfo = '위:${scopes['위내시경'].length} / 대장:${scopes['대장내시경'].length}';
        if (totalRecordForEachRoom[roomNumber] != null) {
          totalRecordForEachRoom[roomNumber]!['위내시경'] = (totalRecordForEachRoom[roomNumber]!['위내시경'] ?? 0) + gsfCount;
        totalRecordForEachRoom[roomNumber]!['대장내시경'] = (totalRecordForEachRoom[roomNumber]!['대장내시경'] ?? 0) + csfCount;
        }

        rowChildren.add(Text(scopesInfo, textAlign: TextAlign.center));
      });

      rows.add(TableRow(children: rowChildren));
    });
    rows.add(
      TableRow(
        children: [
          Text('총합', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('위:${totalRecordForEachRoom['1']!['위내시경']} / 대장:${totalRecordForEachRoom['1']!['대장내시경']}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('위:${totalRecordForEachRoom['2']!['위내시경']} / 대장:${totalRecordForEachRoom['2']!['대장내시경']}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('위:${totalRecordForEachRoom['3']!['위내시경']} / 대장:${totalRecordForEachRoom['3']!['대장내시경']}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        ]
      )
    );

    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(50.0), // 첫 번째 열의 너비를 50.0으로 고정
        1: FlexColumnWidth(), // 남은 공간을 균등하게 나눔
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
      },
      border: TableBorder(
        top: BorderSide(width: 2.0),
        bottom: BorderSide(width: 2.0),
        left: BorderSide(width: 2.0),
        right: BorderSide(width: 2.0),
        horizontalInside: BorderSide(width: 1.0),
        verticalInside: BorderSide(width: 1.0),
      ),
      children: rows,
    );
  }




  Widget buildSummaryWidget(String startDate, String endDate) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('patients')
          .where('날짜', isGreaterThanOrEqualTo: startDate)
          .where('날짜', isLessThanOrEqualTo : endDate)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text("데이터를 불러오는 데 실패했습니다.");
        }
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text("환자 기록이 없습니다.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),),
          );
        }

        final result = processDocuments(snapshot.data!.docs);

        return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Table(
                      border: TableBorder(
                        top: BorderSide(width: 2.0), // 상단 테두리 두껍게
                        bottom: BorderSide(width: 2.0), // 하단 테두리 두껍게
                        left: BorderSide(width: 2.0), // 좌측 테두리 두껍게
                        right: BorderSide(width: 2.0), // 우측 테두리 두껍게
                        horizontalInside: BorderSide(width: 1.0), // 행 사이의 테두리
                        verticalInside: BorderSide(width: 1.0), // 열 사이의 테두리
                      ),
                      // columnWidths: const <int, TableColumnWidth>{
                      //   0: FixedColumnWidth(100.0), // 고정된 열 너비
                      //   1: FixedColumnWidth(60.0),
                      //   2: FixedColumnWidth(60.0),
                      // },
                      children: [
                        TableRow(
                          children: [
                            Text('', textAlign: TextAlign.center),
                            Text('검진', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
                            Text('외래', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
                            Text('총합수', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
                          ],
                        ),
                        TableRow(
                          children: [
                            Text('위내시경', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${result.totalDetailSummaries['gsf_gumjin']}', textAlign: TextAlign.center),
                            Text('${result.totalDetailSummaries['gsf_outpatient']}', textAlign: TextAlign.center),
                            Text(
                                '${result.totalDetailSummaries['gsf_gumjin']! + result.totalDetailSummaries['gsf_outpatient']!}',
                                textAlign: TextAlign.center
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Text('대장내시경', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
                            Text('${result.totalDetailSummaries['csf_gumjin']}', textAlign: TextAlign.center),
                            Text('${result.totalDetailSummaries['csf_outpatient']}', textAlign: TextAlign.center),
                            Text(
                                '${result.totalDetailSummaries['csf_gumjin']! + result.totalDetailSummaries['csf_outpatient']!}',
                                textAlign: TextAlign.center
                            ),
                          ],
                        ),
                        if (result.totalDetailSummaries['sig'] != 0)
                        TableRow(
                          children: [
                            Text('Sig', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
                            Text('', textAlign: TextAlign.center),
                            Text('${result.totalDetailSummaries['sig']}', textAlign: TextAlign.center),
                            Text('${result.totalDetailSummaries['sig']}', textAlign: TextAlign.center),
                          ],
                        ),
                        TableRow(
                          children: [
                            Text('총합수', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
                            Text(
                                '${result.totalDetailSummaries['gsf_gumjin']! + result.totalDetailSummaries['csf_gumjin']!}',
                                textAlign: TextAlign.center
                            ),
                            Text(
                                '${result.totalDetailSummaries['gsf_outpatient']! + result.totalDetailSummaries['csf_outpatient']!}',
                                textAlign: TextAlign.center
                            ),
                            Text(
                                '${result.totalDetailSummaries['gsf_outpatient']! + result.totalDetailSummaries['csf_outpatient']! +
                                    result.totalDetailSummaries['gsf_gumjin']! + result.totalDetailSummaries['csf_gumjin']!
                                }',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 5,),
                    Table(
                      border: TableBorder(
                        top: BorderSide(width: 2.0), // 상단 테두리 두껍게
                        bottom: BorderSide(width: 2.0), // 하단 테두리 두껍게
                        left: BorderSide(width: 2.0), // 좌측 테두리 두껍게
                        right: BorderSide(width: 2.0), // 우측 테두리 두껍게
                        horizontalInside: BorderSide(width: 1.0), // 행 사이의 테두리
                        verticalInside: BorderSide(width: 1.0), // 열 사이의 테두리
                      ),
                      children: [
                        TableRow(
                          children: [
                            Text(""),
                            Text('조직검사', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
                            Text('절제술', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
                            Text('CLO', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
                          ]
                        ),
                        TableRow(
                            children: [
                              Text("위내시경", style: TextStyle(fontWeight: FontWeight.bold),),
                              Text('${result.totalDetailSummaries['gsf_Bx']}', textAlign: TextAlign.center,),
                              Text('${result.totalDetailSummaries['gsf_polypectomy']}', textAlign: TextAlign.center,),
                              Text('${result.totalDetailSummaries['CLO']}', textAlign: TextAlign.center,),
                            ]
                        ),
                        TableRow(
                            children: [
                              Text("대장내시경",style: TextStyle(fontWeight: FontWeight.bold), ),
                              Text('${result.totalDetailSummaries['csf_Bx']}', textAlign: TextAlign.center,),
                              Text('${result.totalDetailSummaries['csf_polypectomy']}', textAlign: TextAlign.center,),
                              Text('', textAlign: TextAlign.center,),
                            ]
                        ),
                      ],
                    )
                  ],
                )
                ,
              ),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: result.summaries.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.all(4.0), // 각 타일 사이의 공간을 추가합니다.
                      decoration: BoxDecoration(
                        color: Colors.white, // 배경색 설정
                        border: Border.all(
                          color: Colors.blue, // 테두리 색상
                          width: 1.0, // 테두리 두께
                        ),
                        borderRadius: BorderRadius.circular(5.0), // 테두리의 둥근 모서리 설정
                        boxShadow: [ // 그림자 효과
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5), // 그림자 색상
                            spreadRadius: 1, // 그림자 범위
                            blurRadius: 3, // 그림자 흐림 효과
                            offset: Offset(0, 2), // x, y 축 그림자 오프셋
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text('${result.summaries[index].name}(${result.summaries[index].patientNumber}) - ${result.summaries[index].doctor}'),
                        subtitle: Text(result.summaries[index].summary),
                        onTap: () {
                          Provider.of<PatientModel>(context, listen: false).updatePatient(result.summaries[index].fullPatientInformation);
                          widget.tabController?.animateTo(0);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
      },
    );
  }



  ResultData processDocuments(List<QueryDocumentSnapshot> docs) {
    List<PatientSummary> summaries = [];
    Map<String, int> totalDetailSummaries = {"patient":0, "total_gumjin":0,  "total_outpatient":0, "total_sleep":0, "total_awake":0,
      "patient":0, "gsf_gumjin":0, "gsf_outpatient":0, "gsf_sleep":0, "gsf_awake":0, "csf_gumjin":0,
      "csf_outpatient":0, "csf_sleep":0, "csf_awake":0, "gsf_Bx":0, "gsf_polypectomy":0, "CLO":0, "csf_Bx":0, "csf_polypectomy":0,
      "sig":0, "sig_Bx":0, "sig_polypectomy":0,
    };

    for (var doc in docs) {
      var summaryAndDetailSummary = createSummaryFromDoc(doc);
      String summary = summaryAndDetailSummary[0];
      Map<String, int> detailSummary = summaryAndDetailSummary[1];
      Map<String, dynamic> fullInformationPatient = summaryAndDetailSummary[2];

      summaries.add(PatientSummary(doc['이름'], doc['환자번호'], doc['의사'], summary, fullInformationPatient));

      // Update totals
      detailSummary.forEach((key, value) {
        if (totalDetailSummaries.containsKey(key)) {
          totalDetailSummaries.update(key, (existingValue) => existingValue + value);
        }
      });
    }
    // totalDetailSummaries['total_gumjin'] = totalDetailSummaries['gsf_gumjin']! + totalDetailSummaries['csf_gumjin']!;
    // totalDetailSummaries['total_outpatient'] = totalDetailSummaries['gsf_outpatient']! + totalDetailSummaries['csf_outpatient']! + totalDetailSummaries['sig']!;
    // totalDetailSummaries['totalPatient'] =  totalDetailSummaries['total_gumjin']! + totalDetailSummaries['total_outpatient']!;

    return ResultData(totalDetailSummaries, summaries);

  }

  List createSummaryFromDoc(DocumentSnapshot doc) {
    String summary = "";
    Map<String, int> detailSummary = {"patient":0, "gsf_gumjin":0, "gsf_outpatient":0, "gsf_sleep":0, "gsf_awake":0, "csf_gumjin":0,
      "csf_outpatient":0, "csf_sleep":0, "csf_awake":0, "gsf_Bx":0, "gsf_polypectomy":0, "CLO":0, "csf_Bx":0, "csf_polypectomy":0,
      "sig":0, "sig_Bx":0, "sig_polypectomy":0,
    };
    Map<String, dynamic> patientData = doc.data() as Map<String, dynamic>;
    if (doc['이름'] !="기기세척") {
      detailSummary['patient'] =1;
    }
    if (doc['위내시경'].isNotEmpty) {
      summary = summary+'위('+doc['위검진_외래'] + " "+doc['위수면_일반']+", ";
      if (doc['위검진_외래'] == '검진') {
        detailSummary["gsf_gumjin"] =1;
      } else if (doc['위검진_외래'] == '외래') {
        detailSummary["gsf_outpatient"] =1;
      }
      if (doc['위수면_일반'] == '수면') {
        detailSummary["gsf_sleep"] =1;
      } else if (doc['위수면_일반'] == '일반') {
        detailSummary["gsf_awake"] =1;
      }
      for (var scope in doc['위내시경'].keys.toList()) {
        summary += scope+" ";
      }
      if(doc['위조직'] != "0") {
        summary += ' ,Bx:'+doc['위조직'];
        detailSummary["gsf_Bx"] = int.parse(doc['위조직']);
      }
      if(doc['위절제술'] != "0") {
        summary += ' ,용종절제술:'+doc['위절제술'];
        detailSummary["gsf_polypectomy"] = int.parse(doc['위절제술']);
      }
      if(doc['CLO']) {
        summary += ' ,CLO, ';
        detailSummary["CLO"] = 1;
      }
      summary+=')';
    }
    if (doc['대장내시경'].isNotEmpty) {
      if(doc['위내시경'].isNotEmpty) {
        summary += '//';
      }
      summary = summary+'대장('+doc['대장검진_외래'] + " "+doc['대장수면_일반']+", ";
      if (doc['대장검진_외래'] == "검진") {
        detailSummary["csf_gumjin"] =1;
      } else if (doc['대장검진_외래'] == "외래") {
        detailSummary["csf_outpatient"] =1;
      }
      if (doc['대장수면_일반'] == '수면') {
        detailSummary["csf_sleep"] =1;
      } else if (doc['대장수면_일반'] == '일반') {
        detailSummary["csf_awake"] =1;
      }
      for (var scope in doc['대장내시경'].keys.toList()) {
        summary += scope+" ";
      }
      if(doc['대장조직'] != "0") {
        summary += ' ,Bx:'+doc['대장조직'];
        detailSummary["csf_Bx"] = int.parse(doc['대장조직']);
      }
      if(doc['대장절제술'] != "0") {
        summary += ' ,용종절제술:'+doc['대장절제술'];
        detailSummary["csf_polypectomy"] = int.parse(doc['대장절제술']);
      }
      summary += ')';
    }
    if (doc['sig'].isNotEmpty) {
      if (doc['위내시경'].isNotEmpty) {
        summary += '//';
      } else if (doc['대장내시경'].isNotEmpty) {
        summary += '//';
      }
      detailSummary["sig"] = 1;
      summary += 'sig( ';
      for (var scope in doc['sig'].keys.toList()) {
        summary += scope+" ";
      }
      if(doc['sig조직'] != "0") {
        summary += 'Bx:'+doc['sig조직']+", ";
        detailSummary["sig_Bx"] = int.parse((doc['sig조직']));
      }
      if(doc['sig절제술'] != "0") {
        summary += '용종절제술:'+doc['sig절제술'] + ", ";
        detailSummary["sig_polypectomy"] = int.parse(doc['sig절제술']);
      }
      summary += ")";
    }

    return [summary, detailSummary, patientData];
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
                //SizedBox(width: 10,),
                // Expanded(
                //   child: ElevatedButton(
                //       onPressed: () => showEmailDialog(context, '내시경검사와세척기본데이터'),
                //       child: Row(
                //         mainAxisSize: MainAxisSize.min, // Row의 크기를 자식들의 크기에 맞게 조절
                //         children: <Widget>[
                //           Text('기본자료'), // 텍스트 위젯
                //           SizedBox(width: 8), // 텍스트와 아이콘 사이의 공간
                //           Icon(Icons.email), // 메일 아이콘
                //         ],
                //       ),
                //     style: ButtonStyle(
                //       backgroundColor: MaterialStateProperty.all(const Color(0xFFb3cde0)),
                //       shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                //         RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(15), // 모서리를 둥글지 않게 설정
                //         ),
                //       ),
                //       fixedSize: MaterialStateProperty.all(Size.fromHeight(50)),
                //     ),
                //   ),
                // ),
                SizedBox(width: 10,),
                Expanded(
                    child: ElevatedButton(
                      onPressed: ()=> showEmailDialog(context, '수검자별내시경세척및소독일지'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Row의 크기를 자식들의 크기에 맞게 조절
                        children: <Widget>[
                          Text(
                            '세척&소독일지',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                            ),
                          ), // 텍스트 위젯
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
            SizedBox(height: 5,),
            //Divider(color: Colors.indigo,),
            SizedBox(height: 5,),
            Row(
              children: [
                SizedBox(width: 5,),
                Text(
                    '과장님별 통계',
                    textAlign: TextAlign.start,
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
                Checkbox(
                  tristate:false,
                  value: eachDocSummary,
                  onChanged: (value) {
                    setState(() {
                      eachDocSummary = value!;
                    });
                  },
                ),
              ],
            ),
            eachDocSummary? Row(
                children: [
                  //SizedBox(width: 1,),
                  TextButton(
                    onPressed: () => _selectDateForEachPurpose(context, "Doc", true), // true for start date
                    child: Row(
                      children: [
                        Text(
                            'From: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                        ),
                        Text(DateFormat('yy-MM-dd').format(startDateForDocSummary)),
                      ],
                    ),
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 8.0)), // 버튼 내부 패딩 조절
                      // 기타 스타일 설정...
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDateForEachPurpose(context, "Doc", false), // false for end date
                    child: Row(
                      children: [
                        Text(
                          'To: ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(DateFormat('yy-MM-dd').format(endDateForDocSummary)),
                      ],
                    ),
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 5.0)), // 버튼 내부 패딩 조절
                      // 기타 스타일 설정...
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
                  ElevatedButton(
                    onPressed: () {
                      fetchDataByDoctorAndDateRange(selectedDoctor, startDateForDocSummary, endDateForDocSummary);
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
                      padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                      //fixedSize: MaterialStateProperty.all(Size.fromHeight(30)),
                    ),
                  ),

                ],
              )
             : SizedBox(),
            //SizedBox(height: 5,),
            //Divider(color: Colors.indigo,),
            Row(
              children: [
                SizedBox(width: 5,),
                Text(
                  '검사 요약',
                  textAlign: TextAlign.start,
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
                Checkbox(
                  tristate:false,
                  value: examSummary,
                  onChanged: (value) {
                    setState(() {
                      examSummary = value!;
                    });
                  },
                ),
                examSummary? TextButton(
                  onPressed: () => _selectDateForEachPurpose(context,"Exam", true), // true for start date
                  child: Row(
                    children: [
                      Text(
                        'From: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(DateFormat('yy-MM-dd').format(startDateForExamSummary)),
                    ],
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 8.0)), // 버튼 내부 패딩 조절
                    // 기타 스타일 설정...
                  ),
                ) : SizedBox(),
                examSummary? TextButton(
                  onPressed: () => _selectDateForEachPurpose(context, "Exam", false), // false for end date
                  child: Row(
                    children: [
                      Text(
                        'To: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(DateFormat('yy-MM-dd').format(endDateForExamSummary)),
                    ],
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 5.0)), // 버튼 내부 패딩 조절
                    // 기타 스타일 설정...
                  ),
                ) : SizedBox(),
              ],
            ),
            examSummary? buildSummaryWidget(
                DateFormat('yyyy-MM-dd').format(startDateForExamSummary), DateFormat('yyyy-MM-dd').format(endDateForExamSummary))
                : SizedBox(),
            Row(
              children: [
                SizedBox(width: 5,),
                Text(
                  '방별 요약',
                  textAlign: TextAlign.start,
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
                Checkbox(
                  tristate:false,
                  value: roomSummary,
                  onChanged: (value) {
                    setState(() {
                      roomSummary = value!;
                    });
                  },
                ),
                roomSummary? TextButton(
                  onPressed: () => _selectDateForEachPurpose(context, "Room", true), // true for start date
                  child: Row(
                    children: [
                      Text(
                        'From: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(DateFormat('yy-MM-dd').format(startDateForRoomSummary)),
                    ],
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 8.0)), // 버튼 내부 패딩 조절
                    // 기타 스타일 설정...
                  ),
                ) : SizedBox(),
                roomSummary? TextButton(
                  onPressed: () => _selectDateForEachPurpose(context, "Room",  false), // false for end date
                  child: Row(
                    children: [
                      Text(
                        'To: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(DateFormat('yy-MM-dd').format(endDateForRoomSummary)),
                    ],
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 5.0)), // 버튼 내부 패딩 조절
                    // 기타 스타일 설정...
                  ),
                ) : SizedBox(),
              ],
            ),
            roomSummary? buildRoomSummaryWidget(
                DateFormat('yyyy-MM-dd').format(startDateForRoomSummary), DateFormat('yyyy-MM-dd').format(endDateForRoomSummary))
                : SizedBox(),
            Row(
              children: [
                SizedBox(width: 5,),
                Text(
                  '세부 검색',
                  textAlign: TextAlign.start,
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
                Checkbox(
                  tristate:false,
                  value: detailQuery,
                  onChanged: (value) {
                    setState(() {
                      detailQuery = value!;
                    });
                  },
                ),
                detailQuery? TextButton(
                  onPressed: () => _selectDateForEachPurpose(context, "detailQuery", true), // true for start date
                  child: Row(
                    children: [
                      Text(
                        'From: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(DateFormat('yy-MM-dd').format(startDateForDetailQuery)),
                    ],
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 8.0)), // 버튼 내부 패딩 조절
                    // 기타 스타일 설정...
                  ),
                ) : SizedBox(),
                detailQuery? TextButton(
                  onPressed: () => _selectDateForEachPurpose(context, "detailQuery", false), // false for end date
                  child: Row(
                    children: [
                      Text(
                        'To: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(DateFormat('yy-MM-dd').format(endDateForDetailQuery)),
                    ],
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 5.0)), // 버튼 내부 패딩 조절
                  ),
                ) : SizedBox(),
              ],
            ),
            detailQuery? Container(
                padding: EdgeInsets.all(1.0),
                decoration: BoxDecoration(
                  color: Colors.white24, // 배경색 설정
                  border: Border.all(
                    color: Colors.grey, // 테두리 색상
                    width: 1.0, // 테두리 두께
                  ),
                  borderRadius: BorderRadius.circular(12), // 테두리 둥글게
                ),
                child: sortDetail(startDate: startDateForDetailQuery, endDate: endDateForDetailQuery, tabController: widget.tabController!)) : SizedBox(),
            SizedBox(height: 10,),
            // ElevatedButton(
            //     onPressed: () => makingExcelFileEndoscopyWahserDailyReport(DateFormat('yyyy-MM-dd').format(selectedDate)),
            //     child: Text('엑셀')
            // ),
            // ElevatedButton(
            //     onPressed: () async {
            //       final firestore = FirebaseFirestore.instance;
            //       final id = "da1407ee-2e4f-4a97-8d1e-aed116460432";
            //       QuerySnapshot querySnapshot = await firestore.collection('patients').get();
            //       //QuerySnapshot querySnapshot = await firestore.collection('patients').where('id', isEqualTo: id).get();
            //       for (var doc in querySnapshot.docs) {
            //         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            //         if (data['날짜'].length >10) {
            //           print (data['이름']);
            //         }
            //       }
            //     },
            //     child: Text('데이터찾기')
            // )

          ],
        ),
      ),
    );
  }
}
