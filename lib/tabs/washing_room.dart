import 'dart:convert';
import 'package:ansung_endo/widgets/endoscopy_button.dart';
import 'package:ansung_endo/widgets/washer_record_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'dart:io';
import 'package:intl/intl.dart';
import '../widgets/machine_button.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



late Map<String, List<dynamic>?> machineScopyTimePtName = {'1호기':[], '2호기':[], '3호기':[], '4호기':[], '5호기':[]};
late Map<String, List<dynamic>?> todaymachineScopyTimePtName = {'1호기':[], '2호기':[], '3호기':[], '4호기':[], '5호기':[]};
late Map<String, List<dynamic>?> machineWasherChange =
{'1호기':['2000-01-01 00:00'], '2호기':['2000-01-01 00:00'], '3호기':['2000-01-01 00:00'], '4호기':['2000-01-01 00:00'], '5호기':['2000-01-01 00:00']};
late Map<String, int> selectedIndexOfWasherChangeList = {'1호기':0, '2호기':0, '3호기':0, '4호기':0, '5호기':0};
late Map<String, bool> displayTodayOrNot = {'1호기':true, '2호기':true, '3호기':true, '4호기':true, '5호기':true};
late String emailAdress = "";

class WashingRoom extends StatefulWidget {
  //MyHomePage({Key key}) : super(key: key);

  //final String title;

  @override
  _WashingRoomState createState() => _WashingRoomState();
}

class _WashingRoomState extends State<WashingRoom> {

  bool _isPressedMachine = false;
  bool _isPressedScopy = false;
  int _selectedIndexMachine = 0;
  int _selectedIndexScopy = 0;
  String selectedMachineName = "";
  String selectedScopyName = "";
  String _selectedTimeOtherDay = "";
  bool displatyToday = true;


  Map<String, String> scopyFullName = {'039':'7C692K039', '073':'KG391K073', '098':'5C692K098',  '153':'5G391K153', '166':'6C692K166',
    '180':'5G391K180', '219':'1C664K219', '256':'7G391K257', '257':'7G391k257', '259':'7G391K259', '333':'2G348K333', '379':'1C665K379', '390':'2G348K390',
    '405':'2G348K405', '407':'2G348K407', '515':'1C666K515', '694':'5G348K694'};

  List<String> scopyShortName= ['039', '073', '098', '153','166','180','219', '256', '257', '259', '333', '379', '390', '405','407', '515', '694'];

  Map<String, String> washingMachingFullName = {'1호기':'J1-G0423102', '2호기':'J1-G0423103', '3호기':'J1-G0423104', '4호기':'J1-G0417099', '5호기':'J1-I0210032'};

  int timeAsEpoch = 0;
  // '${DateTime.now().toUtc().add(Duration(hours: 9)).toString().substring(0, 19)}';

  DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  DateFormat dateFormatHHmm = DateFormat('HH:mm');

  String PtID = "";

  @override
  void initState() {
    //super.initState();
    //_loadData();
    _loadDataFromFirebase();
  }

  void _onPressedMachine(int index, String machineName) {
    setState(() {
      if (_selectedIndexMachine != index) {
        _selectedIndexMachine = index;
        _isPressedMachine = true;
        selectedMachineName = machineName;
      } else {
        _isPressedMachine = !_isPressedMachine;
      }
    });
  }

  void _onPressedScopy(int index, String scopyName) {
    setState(() {
      if (_selectedIndexScopy != index) {
        _selectedIndexScopy = index;
        _isPressedScopy = true;
        selectedScopyName = scopyName;
      } else {
        _isPressedScopy = !_isPressedScopy;
      }
    });
  }

  int dateToMilliseconds (String dateString) {

    DateTime date = DateTime.parse(dateString);
    int milliseconds = date.millisecondsSinceEpoch;

    return milliseconds;
  }

  String timeToformattedFormAsyyyyMMddHHMM(DateTime time) {
    //DateTime now = DateTime.now().toUtc().add(Duration(hours: 9));
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(time);
    return formattedDate;
  }

  Future<void> _loadDataFromFirebase() async {
    final firestore = FirebaseFirestore.instance;

    try {
      // 기계 별 내시경 소독 기록 가져오기
      QuerySnapshot scopyTimePtIDSnapshot = await firestore.collectionGroup('records').get();
      machineScopyTimePtName = {
        '1호기': [],
        '2호기': [],
        '3호기': [],
        '4호기': [],
        '5호기': [],
      };
      for (QueryDocumentSnapshot doc in scopyTimePtIDSnapshot.docs) {
        String machineName = doc.reference.parent.parent!.id;
        String scopyName = doc.get('일련번호');
        String dateTime = doc.get('날짜-시간');
        try {
          String id = doc.get('환자정보');
          String ptName = "";
          QuerySnapshot querySnapshot = await firestore.collection('patients').where('id', isEqualTo:id).get();
          if (querySnapshot.docs.isNotEmpty) {
            for (var doc in querySnapshot.docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              ptName = data['이름'];
            }
          }
          machineScopyTimePtName[machineName]!.add({'일련번호':scopyName, '날짜-시간':dateTime, '환자이름':ptName});
        } catch (e) {
          print ('machineName:$machineName, 날짜-시간:$dateTime');
        }



      }

      // 기계 별 세척액 변경 기록 가져오기
      QuerySnapshot washerChangeSnapshot = await firestore.collectionGroup('washerChanges').get();
      machineWasherChange = {
        '1호기': [],
        '2호기': [],
        '3호기': [],
        '4호기': [],
        '5호기': [],
      };
      for (QueryDocumentSnapshot doc in washerChangeSnapshot.docs) {
        String machineName = doc.reference.parent.parent!.id;
        String changeDate = doc.get('changeDate');
        machineWasherChange[machineName]!.add(changeDate);
      }

      // 초기 selectedIndexOfWasherChangeList 설정
      selectedIndexOfWasherChangeList.forEach((key, value) {
        selectedIndexOfWasherChangeList[key] = machineWasherChange[key]!.length - 1;
      });

      // todaymachineScopyTime 초기화
      _initializeTodaymachineScopyTimePtName();
    } catch (e) {
      print('Error loading data from Firestore: $e');
    }
    setState(() {
      print('시작');
    });

  }

  void _initializeTodaymachineScopyTimePtName() {
    DateTime today = DateTime.now();
    DateTime midnight = DateTime(today.year, today.month, today.day);
    int todayMidNightMillisecondsSinceEpoch = midnight.millisecondsSinceEpoch;

    todaymachineScopyTimePtName = {
      '1호기': [],
      '2호기': [],
      '3호기': [],
      '4호기': [],
      '5호기': [],
    };

    machineScopyTimePtName.forEach((key, value) {
      if (value != null) {
        value.forEach((element) {
          if (dateToMilliseconds(element['날짜-시간']) > todayMidNightMillisecondsSinceEpoch) {
            todaymachineScopyTimePtName[key]!.add(element);
          }
        });
      }
    });
    print ('today: $todaymachineScopyTimePtName');
  }


  Future<void> saveMachineWasherChangeToFirestore(String machine, DateTime time) async {
    final firestore = FirebaseFirestore.instance;

    final changeDate = timeToformattedFormAsyyyyMMddHHMM(time);
    Map<String, String> data = {'changeDate' :changeDate};
    try {
      await firestore.collection('machines').doc(machine).collection('washerChanges').add(data);
      print('washer change date Data saved successfully!');
    } catch (e) {
      print('Error saving data to Firestore: $e');
    }
  }


  Future<void> saveMachineScopyTimePtIDToFirestore(String machine, Map<String, String> recordInfo) async {
    // Firestore 인스턴스 생성
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // 문서 이름 생성 ('machine_날짜-시간')
    String documentName = '${recordInfo['일련번호']}_${recordInfo['날짜-시간']}';

    try {
      // 'machine' 컬렉션 내 'machine' 문서의 'records' 서브컬렉션에
      // 'documentName' 이름으로 문서 생성 후 'recordInfo' Map 데이터 추가
      await firestore.collection('machines').doc(machine).collection('records').doc(documentName).set(recordInfo);

      print('Data saved successfully!');
    } catch (e) {
      print('Error saving data to Firestore: $e');
    }
  }


  void _store(String machineName, String scopy, Map<String, dynamic> patientAndExamInformation, String appBarDate) async {

    if (!_isPressedScopy) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('경고'),
            content: Text('내시경 번호를 선택해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('예'),
              ),
            ],
          );
        },
      );
    }

    if (!_isPressedMachine) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('경고'),
            content: Text('세척기 번호를 선택해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('예'),
              ),
            ],
          );
        },
      );
    }

    if (listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate(machineName, machineWasherChange[machineName]!.last).length>=80){
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('경고'),
            content: Text('세척 횟수가 80 넘게됩니다. 세척액을 교체해주세요'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('예'),
              ),
            ],
          );
        },
      );
      return;
    }

    if ((DateTime.now().difference(DateTime.parse(machineWasherChange[machineName]!.last))).inDays+1 >28) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('경고'),
            content: Text('세척액 교체일수가 28일 넘었습니다. 세척액을 교체해주세요'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('예'),
              ),
            ],
          );
        },
      );
      return;
    }



    if (appBarDate == 'Today') {
      print ('Today');
      if (_isPressedMachine && _isPressedScopy) {
        final currentTime = timeToformattedFormAsyyyyMMddHHMM(DateTime.now());
        Map<String, String> newInfo = {'날짜-시간':currentTime, '일련번호':scopy, '환자정보':patientAndExamInformation['id']};
        Map<String, String> newInfoWithName = {'날짜-시간':currentTime, '일련번호':scopy, '환자이름':patientAndExamInformation['이름']};
        setState(() {
          todaymachineScopyTimePtName[machineName]!.add(newInfoWithName);
        });
        machineScopyTimePtName[machineName]!.add(newInfoWithName);

        final Map<String, List<dynamic>?>sortedmachineScopyTime = {};
        machineScopyTimePtName.forEach((key, value) {
          sortedmachineScopyTime[key] = sortRecordsByDateTime(value!);
        });
        print ('newInifo:$newInfo');
        await saveMachineScopyTimePtIDToFirestore(machineName, newInfo);

      }
    } else {
      final TimeOfDay initialTime = TimeOfDay(hour: 9, minute: 0);
      final TimeOfDay? picked = await showTimePicker(context: context, initialTime: initialTime);
      DateTime date = DateTime.parse(appBarDate);
      DateTime otherDateAndTime = DateTime(
          date.year, date.month, date.day, picked!.hour, picked.minute
      );
      String otherDateAndTimeFormattedForm = DateFormat('yyyy-MM-dd HH:mm').format(otherDateAndTime);
      //SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, String> newInfo = {'날짜-시간':otherDateAndTimeFormattedForm, '일련번호':scopy, '환자정보':patientAndExamInformation['id']};
      Map<String, String> newInfoWithName = {'날짜-시간':otherDateAndTimeFormattedForm, '일련번호':scopy, '환자이름':patientAndExamInformation['이름']};
      setState(() {
        machineScopyTimePtName[machineName]!.add(newInfoWithName);
      });
      final Map<String, List<dynamic>?>sortedmachineScopyTime = {};
      machineScopyTimePtName.forEach((key, value) {
        sortedmachineScopyTime[key] = sortRecordsByDateTime(value!);
      });
      //await prefs.setString('machineScopyTime', jsonEncode(sortedmachineScopyTime));
      await saveMachineScopyTimePtIDToFirestore(machineName, newInfo);
    }
    setState(() {
      selectedPatientName = '환자';
    });


  }

  void deleteItemFromFirestore(String machineName, Map<String, String> scopyTimePtName) async {
    final firestore = FirebaseFirestore.instance;
    String docId = '${scopyTimePtName['일련번호']}_${scopyTimePtName['날짜-시간']}'; // 고유 ID 생성 방식이 데이터에 맞게 조정되어야 합니다.

    try {
      await firestore.collection('machines').doc(machineName).collection('records').doc(docId).delete();
      print('Document successfully deleted.');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }


  // void _storeAfterDeleteOrEdit(machineName) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('machineScopyTime', jsonEncode(machineScopyTime));
  //
  //
  //   setState(() {
  //     final String =  machineScopyTime[machineName]![0];
  //   });
  // }

  void deleteItem(String machineName, Map endoscopyTimePtName) {
    setState(() {
      machineScopyTimePtName[machineName]!.remove(endoscopyTimePtName);
    });
  }

  Future<void> makingExcelFileforEachWashingMachineReport(String machineName, String washerChangeDate ) async {

    final List scopyAndTimeList = listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate(machineName, washerChangeDate);

    final workbook = xls.Workbook();

    final xls.Style globalstyle = workbook.styles.add('style');
    globalstyle.hAlign = xls.HAlignType.center;
    globalstyle.vAlign = xls.VAlignType.center;
    globalstyle.borders.all.lineStyle = xls.LineStyle.thin;


    final worksheet = workbook.worksheets[0];
    worksheet.name = '1호기';
    worksheet.pageSetup.orientation = xls.ExcelPageOrientation.landscape;
    worksheet.getRangeByName('A1:N1').merge();
    worksheet.getRangeByName('A1').setText('내시경 식별 번호 내역 & 소독액 사용 횟수');
    worksheet.getRangeByName('A1:N1').cellStyle = globalstyle;
    worksheet.getRangeByName('A1:N1').cellStyle.bold = true;
    worksheet.getRangeByName('A1:N1').cellStyle.fontSize = 20;

    Directory? appDirectory = await getApplicationDocumentsDirectory();
    final fileName = appDirectory.path + '/내시경 식별 번호 내역 & 소독액 사용 횟수.xlsx';
    worksheet.getRangeByName('A2').setText('세척기');
    worksheet.getRangeByName('A2').cellStyle.fontSize=11;
    worksheet.getRangeByName('B2:E2').merge();
    worksheet.getRangeByName('B2').setText('${machineName[0]}호:${washingMachingFullName[machineName]}');
    worksheet.getRangeByName('B2').cellStyle.fontSize=11;
    worksheet.getRangeByName('F2').setText('소독횟수');
    worksheet.getRangeByName('G2').setText('${scopyAndTimeList.length}');
    worksheet.getRangeByName('H2:I2').merge();
    worksheet.getRangeByName('H2').setText('소독액 주입일');
    worksheet.getRangeByName('H2').cellStyle.fontSize=11;
    worksheet.getRangeByName('J2:K2').merge();
    worksheet.getRangeByName('J2').setText(washerChangeDate);
    worksheet.getRangeByName('J2').cellStyle.fontSize=11;
    worksheet.getRangeByName('L2').setText('담당자');
    worksheet.getRangeByName('M2:N2').merge();

    worksheet.getRangeByName('A3').setText('소독액명');
    worksheet.getRangeByName('A3').cellStyle.fontSize=11;
    worksheet.getRangeByName('B3:G3').merge();
    worksheet.getRangeByName('B3').setText('페라플루디액 1제+2제(0.2%과아세트산)');
    worksheet.getRangeByName('H3:I3').merge();
    worksheet.getRangeByName('H3').setText('소독액 배출일');
    worksheet.getRangeByName('H3').cellStyle.fontSize=11;
    worksheet.getRangeByName('J3:K3').merge();
    worksheet.getRangeByName('L3').setText('부서장');
    worksheet.getRangeByName('M3:N3').merge();

    worksheet.getRangeByName('A1:N3').cellStyle = globalstyle;

    //worksheet.getRangeByName('G2').cellStyle.hAlign = xls.HAlignType.right;

    final List ColumnName = ['B', 'C', 'D','E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'];
    var  row = 4;

    final monthAndDayList = {};
    scopyAndTimeList.forEach((element) {
      final String monthAndDay = DateFormat('MM/dd').format(DateTime.parse(element[1]));
      final String hourAndMin = DateFormat('HH:mm').format(DateTime.parse(element[1]));
      final int sequenceNum = scopyAndTimeList.indexOf(element)+1;
      if (!monthAndDayList.containsKey(monthAndDay)) {
        monthAndDayList[monthAndDay] = [];
        monthAndDayList[monthAndDay].add([element[0], sequenceNum.toString(), hourAndMin]);
      } else {
        monthAndDayList[monthAndDay].add([element[0], sequenceNum.toString(), hourAndMin]);
      }
    });

    monthAndDayList.forEach((key, value) {
      worksheet.getRangeByName('A${row.toString()}').cellStyle = globalstyle;
      worksheet.getRangeByName('A${row.toString()}').cellStyle.bold = true;
      worksheet.getRangeByName('A${row.toString()}').cellStyle.fontSize = 12;
      worksheet.getRangeByName('A${row.toString()}').setText(key);
      for (int i=0;i<value.length;i++) {
        final String excelLocationName = ColumnName[i]+row.toString();
        worksheet.getRangeByName(excelLocationName).cellStyle = globalstyle;
        worksheet.getRangeByName(excelLocationName).cellStyle.fontSize = 9;
        worksheet.getRangeByName(excelLocationName).setText('${scopyFullName[value[i][0]]} \n ${value[i][1]} / ${value[i][2]}');
      }
      row++;
    });





    final excelData = workbook.saveAsStream();
    workbook.dispose();
    //await workbook.saAsBytes(bytes, flush: true);

    final file = await File(fileName).create(recursive: true);

    await file.writeAsBytes(excelData, flush: true);
  }

  Future<void> makingExcelFileforDailyWashingMachineReport() async {

    final alphabetList = ['A','B', 'C','D','E','F','G','H','I','J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R'];

    final workbook = xls.Workbook();

    final DateTime today = DateTime.now();
    final String formattedToday = DateFormat('yyyy-MM-dd').format(today);

    final worksheet = workbook.worksheets[0];

    final xls.Style globalstyle = workbook.styles.add('style');
    globalstyle.hAlign = xls.HAlignType.center;
    globalstyle.vAlign = xls.VAlignType.center;
    globalstyle.borders.all.lineStyle = xls.LineStyle.thin;

    worksheet.getRangeByName('A1:F1').merge();
    worksheet.getRangeByName('A1').setText('세척기 사용 순서($formattedToday)');
    worksheet.getRangeByName('A1:F1').cellStyle = globalstyle;
    worksheet.getRangeByName('A1:F1').cellStyle.bold = true;
    worksheet.getRangeByName('A1:F1').cellStyle.fontSize = 20;

    List<int> tempList = [];
    todaymachineScopyTimePtName.forEach((key, value) {
      tempList.add(value!.length);
    });
    int maxLength = tempList.fold(0, (a,b) => a>b? a:b);
    for (int i=0;i<maxLength;i++) {
      worksheet.getRangeByName('A${i+3}').setText('${i+1}');
      worksheet.getRangeByName('A${i+3}').cellStyle = globalstyle;
    }
    worksheet.getRangeByName('B2').setText('1호기(102)');
    worksheet.getRangeByName('C2').setText('2호기(103)');
    worksheet.getRangeByName('D2').setText('3호기(104)');
    worksheet.getRangeByName('E2').setText('4호기(099)');
    worksheet.getRangeByName('F2').setText('5호기(032)');
    worksheet.getRangeByName('B2:F2').cellStyle.bold = true;
    worksheet.setColumnWidthInPixels(2, 100);
    worksheet.setColumnWidthInPixels(3, 100);
    worksheet.setColumnWidthInPixels(4, 100);
    worksheet.setColumnWidthInPixels(5, 100);
    worksheet.setColumnWidthInPixels(6, 100);
    worksheet.getRangeByName('A2:F${maxLength+2}').cellStyle = globalstyle;
    worksheet.getRangeByName('B2:F2').cellStyle.bold = true;

    todaymachineScopyTimePtName.forEach((key, value) {
      if (value!.length >0 ) {
        for (int i = 0; i < value.length; i++) {
          worksheet.getRangeByName('${alphabetList[int.parse(key[0])]}${i + 3}').cellStyle = globalstyle;
          final scopyName =  scopyFullName[value[i][0]];
          final timeAsHHmm = value[i][1].substring(11);
          worksheet.getRangeByName('${alphabetList[int.parse(key[0])]}${i + 3}')
              .setText('$scopyName \n (${timeAsHHmm})');

        }
      }
    });



    Directory? appDirectory = await getApplicationDocumentsDirectory();
    final fileName = appDirectory.path + '/세척기사용순서(' + formattedToday + ').xlsx';

    final excelData = workbook.saveAsStream();
    workbook.dispose();
    //await workbook.saAsBytes(bytes, flush: true);

    final file = await File(fileName).create(recursive: true);

    await file.writeAsBytes(excelData, flush: true);
  }

  Future<void> showEmailDialog(BuildContext context) async {
    TextEditingController emailController = TextEditingController();

    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title:Text('메일주소입력'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('보낼 메일 주소를 입력하세요.'),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(hintText:emailAdress),
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
                    emailAdress = emailController.text;
                    _sendEmailForDailyReport(emailAdress);
                    Navigator.of(context).pop();
                  },
                  child: Text('보내기')
              )
            ],
          );
        }
    );
  }



  Future<void> _sendEmailForDailyReport(String emailAddress) async {
    Directory? appDirectory = await getApplicationDocumentsDirectory();
    makingExcelFileforDailyWashingMachineReport();
    final String formattedToday = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final email = Email(
      body: '오늘 하루도 수고했어요.  늘 감사합니다^^',
      subject: '데일리내시경세척리포트($formattedToday)',
      recipients: [emailAddress, '19030112@bizmeka.com'],
      attachmentPaths: ['${appDirectory.path}/'+ '세척기사용순서('+ '$formattedToday' +').xlsx'],
    );



    String platformResponse;

    try {
      await FlutterEmailSender.send(email);
      platformResponse = "success";
    } catch (error) {
      platformResponse = error.toString();
    }

    if (!mounted) return;

    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text(platformResponse),
    // ));
  }

  Future<void> _selectDateForChangingWasher(BuildContext context, String machineName, StateSetter setState) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        // 날짜와 시간 결합
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // 최종 문자열 포맷
        final String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(
            finalDateTime);

        if (!machineWasherChange[machineName]!.contains(formattedDateTime)) {
          setState(() {
            machineWasherChange[machineName]!.add(formattedDateTime);
          });
          //SharedPreferences prefs = await SharedPreferences.getInstance();
          // await prefs.setString(
          //     'machineWasherChange', jsonEncode(machineWasherChange));
          await saveMachineWasherChangeToFirestore(machineName, finalDateTime);
        }
      }
    }
  }

  Future<void> _showWasherRecord(BuildContext context, String machineName) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: Center(
                  child: Text("$machineName 소독액 변경 날짜"),
                ),
                content: Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true, // 다이얼로그 크기에 맞게 ListView의 크기를 조정
                    itemCount: machineWasherChange[machineName]?.length ?? 0, // 항목의 개수 지정
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Radio<int>(
                          value: index,
                          groupValue: selectedIndexOfWasherChangeList[machineName],
                          onChanged: (int? value) {
                            setState(() {
                              selectedIndexOfWasherChangeList[machineName] = value!;
                              displayTodayOrNot[machineName] = false;
                            });
                          },
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max, // Column의 크기를 내용에 맞게 조절
                          children: [
                            Text(
                              DateFormat('yy/MM/dd').format(DateFormat('yyyy-MM-dd').parse(machineWasherChange[machineName]![index]))+'(${listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate(machineName, machineWasherChange[machineName]![index]).length})',
                              style: TextStyle(
                                fontSize: 18, // 글씨 크기를 조금 크게 설정
                                fontWeight: FontWeight.bold,
                                color: Colors.red,// 글씨를 굵게 설정
                              ),

                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _updateMachineWasherChangeDate(context, machineName, index, setState),
                                  icon: Icon(Icons.edit, size: 20),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _deleteMachineWasherChangeDate(machineName, index, setState);
                                    });
                                  },
                                  icon: Icon(Icons.delete, size: 20),
                                ),
                                IconButton(
                                  onPressed: () => makingExcelFileforEachWashingMachineReport(machineName, machineWasherChange[machineName]![index]) ,
                                  icon: Icon(Icons.mail, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );

                    },
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('추가'),
                    onPressed: () {
                      setState(() {
                        _selectDateForChangingWasher(context, machineName, setState);
                      });
                    },
                  ),
                  TextButton(
                    child: Text('닫기'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            }
        );
      },
    ) ?? false;
    if (result == true) {
      setState(() {
        final String tempString = machineWasherChange[machineName]![0];
      });
    }
  }


  Future<void> _updateMachineWasherChangeDate(BuildContext context,  String machineName, int index, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      //locale: const Locale('ko', 'KR'),
    );
    if (picked != null && !machineWasherChange[machineName]!.contains(DateFormat('yyyy-MM-dd').format(picked))) {
      setState(() {
        machineWasherChange[machineName]![index]= DateFormat('yyyy-MM-dd').format(picked);
      });
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setString('machineWasherChange', jsonEncode(machineWasherChange));
      saveMachineWasherChangeToFirestore(machineName, picked);

    }
  }

  Future<void> _deleteMachineWasherChangeDateFromFirebase(String machineName, String changeDate) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // 세척액 변경 날짜에 해당하는 문서 찾기
      var querySnapshot = await firestore
          .collection('machines')
          .doc(machineName)
          .collection('washerChanges')
          .where('changeDate', isEqualTo: changeDate)
          .get();

      // 해당 문서 삭제
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

    } catch (e) {
      print('Error deleting machine washer change date from Firestore: $e');
    }
  }


  Future<void> _deleteMachineWasherChangeDate(String machineName, int index, StateSetter setState) async {
    setState(() {
      if (machineWasherChange[machineName] != null) {
        machineWasherChange[machineName]!.removeAt(index);
      }
    });
    _deleteMachineWasherChangeDateFromFirebase(machineName, machineWasherChange[machineName]![index]);
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.setString('machineWasherChange', jsonEncode(machineWasherChange));
  }

  DateTime selectedDate = DateTime.now();

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

  List<dynamic> sortRecordsByDateTime(List<dynamic> records) {
    records.sort((a, b) {
      // '시간-날짜' 값을 DateTime 으로 파싱합니다.
      DateTime dateTimeA = DateTime.parse(a['날짜-시간']);
      DateTime dateTimeB = DateTime.parse(b['날짜-시간']);

      // DateTime 객체를 비교하여 정렬합니다.
      return dateTimeA.compareTo(dateTimeB);
    });
    return records;
  }

  bool compareDatesAndAddIfLater(String dateStr, String dateTimeStr) {
    List<String> result = [];

    // 문자열을 DateTime 객체로 변환
    DateTime date = DateTime.parse(dateStr);
    DateTime dateTime = DateTime.parse(dateTimeStr);

    // 두 DateTime 객체를 비교
    if (dateTime.isAfter(date)) {
      return true;
    }

    return false;


  }

  List listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate(
      String machineName, String washerChangeDate) {
    List tempList = [];
    final indexOfWasherDate = machineWasherChange[machineName]!.indexOf(washerChangeDate);
    final indexOfNextWasherDate = indexOfWasherDate+1;
    if (machineScopyTimePtName[machineName] != null) {
      for (Map element in machineScopyTimePtName[machineName]!) {
        if (indexOfWasherDate+1 == machineWasherChange[machineName]!.length) {
          if (compareDatesAndAddIfLater(washerChangeDate, element['날짜-시간'])) {
            tempList.add(element);
          }
        } else {
          if (compareDatesAndAddIfLater(washerChangeDate, element['날짜-시간']) && !compareDatesAndAddIfLater(machineWasherChange[machineName]![indexOfNextWasherDate], element['날짜-시간'])) {
            tempList.add(element);
          }
        }
      }

    }
    return tempList;
  }

  List<Widget> buildEndoscopyButtons(List<String> data) {
    List<Widget> rows = [];
    List<Widget> buttons = [];

    // 데이터를 순회하며 endoscopyButton 위젯을 생성
    for (var i = 0; i < data.length; i++) {
      buttons.add(
        endoscopyButton(
          onPressed: () => _onPressedScopy(int.parse(data[i]), data[i]),
          text: data[i],
          isSelected: _isPressedScopy && _selectedIndexScopy == int.parse(data[i]),
        ),
      );

      // 매 5개의 버튼이나 마지막 버튼에 도달했을 때 Row 위젯에 추가
      if ((i + 1) % 5 == 0 || i == data.length - 1) {
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [...buttons],
          ),
        );
        buttons = []; // 버튼 리스트 초기화
      }
    }

    return rows;
  }

  Future<List<Map<String, dynamic>>> fetchPatientInfoByDate(DateTime date) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> patientsList = [];

    String DateString = DateFormat('yyyy-MM-dd').format(date);

    try{
      QuerySnapshot querySnapshot = await firestore.collection('patients')
          .where('날짜', isEqualTo:DateString)
          .get();

      for(var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        patientsList.add(data);
      }
    } catch (e) {
      print ("데이터를 가져오지 못했습니다. :$e");
    }

    return patientsList;
  }

  DateTime selectedDateInPatientInfoDialog = DateTime.now();
  Map<String, dynamic> patientAndExamInformation = {"id":"", "환자번호":"", '이름':"", '성별':"", '나이':"", "생일":"", "의사":"", "날짜":"", "시간":"",
    "위검진_외래" : "", "위수면_일반":"", "위조직":"", "CLO":false, "위절제술":"", "위응급":false, "PEG":false, "위내시경기계":"",
    "대장검진_외래":"", "대장수면_일반":"", "대장조직":"", "대장절제":"", "대장응급":false, "대장내시경기계":"",
  };
  String selectedPatientName = "환자";

  void showPatientInfoDialog() async {

    List<Map<String, dynamic>> patientInfoList = await fetchPatientInfoByDate(selectedDateInPatientInfoDialog);
    Future<void> _selectDateInPatientInfoDialog(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDateInPatientInfoDialog,
        firstDate: DateTime(2023),
        lastDate: DateTime(2100),
      );
      if (picked != null && picked != selectedDateInPatientInfoDialog) {
        setState(()  {
          selectedDateInPatientInfoDialog = picked;
        });
        Navigator.of(context).pop(); // 현재 대화상자 닫기
        showPatientInfoDialog();

      }
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {

          String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDateInPatientInfoDialog);
          String Today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('환자 목록'),
                TextButton(
                  onPressed: () => _selectDateInPatientInfoDialog(context),
                  child: Today == formattedDate ? Text('Today') : Text("$formattedDate"),
                ),
              ],
            ),
           content: Container(
             width: double.maxFinite,
             child: ListView.builder(
                  shrinkWrap: true,
                 itemCount: patientInfoList.length,
                 itemBuilder: (BuildContext context, int index) {
                    var patient = patientInfoList[index];
                    return ListTile(
                      title: Text("${patient['이름']}(${patient['환자번호']}) ${patient['성별']}/${patient['나이']}"),
                      subtitle: Text("${patient['날짜']}  ${patient['시간']}"),
                      onTap:() {
                        Navigator.of(context).pop();
                        setState(() {
                          patientAndExamInformation = Map<String, dynamic>.from(patient);
                          selectedPatientName = patientAndExamInformation['이름'];
                        });
                      }
                    );
                 }
             ),
           ),
          );
        }
    );
  }



  @override
  Widget build(BuildContext context) {

    void onEdit(String newName, String newDate, String PtName, Map<String, String> oldScopyTimePtMap, String machineName) {

      // 기존 항목을 찾아 수정
      List? scopyList = machineScopyTimePtName[machineName];

      int indexForEntire = scopyList?.indexOf(oldScopyTimePtMap) ?? -1;
      if(indexForEntire != -1) {
        setState(() {
          machineScopyTimePtName[machineName]![indexForEntire] = {'날짜-시간':newDate, '일련번호':newName, '환자이름':PtName};
        });
      }
      List? todayScopyList = todaymachineScopyTimePtName[machineName];
      int indexForToday = todayScopyList?.indexOf(oldScopyTimePtMap) ?? -1;
      if(indexForToday != -1) {
        setState(() {
          todaymachineScopyTimePtName[machineName]![indexForToday] = {'날짜-시간':newDate, '일련번호':newName, '환자이름':PtName};
        });
      }


    }

    final DateFormat DateFormatForAppBarDate = DateFormat('yyyy-MM-dd');

    final String formattedDateForAppBar = DateFormatForAppBarDate.format(selectedDate);
    final String formattedToday = DateFormatForAppBarDate.format(DateTime.now());
    final String appBarDate = (formattedToday == formattedDateForAppBar) ? 'Today' : formattedDateForAppBar;
    // 세척실 탭의 내용
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                    child: machineButton(index: 1, machineName: '1호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine)
                ),
                Expanded(child: SizedBox()),
                Expanded(
                    child: machineButton(index: 3, machineName: '3호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine)
                ),
                Expanded(child: SizedBox()),
                Expanded(
                    child: machineButton(index: 5, machineName: '5호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine)
                ),
              ]),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(child: SizedBox()),
              Expanded(
                child: machineButton(index: 2, machineName: '2호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine),
              ),
              Expanded(child: SizedBox()),
              Expanded(
                child: machineButton(index: 4, machineName: '4호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine),
              ),
              Expanded(child: SizedBox()),
            ],
          ),
          // const Divider(
          //   color: Colors.black,
          //   height: 20.0,
          // ),

          Column(
            children: buildEndoscopyButtons(scopyShortName),
          ),


          // const Divider(
          //   color: Colors.black,
          //   height: 20.0,
          // ),

          Row(
            children: <Widget>[
              Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: showPatientInfoDialog,
                    child: Text(
                        selectedPatientName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(const Color(0xFF6AD4DD)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // 모서리를 둥글지 않게 설정
                        ),

                      ),
                    ),
                  )
              ),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () => _store(selectedMachineName, selectedScopyName, patientAndExamInformation, appBarDate),
                  child: Text(
                    '저장',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(const Color(0xFF5F5D9C)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // 모서리를 둥글지 않게 설정
                      ),

                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: <Widget> [
              ElevatedButton(
                  onPressed: makingExcelFileforDailyWashingMachineReport,
                  child: Text('엑셀파일')
              ),
              // ElevatedButton(
              //     onPressed: ()=>makingExcelFileforEachWashingMachineReport(2),
              //     child: Text('엑셀파일2')
              // ),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      displayTodayOrNot.forEach((key, value) {
                        displayTodayOrNot[key] = true;
                      });
                    });
                  },
                  child: Text('오늘 표시')
              ),
              Expanded(
                // flex: 1, // 이 비율로 '메일 보내기' 버튼이 화면의 20%를 차지합니다.
                child: ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    appBarDate,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,// AppBar의 배경색과 맞추기 위한 텍스트 색상
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
              ),
              IconButton(
                icon: Icon(Icons.mail), // 우편 모양의 아이콘
                onPressed: () => showEmailDialog(context), // _sendEmail 함수 또는 해당 기능을 호출
              )
            ],
          ),
          const Divider(
            color: Colors.black,
            height: 3.0,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(
                children: [
                  WasherRecordButton(
                    machineName: '1호기',
                    //scopyCount: machineScopyTime['1호기']?.length ?? 0, // Null Safety 처리
                    scopyCount: displayTodayOrNot['1호기']!? listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('1호기', machineWasherChange['1호기']!.last).length : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('1호기', machineWasherChange['1호기']![selectedIndexOfWasherChangeList['1호기']!]).length,
                    onPressed: () => _showWasherRecord(context, '1호기'),
                    // 날짜가 없는 경우 기본값 사용
                    lastChangeDate: displayTodayOrNot['1호기']!? machineWasherChange['1호기']!.last : machineWasherChange['1호기']![selectedIndexOfWasherChangeList['1호기']!],

                  ),
                  endoscopyForEachMachineWidget(
                      scopyTimePtNameList: displayTodayOrNot['1호기']!? todaymachineScopyTimePtName['1호기']! : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('1호기', machineWasherChange['1호기']![selectedIndexOfWasherChangeList['1호기']!]),
                      machineName: '1호기',
                      onEdit : onEdit,
                      onDelete: (String machineName, Map<String, String> scopyTimePtName) async {
                        deleteItemFromFirestore(machineName, scopyTimePtName);
                        setState(() {
                          todaymachineScopyTimePtName[machineName]!.remove(scopyTimePtName);
                          machineScopyTimePtName[machineName]!.remove(scopyTimePtName);
                        });
                        //_storeAfterDeleteOrEdit(machineName);
                      }
                  ),
                ],
              )),
              Expanded(child: Column(
                children: [
                  WasherRecordButton(
                    machineName: '2호기',
                    scopyCount:displayTodayOrNot['2호기']!? listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('2호기', machineWasherChange['2호기']!.last).length : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('2호기', machineWasherChange['2호기']![selectedIndexOfWasherChangeList['2호기']!]).length, // Null Safety 처리
                    onPressed: () => _showWasherRecord(context, '2호기'),
                    // 날짜가 없는 경우 기본값 사용
                    lastChangeDate: displayTodayOrNot['2호기']!? machineWasherChange['2호기']!.last : machineWasherChange['2호기']![selectedIndexOfWasherChangeList['2호기']!],

                  ),
                  endoscopyForEachMachineWidget(
                      scopyTimePtNameList: displayTodayOrNot['2호기']!? todaymachineScopyTimePtName['2호기']! :listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('2호기', machineWasherChange['2호기']![selectedIndexOfWasherChangeList['2호기']!]),
                      machineName: '2호기',
                      onEdit : onEdit,
                      onDelete: (String machineName, Map<String, String> scopyTimePtName) async {
                        deleteItemFromFirestore(machineName, scopyTimePtName);
                        setState(() {
                          todaymachineScopyTimePtName[machineName]!.remove(scopyTimePtName);
                          machineScopyTimePtName[machineName]!.remove(scopyTimePtName);
                        });
                        //_storeAfterDeleteOrEdit(machineName);
                      }
                  ),
                ],
              )),
              Expanded(child: Column(
                children: [
                  WasherRecordButton(
                    machineName: '3호기',
                    scopyCount: displayTodayOrNot['3호기']!? listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('3호기', machineWasherChange['3호기']!.last).length : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('3호기', machineWasherChange['3호기']![selectedIndexOfWasherChangeList['3호기']!]).length, // Null Safety 처리
                    onPressed: () => _showWasherRecord(context, '3호기'),
                    // 날짜가 없는 경우 기본값 사용
                    lastChangeDate: displayTodayOrNot['3호기']!? machineWasherChange['3호기']!.last : machineWasherChange['3호기']![selectedIndexOfWasherChangeList['3호기']!],

                  ),
                  endoscopyForEachMachineWidget(
                      scopyTimePtNameList: displayTodayOrNot['3호기']!? todaymachineScopyTimePtName['3호기']! : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('3호기', machineWasherChange['3호기']![selectedIndexOfWasherChangeList['3호기']!]),
                      machineName: '3호기',
                      onEdit : onEdit,
                      onDelete: (String machineName, Map<String,String> scopyTimePtName) async {
                        deleteItemFromFirestore(machineName, scopyTimePtName);
                        setState(() {
                          todaymachineScopyTimePtName[machineName]!.remove(scopyTimePtName);
                          machineScopyTimePtName[machineName]!.remove(scopyTimePtName);
                        });
                        //_storeAfterDeleteOrEdit(machineName);
                      }
                  ),
                ],
              )),
              Expanded(child: Column(
                children: [
                  WasherRecordButton(
                    machineName: '4호기',
                    scopyCount: displayTodayOrNot['4호기']!? listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('4호기', machineWasherChange['4호기']!.last).length : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('4호기', machineWasherChange['4호기']![selectedIndexOfWasherChangeList['4호기']!]).length ?? 0, // Null Safety 처리
                    onPressed: () => _showWasherRecord(context, '4호기'),
                    // 날짜가 없는 경우 기본값 사용
                    lastChangeDate: displayTodayOrNot['4호기']!? machineWasherChange['4호기']!.last :  machineWasherChange['4호기']![selectedIndexOfWasherChangeList['4호기']!] ,

                  ),
                  endoscopyForEachMachineWidget(
                      scopyTimePtNameList: displayTodayOrNot['4호기']!? todaymachineScopyTimePtName['4호기']! : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('4호기', machineWasherChange['4호기']![selectedIndexOfWasherChangeList['4호기']!]),
                      machineName: '4호기',
                      onEdit : onEdit,
                      onDelete: (String machineName, Map<String, String> scopyTimePtName) async {
                        deleteItemFromFirestore(machineName, scopyTimePtName);
                        setState(() {
                          todaymachineScopyTimePtName[machineName]!.remove(scopyTimePtName);
                          machineScopyTimePtName[machineName]!.remove(scopyTimePtName);
                        });
                        //_storeAfterDeleteOrEdit(machineName);
                      }
                  ),
                ],
              )),
              Expanded(child: Column(
                children: [
                  WasherRecordButton(
                    machineName: '5호기',
                    scopyCount:  displayTodayOrNot['5호기']!? listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('5호기', machineWasherChange['5호기']!.last).length : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('5호기', machineWasherChange['5호기']![selectedIndexOfWasherChangeList['5호기']!]).length ?? 0,// Null Safety 처리
                    onPressed: () => _showWasherRecord(context, '5호기'),
                    // 날짜가 없는 경우 기본값 사용
                    lastChangeDate: displayTodayOrNot['5호기']!? machineWasherChange['5호기']!.last : machineWasherChange['5호기']![selectedIndexOfWasherChangeList['5호기']!],

                  ),
                  endoscopyForEachMachineWidget(
                      scopyTimePtNameList: displayTodayOrNot['5호기']!? todaymachineScopyTimePtName['5호기']! : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('5호기', machineWasherChange['5호기']![selectedIndexOfWasherChangeList['5호기']!]),
                      machineName: '5호기',
                      onEdit : onEdit,
                      onDelete: (String machineName, Map<String, String> scopyTimePtName) async {
                        deleteItemFromFirestore(machineName, scopyTimePtName);
                        setState(() {
                          todaymachineScopyTimePtName[machineName]!.remove(scopyTimePtName);
                          machineScopyTimePtName[machineName]!.remove(scopyTimePtName);
                        });
                        //_storeAfterDeleteOrEdit(machineName);
                      }
                  ),
                ],
              ))
            ],
          )
        ],
      ),// 기존에 있던 세척실 탭의 코드를 여기에 넣습니다.
    );
  }
}

Widget endoscopyForEachMachineWidget({
  //required Map<String, List?> machineScopyTime,
  required List scopyTimePtNameList,
  required String machineName,
  required Function onDelete,
  required Function(String, String, String, Map<String, String>, String) onEdit,
}) {
  if (machineScopyTimePtName[machineName]!.isEmpty) {
    return const SizedBox();
  }



  return Column(
    children: scopyTimePtNameList.map((e) {
      return MyButton(
        machineName : machineName,
        scopyTimePtName: e,
        onPressed: () => onDelete(machineName, e),
        onEdit:onEdit,
      );
    }).toList(),

  );
}


class MyButton extends StatelessWidget {
  final String machineName;
  final Map<String, String> scopyTimePtName;
  final VoidCallback onPressed;
  final Function(String, String, String, Map<String, String>, String) onEdit;
  String PtName = "";

  MyButton({
    required this.machineName,
    required this.scopyTimePtName,
    required this.onPressed,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {



    DateFormat dateFormatHHmmInMyButton = DateFormat('HH:mm');
    final dateAsHHmm =  scopyTimePtName['날짜-시간']!.substring(11);
    final dateAsyyDDmm = DateFormat('yy/MM/dd').format(DateTime.parse(scopyTimePtName['날짜-시간']!));
    PtName = scopyTimePtName['환자이름']!;

    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {

              return AlertDialog(
                  title: Text('항목 삭제'),
                  content: Text('이 항목을 삭제하시겠습니까?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('아니오'),
                    ),
                    TextButton(
                        onPressed: () {
                          onPressed();
                          Navigator.of(context).pop();
                        },
                        child: Text('예'))
                  ]
              );
            }
        );
      },
      onLongPress: () async {
        final result = await showDialog(
          context: context,
          builder: (context) => EditDialog(scopyTimePtMap:scopyTimePtName),
        );

        if(result != null) {
          onEdit(result['일련번호'], result['날짜-시간'], result['환자이름'],  scopyTimePtName, machineName);
        }
      },
      child: Container(
          margin: EdgeInsets.all(5.0),
          padding: EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blue,
            ),
            color: displayTodayOrNot[machineName]! ? Colors.lightBlueAccent : Colors.grey,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child : Column(
            children: displayTodayOrNot[machineName]! ? [
              Text(
                scopyTimePtName['일련번호']!,
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),

              ),
              Text((dateAsHHmm)),
              Text(PtName)

            ] : [
              Text(
                scopyTimePtName['일련번호']!,
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(dateAsyyDDmm),
              Text(dateAsHHmm),
              Text(PtName)
            ],
          )
      ),
    );
  }
}

class EditDialog extends StatefulWidget {
  final Map scopyTimePtMap;

  EditDialog({required this.scopyTimePtMap});

  @override
  _EditDialogState createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late TextEditingController _nameController = TextEditingController();
  late TextEditingController _timeController = TextEditingController();
  late TimeOfDay _selectedTime;
  String PtName = "";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scopyTimePtMap['일련번호']);
    //_timeController = TextEditingController(text: DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(widget.scopyTimeList[1]).toUtc()));
    DateFormat format = DateFormat('yyyy-MM-dd HH:mm');
    DateTime initialTime = format.parse(widget.scopyTimePtMap['날짜-시간']);
    _selectedTime = TimeOfDay(hour: initialTime.hour, minute: initialTime.minute);
    PtName = widget.scopyTimePtMap['환자이름'];
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) {
      String formattedTime = picked.format(context);
      _timeController.text = formattedTime;
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    //_timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('항목 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText:'내시경 이름'),
          ),
          // TextField(
          //   controller: _timeController,
          //   decoration: InputDecoration(labelText: '시간(시:분)'),
          // ),
          GestureDetector(
            onTap: ()=> _selectTime(context),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  //labelText: '${_selectedTime.format(context)}',
                  hintText: '${_selectedTime.format(context)}',
                ),
              ),
            ),
          )
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: ()=> Navigator.of(context).pop(),
          child: Text('취소'),
        ),
        TextButton(
          onPressed: () {
            final newName = _nameController.text;
            final newTime = DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              _selectedTime.hour,
              _selectedTime.minute,
            );//.add(Duration(hours: 9));
            Navigator.of(context).pop({"일련번호":newName, "날짜-시간":DateFormat('yyyy-MM-dd HH:mm').format(newTime), '환자이름':PtName});
            // showDialog(
            //   context: context,
            //   builder: (context) => AlertDialog(
            //     title: Text('$newTime(${newTime.millisecondsSinceEpoch})'),
            //   ),
            // );
          },
          child: Text('저장'),
        )


      ],
    );
  }
}