import 'dart:convert';
import 'package:ansung_endo/widgets/endoscopy_button.dart';
import 'package:ansung_endo/widgets/washer_record_button.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'dart:io';
import 'package:intl/intl.dart';
import 'widgets/machine_button.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


late Map<String, List<dynamic>?> machineScopyTime = {'1호기':[], '2호기':[], '3호기':[], '4호기':[], '5호기':[]};
late Map<String, List<dynamic>?> todaymachineScopyTime = {'1호기':[], '2호기':[], '3호기':[], '4호기':[], '5호기':[]};
late Map<String, List<dynamic>?> machineWasherChange =
  {'1호기':['2024-03-01 00:00'], '2호기':['2024-03-01 00:00'], '3호기':['2024-03-01 00:00'], '4호기':['2024-03-01 00:00'], '5호기':['2024-03-01 00:00']};
late Map<String, int> selectedIndexOfWasherChangeList = {'1호기':0, '2호기':0, '3호기':0, '4호기':0, '5호기':0};
late Map<String, bool> displayTodayOrNot = {'1호기':true, '2호기':true, '3호기':true, '4호기':true, '5호기':true};
late String emailAdress = "";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  //MyHomePage({Key key}) : super(key: key);

  //final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isPressedMachine = false;
  bool _isPressedScopy = false;
  int _selectedIndexMachine = 0;
  int _selectedIndexScopy = 0;
  String selectedMachineName = "";
  String selectedScopyName = "";
  String _selectedTimeOtherDay = "";
  bool displatyToday = true;

  
  Map<String, String> scopyFullName = {'039':'7C692K039', '073':'KG391K073', '098':'5C692K098', '166':'6C692K166',
    '180':'5G391K180', '256':'7G391K257', '257':'7G391k257', '259':'7G391K259', '333':'2G348K333', '379':'1C665K379', '390':'2G348K390',
    '405':'2G348K405', '407':'2G348K407', '515':'1C666K515'};

  Map<String, String> washingMachingFullName = {'1호기':'J1-G0423102', '2호기':'J1-G0423103', '3호기':'J1-G0423104', '4호기':'J1-G0417099', '5호기':'J1-I0210032'};

  int timeAsEpoch = 0;
      // '${DateTime.now().toUtc().add(Duration(hours: 9)).toString().substring(0, 19)}';

  DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  DateFormat dateFormatHHmm = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _loadData();
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

  String currentTimeToformattedForm() {
    DateTime now = DateTime.now().toUtc().add(Duration(hours: 9));
    print ('now:$now');
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);
    return formattedDate;
  }

  void _loadData() async {

    DateTime today = DateTime.now().toUtc().add(Duration(hours: 9));
    DateTime midnight = DateTime(today.year, today.month, today.day);
    int todayMidNightMillisecondsSinceEpoch = midnight.millisecondsSinceEpoch;

    final yesterday = DateTime(today.year, today.month, today.day).subtract(Duration(days:2)).millisecondsSinceEpoch;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonStringMachineScopyTime = prefs.getString('machineScopyTime');
    String? jsonStringMachineWasherChange = prefs.getString('machineWasherChange');

    if (jsonStringMachineScopyTime != null) {
      Map<String, dynamic> jsonMap = json.decode(jsonStringMachineScopyTime);
      setState(() {
        machineScopyTime = jsonMap.map((key, value) =>
            MapEntry(key, List<dynamic>.from(value as List<dynamic>? ?? [])));
      });
    }

    if (jsonStringMachineWasherChange != null) {
      print (jsonStringMachineWasherChange);
      Map<String, dynamic> jsonMap = json.decode(jsonStringMachineWasherChange);
      setState(() {
        machineWasherChange = jsonMap.map((key, value) =>
            MapEntry(key, List<dynamic>.from(value as List<dynamic>? ?? ['2024-03-01'])));
      });
      print (machineWasherChange);
    }

    todaymachineScopyTime = {'1호기':[], '2호기':[], '3호기':[], '4호기':[], '5호기':[]};

    machineScopyTime.forEach((key, value) {
      if (!value!.isEmpty) {
        value.forEach((element) {
          if( dateToMilliseconds(element[1]) > todayMidNightMillisecondsSinceEpoch) {
            todaymachineScopyTime[key]!.add(element);
          }
        });
      }
    });
    print ('todayMachineScopyTime:$todaymachineScopyTime');

    selectedIndexOfWasherChangeList.forEach((key, value) {
      selectedIndexOfWasherChangeList[key] = machineWasherChange[key]!.length-1;
    });
  }

  Future<void> saveMachineWasherChangeToFirestore(Map<String, List<dynamic>?> machineWasherChange) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // 각 기계별로 반복
      machineWasherChange.forEach((machineName, changes) async {
        var machineRef = firestore.collection('machines').doc(machineName);
        var washerChangesRef = machineRef.collection('washerChanges');

        // 기존 세척액 변경 기록 삭제 (선택적)
        var snapshots = await washerChangesRef.get();
        for (var doc in snapshots.docs) {
          await doc.reference.delete();
        }

        // 새로운 세척액 변경 기록 추가
        changes?.forEach((changeDate) async {
          await washerChangesRef.add({
            'changeDate': changeDate, // '2024-03-01 00:00' 형태의 날짜 문자열
          });
        });
      });

      print('Machine washer change data successfully saved to Firestore.');
    } catch (e) {
      print('Error saving machine washer change data to Firestore: $e');
    }
  }



  Future<void> saveDataToFirestore(Map<String, List<dynamic>?> data) async {
    final firestore = FirebaseFirestore.instance;

    try {
      WriteBatch batch = firestore.batch();

      data.forEach((machine, records) {
        var machineRef = firestore.collection('machines').doc(machine);

        records!.asMap().forEach((index, record) {
          // 각 레코드를 문서로 변환합니다.
          var docRef = machineRef.collection('records').doc('${record[0]}_${record[1]}');
          Map<String, dynamic> recordData = {
            '일련번호': record[0].toString(),
            '날짜-시간': record[1].toString(),
          };
          batch.set(docRef, recordData);
        });
      });

      // 모든 변경사항을 한 번에 커밋합니다.
      await batch.commit();
      print('Data successfully saved to Firestore.');
    } catch (e) {
      print('Error saving data to Firestore: $e');
    }
  }


  void _store(String machineName, String scopy, String appBarDate) async {

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
      if (_isPressedMachine && _isPressedScopy) {
        final currentTime = currentTimeToformattedForm();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        setState(() {
          todaymachineScopyTime[machineName]!.add([scopy, currentTime]);
        });
        machineScopyTime[machineName]!.add([scopy, currentTime]);

        final Map<String, List<dynamic>?>sortedmachineScopyTime = {};
        machineScopyTime.forEach((key, value) {
          sortedmachineScopyTime[key] = sortDataByDateTime(value!);
        });

        await prefs.setString('machineScopyTime', jsonEncode(sortedmachineScopyTime));
        await saveDataToFirestore(sortedmachineScopyTime);

        print(machineScopyTime);
      }
    } else {
      final TimeOfDay initialTime = TimeOfDay(hour: 9, minute: 0);
      final TimeOfDay? picked = await showTimePicker(context: context, initialTime: initialTime);
      DateTime date = DateTime.parse(appBarDate);
      DateTime otherDateAndTime = DateTime(
        date.year, date.month, date.day, picked!.hour, picked.minute
      );
      String otherDateAndTimeFormattedForm = DateFormat('yyyy-MM-dd HH:mm').format(otherDateAndTime);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        machineScopyTime[machineName]!.add([scopy, otherDateAndTimeFormattedForm]);
      });
      final Map<String, List<dynamic>?>sortedmachineScopyTime = {};
      machineScopyTime.forEach((key, value) {
        sortedmachineScopyTime[key] = sortDataByDateTime(value!);
      });


      await prefs.setString('machineScopyTime', jsonEncode(sortedmachineScopyTime));
      await saveDataToFirestore(sortedmachineScopyTime);

    }

  }

  void deleteItemFromFirestore(String machineName, List<dynamic> scopyTime) async {
    final firestore = FirebaseFirestore.instance;
    String docId = '${scopyTime[0]}_${scopyTime[1]}'; // 고유 ID 생성 방식이 데이터에 맞게 조정되어야 합니다.

    try {
      await firestore.collection('machines').doc(machineName).collection('records').doc(docId).delete();
      print('Document successfully deleted.');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }


  void _storeAfterDeleteOrEdit(machineName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('machineScopyTime', jsonEncode(machineScopyTime));


    setState(() {
      final String =  machineScopyTime[machineName]![0];
    });
  }

  void deleteItem(String machineName, List endoscopyTime) {
    setState(() {
      machineScopyTime[machineName]!.remove(endoscopyTime);
    });
  }

  Future<void> makingExcelFileforEachWashingMachineReport(String machineName, String washerChangeDate ) async {

    final List scopyAndTimeList = listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate(machineName, washerChangeDate);
    print ('haha:$scopyAndTimeList');

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
    todaymachineScopyTime.forEach((key, value) {
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

    todaymachineScopyTime.forEach((key, value) {
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
    final jsonData = json.encode(machineScopyTime);
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
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
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'machineWasherChange', jsonEncode(machineWasherChange));
          await saveMachineWasherChangeToFirestore(machineWasherChange);
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
                          print ('value:$value');
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
      //locale: const Locale('ko', 'KR'),
    );
    if (picked != null && !machineWasherChange[machineName]!.contains(DateFormat('yyyy-MM-dd').format(picked))) {
      setState(() {
        print ('picked:$picked');
        machineWasherChange[machineName]![index]= DateFormat('yyyy-MM-dd').format(picked);
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('machineWasherChange', jsonEncode(machineWasherChange));
      print ('machineWasherChange:$machineWasherChange');
    }
  }

  Future<void> _deleteMachineWasherChangeDate(String machineName, String changeDate) async {
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

      print('Machine washer change date successfully deleted from Firestore.');
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

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('machineWasherChange', jsonEncode(machineWasherChange));
  }

  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // 초기 선택된 날짜
      firstDate: DateTime(2000), // 선택 가능한 가장 이른 날짜
      lastDate: DateTime(2025), // 선택 가능한 가장 늦은 날짜
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked; // 선택된 날짜로 상태 업데이트
      });
    }
  }

  List<dynamic> sortDataByDateTime(List<dynamic> data) {
    data.sort((a, b) {
      DateTime dateTimeA = DateFormat('yyyy-MM-dd HH:mm').parse(a[1]);
      DateTime dateTimeB = DateFormat('yyyy-MM-dd HH:mm').parse(b[1]);
      return dateTimeA.compareTo(dateTimeB);
    });
    return data;
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
    if (machineScopyTime[machineName] != null) {
      for (List element in machineScopyTime[machineName]!) {
        if (indexOfWasherDate+1 == machineWasherChange[machineName]!.length) {
          if (compareDatesAndAddIfLater(washerChangeDate, element[1])) {
            tempList.add(element);
          }
        } else {
          if (compareDatesAndAddIfLater(washerChangeDate, element[1]) && !compareDatesAndAddIfLater(machineWasherChange[machineName]![indexOfNextWasherDate], element[1])) {
            tempList.add(element);
          }
        }
      }

    }
    return tempList;
  }




  @override
  Widget build(BuildContext context) {

    void onEdit(String newName, String newDate, List<dynamic> oldScopyTimeList, String machineName) {

      // 기존 항목을 찾아 수정
      List? scopyList = machineScopyTime[machineName];

      int indexForEntire = scopyList?.indexOf(oldScopyTimeList) ?? -1;
      if(indexForEntire != -1) {
        setState(() {
          machineScopyTime[machineName]![indexForEntire] = [newName, newDate];
        });
      }
      List? todayScopyList = todaymachineScopyTime[machineName];
      int indexForToday = todayScopyList?.indexOf(oldScopyTimeList) ?? -1;
      if(indexForToday != -1) {
        setState(() {
          todaymachineScopyTime[machineName]![indexForToday] = [newName, newDate];
        });
      }


    }

    final DateFormat DateFormatForAppBarDate = DateFormat('yyyy-MM-dd');

    final String formattedDateForAppBar = DateFormatForAppBarDate.format(selectedDate);
    final String formattedToday = DateFormatForAppBarDate.format(DateTime.now());
    final String appBarDate = (formattedToday == formattedDateForAppBar) ? 'Today' : formattedDateForAppBar;

    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ko', 'KR'), // 한국어 설정
      ],
      home: Scaffold(
        appBar: AppBar(
          title: Text(
              '안성성모 내시경센터',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => _selectDate(context),
              child: Text(
                appBarDate,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,// AppBar의 배경색과 맞추기 위한 텍스트 색상
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white54,
                side: BorderSide(color:Colors.orange),
              ),
            ),
            IconButton(
              icon: Icon(Icons.mail), // 우편 모양의 아이콘
              onPressed: () => showEmailDialog(context), // _sendEmail 함수 또는 해당 기능을 호출
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: SingleChildScrollView(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    endoscopyButton(
                        onPressed: () => _onPressedScopy(39, '039'),
                        text: '039',
                        isSelected: _isPressedScopy && _selectedIndexScopy == 39,
                    ),
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(73, '073'),
                      text: '073',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 73,
                    ),
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(98, '098'),
                      text: '098',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 98,
                    ),
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(166, '166'),
                      text: '166',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 166,
                    ),
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(180, '180'),
                      text: '180',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 180,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(256, '256'),
                      text: '256',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 256,
                    ),
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(257, '257'),
                      text: '257',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 257,
                    ),
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(259, '259'),
                      text: '259',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 259,
                    ),
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(333, '333'),
                      text: '333',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 333,
                    ),
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(379, '379'),
                      text: '379',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 379,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(390, '390'),
                      text: '390',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 390,
                    ),
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(405, '405'),
                      text: '405',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 405,
                    ),
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(407, '407'),
                      text: '407',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 407,
                    ),
                    endoscopyButton(
                      onPressed: () => _onPressedScopy(515, '515'),
                      text: '515',
                      isSelected: _isPressedScopy && _selectedIndexScopy == 515,
                    ),
                  ],
                ),

                // const Divider(
                //   color: Colors.black,
                //   height: 20.0,
                // ),

                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _store(selectedMachineName, selectedScopyName, appBarDate),
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
                    // Expanded(
                    //   flex: 1, // 이 비율로 '메일 보내기' 버튼이 화면의 20%를 차지합니다.
                    //   child: ElevatedButton(
                    //     onPressed: _sendEmail,
                    //     child: Text('날짜'),
                    //     style: ButtonStyle(
                    //       shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    //         RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.zero, // 모서리를 둥글지 않게 설정
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
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
                          scopyTime: displayTodayOrNot['1호기']!? todaymachineScopyTime['1호기']! : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('1호기', machineWasherChange['1호기']![selectedIndexOfWasherChangeList['1호기']!]),
                          machineName: '1호기',
                          onEdit : onEdit,
                          onDelete: (String machineName, List scopyTime) async {
                            deleteItemFromFirestore(machineName, scopyTime);
                            setState(() {
                              todaymachineScopyTime[machineName]!.remove(scopyTime);
                              machineScopyTime[machineName]!.remove(scopyTime);
                            });
                            _storeAfterDeleteOrEdit(machineName);
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
                          scopyTime: displayTodayOrNot['2호기']!? todaymachineScopyTime['2호기']! :listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('2호기', machineWasherChange['2호기']![selectedIndexOfWasherChangeList['2호기']!]),
                          machineName: '2호기',
                            onEdit : onEdit,
                            onDelete: (String machineName, List scopyTime) async {
                              deleteItemFromFirestore(machineName, scopyTime);
                              setState(() {
                                todaymachineScopyTime[machineName]!.remove(scopyTime);
                                machineScopyTime[machineName]!.remove(scopyTime);
                              });
                              _storeAfterDeleteOrEdit(machineName);
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
                          scopyTime: displayTodayOrNot['3호기']!? todaymachineScopyTime['3호기']! : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('3호기', machineWasherChange['3호기']![selectedIndexOfWasherChangeList['3호기']!]),
                          machineName: '3호기',
                            onEdit : onEdit,
                            onDelete: (String machineName, List scopyTime) async {
                              deleteItemFromFirestore(machineName, scopyTime);
                              setState(() {
                                todaymachineScopyTime[machineName]!.remove(scopyTime);
                                machineScopyTime[machineName]!.remove(scopyTime);
                              });
                              _storeAfterDeleteOrEdit(machineName);
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
                            scopyTime: displayTodayOrNot['4호기']!? todaymachineScopyTime['4호기']! : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('4호기', machineWasherChange['4호기']![selectedIndexOfWasherChangeList['4호기']!]),
                            machineName: '4호기',
                            onEdit : onEdit,
                            onDelete: (String machineName, List scopyTime) async {
                              deleteItemFromFirestore(machineName, scopyTime);
                              setState(() {
                                todaymachineScopyTime[machineName]!.remove(scopyTime);
                                machineScopyTime[machineName]!.remove(scopyTime);
                              });
                              _storeAfterDeleteOrEdit(machineName);
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
                            scopyTime: displayTodayOrNot['5호기']!? todaymachineScopyTime['5호기']! : listOfEndoscopyForEachMachineAfterSpecificWasherChangeDate('5호기', machineWasherChange['5호기']![selectedIndexOfWasherChangeList['5호기']!]),
                            machineName: '5호기',
                            onEdit : onEdit,
                            onDelete: (String machineName, List scopyTime) async {
                              deleteItemFromFirestore(machineName, scopyTime);
                              setState(() {
                                todaymachineScopyTime[machineName]!.remove(scopyTime);
                                machineScopyTime[machineName]!.remove(scopyTime);
                              });
                              _storeAfterDeleteOrEdit(machineName);
                            }
                        ),
                      ],
                    ))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget endoscopyForEachMachineWidget({
  //required Map<String, List?> machineScopyTime,
  required List scopyTime,
  required String machineName,
  required Function onDelete,
  required Function(String, String, List<dynamic>, String) onEdit,
}) {
  if (machineScopyTime[machineName]!.isEmpty) {
    return const SizedBox();
  }



  return Column(
    children: scopyTime.map((e) {
      return MyButton(
        machineName : machineName,
        scopyTimeList: e,
        onPressed: () => onDelete(machineName, e),
        onEdit:onEdit,
      );
    }).toList(),

  );
}


class MyButton extends StatelessWidget {
  final String machineName;
  final List scopyTimeList;
  final VoidCallback onPressed;
  final Function(String, String, List<dynamic>, String) onEdit;

  MyButton({
    required this.machineName,
    required this.scopyTimeList,
    required this.onPressed,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {

    DateFormat dateFormatHHmmInMyButton = DateFormat('HH:mm');
    final dateAsHHmm =  scopyTimeList[1].substring(11);
    final dateAsyyDDmm = DateFormat('yy/MM/dd').format(DateTime.parse(scopyTimeList[1]));


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
            builder: (context) => EditDialog(scopyTimeList:scopyTimeList),
        );

        if(result != null) {
          print ('${result[0]}/${result[1]}');
          print (result[1].runtimeType);
          onEdit(result[0], result[1], scopyTimeList, machineName);
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
                scopyTimeList[0],
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),

            ),
            Text((dateAsHHmm))
          ] : [
            Text(
                scopyTimeList[0],
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
            ),
            Text(dateAsyyDDmm),
            Text(dateAsHHmm)
          ],
        )
      ),
    );
  }
}

class EditDialog extends StatefulWidget {
  final List scopyTimeList;

  EditDialog({required this.scopyTimeList});

  @override
  _EditDialogState createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _timeController = TextEditingController();
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scopyTimeList[0]);
    //_timeController = TextEditingController(text: DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(widget.scopyTimeList[1]).toUtc()));
    DateFormat format = DateFormat('yyyy-MM-dd HH:mm');
    DateTime initialTime = format.parse(widget.scopyTimeList[1]);
    _selectedTime = TimeOfDay(hour: initialTime.hour, minute: initialTime.minute);
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
              print ('newTime:$newTime');
              print ('EditDialog:${newTime.millisecondsSinceEpoch}');
              Navigator.of(context).pop([newName, DateFormat('yyyy-MM-dd HH:mm').format(newTime)]);
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