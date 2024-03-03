import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'dart:io';
import 'package:intl/intl.dart';

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
  late Map<String, List<dynamic>?> machineScopyTime = {'1호기':[], '2호기':[], '3호기':[], '4호기':[], '5호기':[]};
  Map<String, String> scopyFullName = {'039':'7C692K039', '073':'KG391K073', '098':'5C692K098', '166':'6C692K166',
    '180':'5G391K180', '256':'7G391K257', '259':'7G391K259', '333':'2G348K333', '379':'1C665K379', '390':'2G348K390',
    '405':'2G348K405', '407':'2G348K407', '515':'1C666K515'};

  String _currentTime ="";
  int timeAsEpoch = 0;
      // '${DateTime.now().toUtc().add(Duration(hours: 9)).toString().substring(0, 19)}';

  late Timer _timer;
  DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  DateFormat dateFormatHHmm = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _loadDate();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime =
            '${DateTime.now().toUtc().add(Duration(hours: 9)).toString().substring(0, 19)} ';
        timeAsEpoch = DateTime.now().millisecondsSinceEpoch+9 * 60 * 60 * 1000;
      });
    });
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

  void _loadDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('machineScopyTime');

    if (jsonString != null) {
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      setState(() {
        machineScopyTime = jsonMap.map((key, value) =>
            MapEntry(key, List<dynamic>.from(value as List<dynamic>? ?? [])));
      });
    }
  }

  void _store(String machineName, List scopyAndTime) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    machineScopyTime[machineName]!.add(scopyAndTime);
    //await prefs.setString('machineScopyTime', machineScopyTime.toString());
    await prefs.setString('machineScopyTime', jsonEncode(machineScopyTime));
    print(machineScopyTime);
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
    machineScopyTime.forEach((key, value) {
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

    machineScopyTime.forEach((key, value) {
      if (value!.length >0 ) {
        for (int i = 0; i < value.length; i++) {
          worksheet.getRangeByName('${alphabetList[int.parse(key[0])]}${i + 3}').cellStyle = globalstyle;
          final scopyName =  scopyFullName[value[i][0]];
          final timeAsHHmm = dateFormatHHmm.format(DateTime.fromMillisecondsSinceEpoch(value[i][1]).toUtc());
          worksheet.getRangeByName('${alphabetList[int.parse(key[0])]}${i + 3}')
              .setText('$scopyName \n (${timeAsHHmm.toString()})');

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

    final email = Email(
      body: jsonData,
      subject: '내시경 검사 정보!',
      recipients: ['alienpro@naver.com', '19030112@bizmeka.com'],
      attachmentPaths: ['${appDirectory.path}/test.xlsx'],
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

  void currentTime() {
    final DateTime dateTime2 = DateTime.now();
    int secondsEpoch =dateTime2.millisecondsSinceEpoch;
    print (secondsEpoch);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("안성성모 내시경센터"),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: SingleChildScrollView(
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _onPressedMachine(1, "1호기"),
                      child: Text('1호기'),
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            side: BorderSide(
                                width: 2.0,
                                color:
                                    _isPressedMachine && _selectedIndexMachine == 1
                                        ? Colors.blue
                                        : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child:
                    ElevatedButton(
                      onPressed: () => _onPressedMachine(2, "2호기"),
                      child: Text('2호기'),
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            side: BorderSide(
                                width: 2.0,
                                color:
                                _isPressedMachine && _selectedIndexMachine == 2
                                    ? Colors.blue
                                    : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                    
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _onPressedMachine(3, "3호기"),
                      child: Text('3호기'),
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            side: BorderSide(
                                width: 2.0,
                                color:
                                    _isPressedMachine && _selectedIndexMachine == 3
                                        ? Colors.blue
                                        : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _onPressedMachine(4, "4호기"),
                      child: Text('4호기'),
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            side: BorderSide(
                                width: 2.0,
                                color:
                                    _isPressedMachine && _selectedIndexMachine == 4
                                        ? Colors.blue
                                        : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _onPressedMachine(5, "5호기"),
                      child: Text('5호기'),
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            side: BorderSide(
                                width: 2.0,
                                color:
                                    _isPressedMachine && _selectedIndexMachine == 5
                                        ? Colors.blue
                                        : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(
                color: Colors.black,
                height: 3.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(39, "039"),
                    child: Text('039'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 39
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(73, "073"),
                    child: Text('073'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 73
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(98, "098"),
                    child: Text('098'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 98
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(166, "166"),
                    child: Text('166'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 166
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(180, "180"),
                    child: Text('180'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 180
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(256, "256"),
                    child: Text('256'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 256
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(257, "257"),
                    child: Text('257'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 257
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                      onPressed: () => _onPressedScopy(259, "259"),
                      child: Text('259'),
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            side: BorderSide(
                                width: 2.0,
                                color: _isPressedScopy && _selectedIndexScopy == 259
                                    ? Colors.red
                                    : Colors.grey),
                          ),
                        ),
                      ),
                  ),
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(333, "333"),
                    child: Text('333'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 333
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(379, "379"),
                    child: Text('379'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 379
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(390, "390"),
                    child: Text('390'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 390
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(405, "405"),
                    child: Text('405'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 405
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(407, "407"),
                    child: Text('407'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 407
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _onPressedScopy(515, "515"),
                    child: Text('515'),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          side: BorderSide(
                              width: 2.0,
                              color: _isPressedScopy && _selectedIndexScopy == 515
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(
                color: Colors.black,
                height: 3.0,
              ),
              Row(
                children: <Widget>[
                  ElevatedButton(
                      onPressed: currentTime,
                      child:
                      Text(
                          '현재 시간: ${ dateFormat.format(DateTime.fromMillisecondsSinceEpoch(timeAsEpoch).toUtc().add(const Duration(hours: 9))) }'
                      ),
                      //child: Text('현재 시간: $_currentTime'))
                  ),
                ],
              ),
              const Divider(
                color: Colors.black,
                height: 3.0,
              ),
              Row(
                children: <Widget>[
                  ElevatedButton(
                      onPressed:()=> _store(selectedMachineName, [selectedScopyName, timeAsEpoch]),
                      child: Text('저장')),
                  ElevatedButton(onPressed: _sendEmail, child: Text('메일 보내기')),
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
                      Text('1호기'),
                      endoscopyForEachMachineWidget(
                        machineScopyTime: machineScopyTime,
                        machineName: '1호기',
                      ),
                    ],
                  )),
                  Expanded(child: Column(
                    children: [
                      Text('2호기'),
                      endoscopyForEachMachineWidget(
                        machineScopyTime: machineScopyTime,
                        machineName: '2호기',
                      ),
                    ],
                  )),
                  Expanded(child: Column(
                    children: [
                      Text('3호기'),
                      endoscopyForEachMachineWidget(
                        machineScopyTime: machineScopyTime,
                        machineName: '3호기',
                      ),
                    ],
                  )),
                  Expanded(child: Column(
                    children: [
                      Text('4호기'),
                      endoscopyForEachMachineWidget(
                        machineScopyTime: machineScopyTime,
                        machineName: '4호기',
                      ),
                    ],
                  )),
                  Expanded(child: Column(
                    children: [
                      Text('5호기'),
                      endoscopyForEachMachineWidget(
                        machineScopyTime: machineScopyTime,
                        machineName: '5호기',
                      ),
                    ],
                  ))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

Widget endoscopyForEachMachineWidget({
  required Map<String, List?> machineScopyTime,
  required String machineName,
}) {
  if (machineScopyTime[machineName]!.isEmpty) {
    return const SizedBox();
  }

  return Column(
    children: machineScopyTime[machineName]!.map((e) {
      return MyButton(
        machineTimeList: e,
        onPressed: () {},
      );
    }).toList(),

  );
}


class MyButton extends StatelessWidget {
  final List machineTimeList;
  final VoidCallback onPressed;

  MyButton({required this.machineTimeList, required this.onPressed});




  @override
  Widget build(BuildContext context) {

    DateFormat dateFormatHHmmInMyButton = DateFormat('HH:mm');
    final dateAsHHmm =  dateFormatHHmmInMyButton.format(DateTime.fromMillisecondsSinceEpoch(machineTimeList[1]).toUtc());

    return GestureDetector(
      onTap: onPressed,
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
            Text(machineTimeList[0]),
            Text((dateAsHHmm))
          ],
        )
      ),
    );
  }
}

