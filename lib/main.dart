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


late Map<String, List<dynamic>?> machineScopyTime = {'1호기':[], '2호기':[], '3호기':[], '4호기':[], '5호기':[]};
late Map<String, List<dynamic>?> todaymachineScopyTime = {'1호기':[], '2호기':[], '3호기':[], '4호기':[], '5호기':[]};
late Map<String, List<dynamic>?> machineWasherChange =
  {'1호기':['2024-03-01'], '2호기':['2024-03-01'], '3호기':['2024-03-01'], '4호기':['2024-03-01'], '5호기':['2024-03-01']};
//late Map<String, List<dynamic>?> machineWasherChange = {'1호기':[], '2호기':[], '3호기':[], '4호기':[], '5호기':[]};

void main() {
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

  
  Map<String, String> scopyFullName = {'039':'7C692K039', '073':'KG391K073', '098':'5C692K098', '166':'6C692K166',
    '180':'5G391K180', '256':'7G391K257', '257':'7G391k257', '259':'7G391K259', '333':'2G348K333', '379':'1C665K379', '390':'2G348K390',
    '405':'2G348K405', '407':'2G348K407', '515':'1C666K515'};

  int timeAsEpoch = 0;
      // '${DateTime.now().toUtc().add(Duration(hours: 9)).toString().substring(0, 19)}';

  DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  DateFormat dateFormatHHmm = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String testFunc(int milliSeconds) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(milliSeconds);

    // 월과 날짜를 추출합니다.
    int month = dateTime.month;
    int day = dateTime.day;

    return month.toString() + '/' + day.toString();

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

    DateTime today = DateTime.now();
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
  }



  void _store(String machineName, String scopy, String appBarDate) async {

    print ('appBarDate:$appBarDate');


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


    if (appBarDate == 'Today') {
      if (_isPressedMachine && _isPressedScopy) {
        final currentTime = currentTimeToformattedForm();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        setState(() {
          todaymachineScopyTime[machineName]!.add([scopy, currentTime]);
        });
        machineScopyTime[machineName]!.add([scopy, currentTime]);

        //await prefs.setString('machineScopyTime', machineScopyTime.toString());
        await prefs.setString('machineScopyTime', jsonEncode(machineScopyTime));
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
      print (machineScopyTime);

    }

  }



  void _storeAfterDeleteOrEdit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('machineScopyTime', jsonEncode(machineScopyTime));
  }

  void deleteItem(String machineName, List endoscopyTime) {
    setState(() {
      machineScopyTime[machineName]!.remove(endoscopyTime);
    });
  }

  Future<void> makingExcelFileforEachWashingMachineReport( int machineNum ) async {

    final machine = machineNum;
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
    worksheet.getRangeByName('A2').setText('세척기${machine}호');
    worksheet.getRangeByName('A2').cellStyle.fontSize=10;

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



  Future<void> _sendEmail() async {
    final jsonData = json.encode(machineScopyTime);
    Directory? appDirectory = await getApplicationDocumentsDirectory();
    makingExcelFileforDailyWashingMachineReport();
    final String formattedToday = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final email = Email(
      body: jsonData,
      subject: '데일리내시경세척리포트($formattedToday)',
      recipients: ['alienpro@naver.com', '19030112@bizmeka.com'],
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
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2025),
        //locale: const Locale('ko', 'KR'),
    );
    if (picked != null && !machineWasherChange[machineName]!.contains(DateFormat('yyyy-MM-dd').format(picked))) {
      setState(() {
        machineWasherChange[machineName]!.add(DateFormat('yyyy-MM-dd').format(picked));
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('machineWasherChange', jsonEncode(machineWasherChange));
      print ('machineWasherChange:$machineWasherChange');
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
                      title: Text(
                        DateFormat('yy/MM/dd').format(DateFormat('yyyy-MM-dd').parse(machineWasherChange[machineName]![index]))+'\n(80)'
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _updateMachineWasherChangeDate(context, machineName, index, setState),
                            icon: Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _deleteMachineWasherChangeDate(machineName, index, setState);
                              });
                            },
                            icon: Icon(Icons.delete),
                          ),
                          IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.mail),
                          )
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
        machineWasherChange[machineName]![index]= DateFormat('yyyy-MM-dd').format(picked);
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('machineWasherChange', jsonEncode(machineWasherChange));
      print ('machineWasherChange:$machineWasherChange');
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
          title: Text('안성성모 내시경센터'),
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
              onPressed: () {}, // _sendEmail 함수 또는 해당 기능을 호출
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
                        child: machineButton(index: 2, machineName: '2호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine)
                    ),
                    Expanded(child: SizedBox()),
                    Expanded(
                        child: machineButton(index: 3, machineName: '3호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine)
                    ),
                ]),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(child: SizedBox()),
                    Expanded(
                    child: machineButton(index: 4, machineName: '4호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine),
                    ),
                    Expanded(child: SizedBox()),
                    Expanded(
                      child: machineButton(index: 5, machineName: '5호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine),
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
                const Divider(
                  color: Colors.black,
                  height: 20.0,
                ),

                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 4, // 이 비율로 '저장' 버튼이 화면의 80%를 차지합니다.
                      child: ElevatedButton(
                        onPressed: () => _store(selectedMachineName, selectedScopyName, appBarDate),
                        child: Text('저장'),
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero, // 모서리를 둥글지 않게 설정
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1, // 이 비율로 '메일 보내기' 버튼이 화면의 20%를 차지합니다.
                      child: ElevatedButton(
                        onPressed: _sendEmail,
                        child: Text('날짜'),
                        style: ButtonStyle(
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
                    ElevatedButton(
                        onPressed: ()=>makingExcelFileforEachWashingMachineReport(2),
                        child: Text('엑셀파일2'))
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
                          scopyCount: machineScopyTime['1호기']?.length ?? 0, // Null Safety 처리
                          onPressed: () => _showWasherRecord(context, '1호기'),
                          // 날짜가 없는 경우 기본값 사용
                          lastChangeDate: machineWasherChange['1호기']?.isNotEmpty == true ? machineWasherChange['1호기']!.last.substring(5) : '03-01',

                        ),
                        endoscopyForEachMachineWidget(
                          machineScopyTime: todaymachineScopyTime,
                          machineName: '1호기',
                          onEdit : onEdit,
                          onDelete: (String machineName, List scopyTime) {
                            setState(() {
                              todaymachineScopyTime[machineName]!.remove(scopyTime);
                              machineScopyTime[machineName]!.remove(scopyTime);
                            });
                            _storeAfterDeleteOrEdit();
                          }
                        ),
                      ],
                    )),
                    Expanded(child: Column(
                      children: [
                        WasherRecordButton(
                          machineName: '2호기',
                          scopyCount: machineScopyTime['2호기']?.length ?? 0, // Null Safety 처리
                          onPressed: () => _showWasherRecord(context, '2호기'),
                          // 날짜가 없는 경우 기본값 사용
                          lastChangeDate: machineWasherChange['2호기']?.isNotEmpty == true ? machineWasherChange['2호기']!.last.substring(5) : '03-01',

                        ),
                        endoscopyForEachMachineWidget(
                          machineScopyTime: todaymachineScopyTime,
                          machineName: '2호기',
                            onEdit : onEdit,
                            onDelete: (String machineName, List scopyTime) {
                              setState(() {
                                todaymachineScopyTime[machineName]!.remove(scopyTime);
                                machineScopyTime[machineName]!.remove(scopyTime);
                              });
                              _storeAfterDeleteOrEdit();
                            }
                        ),
                      ],
                    )),
                    Expanded(child: Column(
                      children: [
                        WasherRecordButton(
                          machineName: '3호기',
                          scopyCount: machineScopyTime['3호기']?.length ?? 0, // Null Safety 처리
                          onPressed: () => _showWasherRecord(context, '3호기'),
                          // 날짜가 없는 경우 기본값 사용
                          lastChangeDate: machineWasherChange['3호기']?.isNotEmpty == true ? machineWasherChange['3호기']!.last.substring(5) : '03-01',

                        ),
                        endoscopyForEachMachineWidget(
                          machineScopyTime: todaymachineScopyTime,
                          machineName: '3호기',
                            onEdit : onEdit,
                            onDelete: (String machineName, List scopyTime) {
                              setState(() {
                                todaymachineScopyTime[machineName]!.remove(scopyTime);
                                machineScopyTime[machineName]!.remove(scopyTime);
                              });
                              _storeAfterDeleteOrEdit();
                            }
                        ),
                      ],
                    )),
                    Expanded(child: Column(
                      children: [
                        WasherRecordButton(
                          machineName: '4호기',
                          scopyCount: machineScopyTime['4호기']?.length ?? 0, // Null Safety 처리
                          onPressed: () => _showWasherRecord(context, '4호기'),
                          // 날짜가 없는 경우 기본값 사용
                          lastChangeDate: machineWasherChange['4호기']?.isNotEmpty == true ? machineWasherChange['4호기']!.last.substring(5) : '03-01',

                        ),
                        endoscopyForEachMachineWidget(
                          machineScopyTime: todaymachineScopyTime,
                          machineName: '4호기',
                            onEdit : onEdit,
                            onDelete: (String machineName, List scopyTime) {
                              setState(() {
                                todaymachineScopyTime[machineName]!.remove(scopyTime);
                                machineScopyTime[machineName]!.remove(scopyTime);
                              });
                              _storeAfterDeleteOrEdit();
                            }
                        ),
                      ],
                    )),
                    Expanded(child: Column(
                      children: [
                        WasherRecordButton(
                          machineName: '5호기',
                          scopyCount: machineScopyTime['5호기']?.length ?? 0, // Null Safety 처리
                          onPressed: () => _showWasherRecord(context, '5호기'),
                          // 날짜가 없는 경우 기본값 사용
                          lastChangeDate: machineWasherChange['5호기']?.isNotEmpty == true ? machineWasherChange['5호기']!.last.substring(5) : '03-01',

                        ),
                        endoscopyForEachMachineWidget(
                          machineScopyTime: todaymachineScopyTime,
                          machineName: '5호기',
                            onEdit : onEdit,
                            onDelete: (String machineName, List scopyTime) {
                              setState(() {
                                todaymachineScopyTime[machineName]!.remove(scopyTime);
                                machineScopyTime[machineName]!.remove(scopyTime);
                              });
                              _storeAfterDeleteOrEdit();
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
  required Map<String, List?> machineScopyTime,
  required String machineName,
  required Function onDelete,
  required Function(String, String, List<dynamic>, String) onEdit,
}) {
  if (machineScopyTime[machineName]!.isEmpty) {
    return const SizedBox();
  }



  return Column(
    children: machineScopyTime[machineName]!.map((e) {
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
          ),
        child : Column(
          children: [
            Text(scopyTimeList[0]),
            Text((dateAsHHmm))
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