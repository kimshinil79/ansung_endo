// import 'dart:convert';
import 'package:ansung_endo/widgets/endoscopy_button.dart';
import 'package:ansung_endo/widgets/washer_record_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
// import 'dart:io';
import 'package:intl/intl.dart';
import '../widgets/machine_button.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';



List<String> machines = ['1호기', '2호기', '3호기', '4호기', '5호기'];
late Map<String, List<dynamic>?> machineScopyTimePtName = {'1호기':[], '2호기':[], '3호기':[], '4호기':[], '5호기':[]};
late Map<String, List<dynamic>?> todaymachineScopyTimePtName = {'1호기':[], '2호기':[], '3호기':[], '4호기':[], '5호기':[]};
Map<String, List<String>> machineWasherChange =
{'1호기':['2000-01-01 00:00'], '2호기':['2000-01-01 00:00'], '3호기':['2000-01-01 00:00'], '4호기':['2000-01-01 00:00'], '5호기':['2000-01-01 00:00']};
late Map<String, int> selectedIndexOfWasherChangeList = {'1호기':0, '2호기':0, '3호기':0, '4호기':0, '5호기':0};
late Map<String, bool> displayTodayOrNot = {'1호기':true, '2호기':true, '3호기':true, '4호기':true, '5호기':true};
late String emailAdress = "";
bool noPatient = false;

class WashingRoom extends StatefulWidget {
  //MyHomePage({Key key}) : super(key: key);

  //final String title;

  @override
  _WashingRoomState createState() => _WashingRoomState();
}

class _WashingRoomState extends State<WashingRoom> {

  bool _isPressedMachine = false;
  bool _isPressedScopy = false;
  bool endoscopySelection = false;
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
  Map<String, String> GSFmachine = {'073':'KG391K073', '180':'5G391K180', '153':'5G391K153','256':'7G391K256','257':'7G391k257',
    '259':'7G391K259','407':'2G348K407', '405':'2G348K405','390':'2G348K390', '333':'2G348K333', '694':'5G348K694'};
  Map<String, String> CSFmachine = {'039':'7C692K039', '166':'6C692K166', '098':'5C692K098', '219':'1C664K219', '379':'1C665K379', '515':'1C666K515',};

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

    List<bool> isSelected = List.generate(scopyShortName.length, (_) => false);
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

  Future<void> _onPressedScopy(String scopyName) async {

    setState(() {
      if (selectedScopyName != scopyName) {
        selectedScopyName = scopyName;
        _isPressedScopy = true;
        endoscopySelection = true;
      } else {
        _isPressedScopy = !_isPressedScopy;
        endoscopySelection != endoscopySelection;
      }
    });
  }

  Map<String, String> sortMapByKey(Map<String, String> scopes) {

    // 맵을 엔트리 리스트로 변환
    var entries = scopes.entries.toList();

    // 리스트를 키 기준으로 오름차순 정렬
    entries.sort((a, b) => a.key.compareTo(b.key));

    // 정렬된 리스트를 다시 맵으로 변환
    Map<String, String> sortedGSFmachine = Map.fromEntries(entries);

    // 결과 출력

    return sortedGSFmachine;
  }

  Future<void> fetchScopes(String scopeType) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference docRef = await firestore.collection('scopes').doc(scopeType);

    docRef.get().then((DocumentSnapshot document) {
      if (document.exists) {
        setState(()  {
          if (scopeType == 'GSF') {
            GSFmachine = Map<String, String>.from(document.data() as Map<String, dynamic>);
            GSFmachine =  sortMapByKey(GSFmachine);
          } else if (scopeType == 'CSF') {
            CSFmachine = Map<String, String>.from(document.data() as Map<String, dynamic>);
            CSFmachine = sortMapByKey(CSFmachine);
            scopyShortName =  sortMapByKey({...GSFmachine, ...CSFmachine}).keys.toList();

        }
        });
      } else {
        print('No such document!');
      }
    }).catchError((error) {
      print("Error getting document: $error");
    });


  }

  int dateToMilliseconds (String dateString) {
    int milliseconds = 0;
    try {
      DateTime date = DateTime.parse(dateString);
      milliseconds = date.millisecondsSinceEpoch;
    } catch (e) {
      print ('dateToMilliseconds:$e');
    }

    return milliseconds;
  }

  String timeToformattedFormAsyyyyMMddHHmm(DateTime time) {
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(time);
    return formattedDate;
  }

  Future<void> _loadDataFromFirebase() async {
    final firestore = FirebaseFirestore.instance;

    await fetchScopes('GSF');
    await fetchScopes('CSF');
    setState(()  {
      scopyShortName =  sortMapByKey({...GSFmachine, ...CSFmachine}).keys.toList();
    });


    try {
      machineScopyTimePtName = {
        '1호기': [],
        '2호기': [],
        '3호기': [],
        '4호기': [],
        '5호기': [],
      };
      for (var machine in machines) {
        QuerySnapshot querySnapshotForGSFArray  = await firestore
            .collection('patients').where('위세척기계', arrayContains: machine).get();
        // QuerySnapshot querySnapshotForGSFString  = await firestore
        //     .collection('patients').where('위세척기계', isEqualTo: machine).get();
        // List<QueryDocumentSnapshot> totalquerySnapshots = [];
        // totalquerySnapshots.addAll(querySnapshotForGSFArray.docs);
        // totalquerySnapshots.addAll(querySnapshotForGSFString.docs);
        for (var doc in querySnapshotForGSFArray.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (doc['위내시경기계'] is List) {
            int indexOfMachine = data['위세척기계'].indexOf(machine);
            String gsfWashingTime = data['위내시경세척시간'][indexOfMachine];
            String scope = data['위내시경기계'][indexOfMachine];
            machineScopyTimePtName[machine]!.add({
              '일련번호': scope,
              '날짜-시간': gsfWashingTime,
              '환자이름': data['이름'],
              '환자id': data['id']
            });
          } else if (doc['위내시경기계'] is String) {
            machineScopyTimePtName[machine]!.add({
              '일련번호': doc['위내시경기계'],
              '날짜-시간': doc['위내시경세척시간'],
              '환자이름': data['이름'],
              '환자id': data['id']
            });
          }
        }

        QuerySnapshot querySnapshotForCSFArray = await firestore
            .collection('patients').where('대장세척기계', arrayContains: machine).get();
        // QuerySnapshot querySnapshotForCSFString  = await firestore
        //     .collection('patients').where('대장세척기계', isEqualTo: machine).get();
        // List<QueryDocumentSnapshot> totalquerySnapshots2 = [];
        // totalquerySnapshots2.addAll(querySnapshotForCSFArray.docs);
        // totalquerySnapshots2.addAll(querySnapshotForCSFString.docs);
        for (var doc in querySnapshotForCSFArray.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if(doc['대장내시경기계'] is List) {
            int indexOfMachine = data['대장세척기계'].indexOf(machine);
            String csfWashingTime = data['대장내시경세척시간'][indexOfMachine];
            String scope = data['대장내시경기계'][indexOfMachine];
            machineScopyTimePtName[machine]!.add({
              '일련번호': scope,
              '날짜-시간': csfWashingTime,
              '환자이름': data['이름'],
              '환자id': data['id']
            });
          } else if (doc['대장내시경기계'] is String) {
            machineScopyTimePtName[machine]!.add({
              '일련번호': doc['대장내시경기계'],
              '날짜-시간': doc['대장내시경세척시간'],
              '환자이름': data['이름'],
              '환자id': data['id']
            });
          }
        }
        try{
          QuerySnapshot querySnapshotForSigArray = await firestore
              .collection('patients').where('sig세척기계', isEqualTo: machine).get();
          for (var doc in querySnapshotForSigArray.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String sigWashingTime = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(data['sig세척시간']));
            String scope = data['sig기계'];
            machineScopyTimePtName[machine]!.add({
              '일련번호': scope,
              '날짜-시간': sigWashingTime,
              '환자이름': data['이름'],
              '환자id': data['id']
            });
          }
        } catch (e) {
          print ('zzzzzzzz:$e');
        }


      }
    } catch (e) {
      print ('환자 정보와 기계 정보 메치에 에러 발생:$e');
    }


      // 기계 별 세척액 변경 기록 가져오기
      QuerySnapshot washerChangeSnapshot = await firestore.collectionGroup('washerChanges').get();
      machineWasherChange = {
        '1호기':['2000-01-01 00:00'], '2호기':['2000-01-01 00:00'], '3호기':['2000-01-01 00:00'], '4호기':['2000-01-01 00:00'], '5호기':['2000-01-01 00:00']
      };
      for (QueryDocumentSnapshot doc in washerChangeSnapshot.docs) {
        String machineName = doc.reference.parent.parent!.id;
        String changeDate = doc.get('changeDate');
        machineWasherChange[machineName]!.add(changeDate);
      }


      for (var machine in machineWasherChange.keys.toList()) {
          machineWasherChange[machine] = sortwasherChangeByDateTime(machineWasherChange[machine]!);
      }


      // 초기 selectedIndexOfWasherChangeList 설정
      selectedIndexOfWasherChangeList.forEach((key, value) {
        selectedIndexOfWasherChangeList[key] = machineWasherChange[key]!.length - 1;
      });

      // todaymachineScopyTime 초기화
      _initializeTodaymachineScopyTimePtName();

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
      sortRecordsByDateTime(todaymachineScopyTimePtName[key]!);
    });
  }


  Future<void> updateMachineWasherChangeToFirestore(String machine, String oldWasherChangeDate, DateTime time) async {
    final firestore = FirebaseFirestore.instance;

    final changeDate = timeToformattedFormAsyyyyMMddHHmm(time);
    
    try {
      QuerySnapshot querySnapshot =  await firestore.collection('machines').doc(machine).collection('washerChanges').where('changeDate', isEqualTo:oldWasherChangeDate).get();
      for (var doc in querySnapshot.docs) {
        await firestore.collection('machines').doc(machine).collection('washerChanges').doc(doc.id).update({'changeDate':changeDate});
      }
      print('washer change date Data updated successfully!');
    } catch (e) {
      print('Error saving data to Firestore: $e');
    }
  }

  Future<void> saveMachineWasherChangeToFirestore(String machine, DateTime time) async {
    final firestore = FirebaseFirestore.instance;

    final changeDate = timeToformattedFormAsyyyyMMddHHmm(time);
    Map<String, String> data = {'changeDate' :changeDate};
    try {
      await firestore.collection('machines').doc(machine).collection('washerChanges').add(data);
      print('washer change date Data saved successfully!');
    } catch (e) {
      print('Error saving data to Firestore: $e');
    }
  }




  Future<void> saveMachineScopyTimePtIDToFirestore(String machine, Map<String, String> recordInfo, Map<String, dynamic> patientAndExamInformation) async {
    // Firestore 인스턴스 생성
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // 문서 이름 생성 ('machine_날짜-시간')
    String documentName = '${recordInfo['일련번호']}_${recordInfo['날짜-시간']}';

    try {
      // 'machine' 컬렉션 내 'machine' 문서의 'records' 서브컬렉션에
      // 'documentName' 이름으로 문서 생성 후 'recordInfo' Map 데이터 추가
      //await firestore.collection('machines').doc(machine).collection('records').doc(documentName).set(recordInfo);
      String id = patientAndExamInformation['id'];
      QuerySnapshot querySnapshot = await firestore.collection('patients').where('id', isEqualTo:id).get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          await firestore.collection('patients').doc(doc.id).update(patientAndExamInformation);
        }
      } else {
        String docName = patientAndExamInformation['이름']! + "_" + patientAndExamInformation['날짜']! + "_" + patientAndExamInformation['id']! ;
        await firestore.collection('patients').doc(docName).set(patientAndExamInformation);
      }

      print('Data saved successfully!');
    } catch (e) {
      print('Error saving data to Firestore: $e');
    }
  }


  void _store(String machineName, String scopy, Map<String, dynamic> patientAndExamInformation, String appBarDate) async {

    if ((patientAndExamInformation['위내시경기계'].contains(scopy) && patientAndExamInformation['위세척기계'].contains(machineName))
    || (patientAndExamInformation['대장내시경기계'].contains(scopy) && patientAndExamInformation['대장세척기계'].contains(machineName))
    ) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('경고'),
            content: Text('이미 입력된 정보입니다.'),
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

    if(noPatient) {
      patientAndExamInformation['id'] = generateUniqueId();
      patientAndExamInformation['이름'] = "없음";
      patientAndExamInformation['환자번호'] = "없음";
      patientAndExamInformation['성별'] = "없음";
      patientAndExamInformation['나이'] = "없음";
      patientAndExamInformation['Room'] = "없음";
      patientAndExamInformation['생일'] = "없음";
      patientAndExamInformation['의사'] = "없음";
      patientAndExamInformation['날짜'] = "";
      patientAndExamInformation['시간'] = "";
      patientAndExamInformation['위검진_외래'] = "없음";
      patientAndExamInformation['위수면_일반'] = "없음";
      patientAndExamInformation['위조직'] = "0";
      patientAndExamInformation['CLO'] = false;
      patientAndExamInformation['위절제술'] = "0";
      patientAndExamInformation['위응급'] = false;
      patientAndExamInformation['PEG'] = false;
      patientAndExamInformation['위내시경기계'] = [];
      patientAndExamInformation['위세척기계'] = [];
      patientAndExamInformation['위내시경세척시간'] = [];
      patientAndExamInformation['대장검진_외래'] = "없음";
      patientAndExamInformation['대장수면_일반'] = "없음";
      patientAndExamInformation['대장조직'] = "0";
      patientAndExamInformation['대장절제술'] = "0";
      patientAndExamInformation['대장응급'] = false;
      patientAndExamInformation['대장내시경기계'] = [];
      patientAndExamInformation['대장세척기계'] = [];
      patientAndExamInformation['대장내시경세척시간'] = [];
      patientAndExamInformation['sig기계'] = "";
      patientAndExamInformation['sig조직'] = "0";
      patientAndExamInformation['sig절제술'] = "0";
      patientAndExamInformation['sig응급'] = false;
      patientAndExamInformation['sig세척기계'] = "";
      patientAndExamInformation['sig세척시간'] = "";
      selectedScopyName = "...";
    }


    if (appBarDate == 'Today') {
      if (_isPressedMachine ) {
        final currentTime = timeToformattedFormAsyyyyMMddHHmm(DateTime.now());
        patientAndExamInformation['날짜'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (patientAndExamInformation['위내시경기계'] == null  ) {
          patientAndExamInformation['위내시경기계'] = [];
          patientAndExamInformation['위세척기계'] = [];
          patientAndExamInformation['위내시경세척시간'] = [];
        }
        if (patientAndExamInformation['대장내시경기계'] == null) {
          patientAndExamInformation['대장내시경기계'] = [];
          patientAndExamInformation['대정세척기계'] = [];
          patientAndExamInformation['대장내시경세척시간'] = [];
        }
        if (patientAndExamInformation['sig기계'] == null) {
          patientAndExamInformation['sig세척기계'] = '';
          patientAndExamInformation['sig세척시간'] = '';
        }
        if (GSFmachine.containsKey(scopy) && patientAndExamInformation['위내시경기계'].contains(scopy)) {
            patientAndExamInformation['위세척기계'].add(machineName);
            patientAndExamInformation['위내시경세척시간'].add(currentTime);
        } else if(CSFmachine.containsKey(scopy) && patientAndExamInformation['대장내시경기계'].contains(scopy)){
          patientAndExamInformation['대장세척기계'].add(machineName);
          patientAndExamInformation['대장내시경세척시간'].add(currentTime);
        } else if(patientAndExamInformation['sig기계'] !="") {
          patientAndExamInformation['sig세척기계'] = machineName;
          patientAndExamInformation['sig세척시간'] = currentTime;
        }

        if (GSFmachine.containsKey(scopy) && noPatient) {
          patientAndExamInformation['위내시경기계'].add(scopy);
          patientAndExamInformation['위세척기계'].add(machineName);
          patientAndExamInformation['위내시경세척시간'].add(currentTime);
        }
        if (CSFmachine.containsKey(scopy) && noPatient) {
          patientAndExamInformation['대장내시경기계'].add(scopy);
          patientAndExamInformation['대장세척기계'].add(machineName);
          patientAndExamInformation['대장내시경세척시간'].add(currentTime);
        }

        Map<String, String> newInfo = {'날짜-시간':currentTime, '일련번호':scopy, '환자정보':patientAndExamInformation['id']};
        Map<String, String> newInfoWithName = {'날짜-시간':currentTime, '일련번호':scopy, '환자이름':patientAndExamInformation['이름'], '환자id':patientAndExamInformation['id']};
        setState(() {
          todaymachineScopyTimePtName[machineName]!.add(newInfoWithName);
        });
        machineScopyTimePtName[machineName]!.add(newInfoWithName);

        final Map<String, List<dynamic>?>sortedmachineScopyTime = {};
        machineScopyTimePtName.forEach((key, value) {
          sortedmachineScopyTime[key] = sortRecordsByDateTime(value!);
        });

        await saveMachineScopyTimePtIDToFirestore(machineName, newInfo, patientAndExamInformation);

      }
    } else {
      final TimeOfDay initialTime = TimeOfDay(hour: 9, minute: 0);
      final TimeOfDay? picked = await showTimePicker(context: context, initialTime: initialTime);
      DateTime date = DateTime.parse(appBarDate);
      DateTime otherDateAndTime = DateTime(
          date.year, date.month, date.day, picked!.hour, picked.minute
      );
      String otherTime = DateFormat('HH:mm').format(otherDateAndTime);
      patientAndExamInformation['날짜'] = DateFormat('yyyy-MM-dd').format(otherDateAndTime);
      if (GSFmachine.containsKey(scopy) && patientAndExamInformation['위내시경기계'].contains(scopy)) {
          patientAndExamInformation['위세척기계'].add(machineName);
          patientAndExamInformation['위내시경세척시간'].add(timeToformattedFormAsyyyyMMddHHmm(otherDateAndTime));
      }
      if (CSFmachine.containsKey(scopy) && patientAndExamInformation['대장내시경기계'].contains(scopy)) {
          patientAndExamInformation['대장세척기계'].add(machineName);
          patientAndExamInformation['대장내시경세척시간'].add(timeToformattedFormAsyyyyMMddHHmm(otherDateAndTime));
      }
      if (GSFmachine.containsKey(scopy) && noPatient) {
        patientAndExamInformation['위내시경기계'].add(scopy);
        patientAndExamInformation['위세척기계'].add(machineName);
        patientAndExamInformation['위내시경세척시간'].add(timeToformattedFormAsyyyyMMddHHmm(otherDateAndTime));
      }
      if (CSFmachine.containsKey(scopy) && noPatient) {
        patientAndExamInformation['대장내시경기계'].add(scopy);
        patientAndExamInformation['대장세척기계'].add(machineName);
        patientAndExamInformation['대장내시경세척시간'].add(timeToformattedFormAsyyyyMMddHHmm(otherDateAndTime));
      }

      //SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, String> newInfo = {'날짜-시간':timeToformattedFormAsyyyyMMddHHmm(otherDateAndTime), '일련번호':scopy, '환자정보':patientAndExamInformation['id']};
      Map<String, String> newInfoWithName = {'날짜-시간':timeToformattedFormAsyyyyMMddHHmm(otherDateAndTime), '일련번호':scopy, '환자이름':patientAndExamInformation['이름'], '환자id':patientAndExamInformation['id']};
      setState(() {
        machineScopyTimePtName[machineName]!.add(newInfoWithName);
      });
      final Map<String, List<dynamic>?>sortedmachineScopyTime = {};
      machineScopyTimePtName.forEach((key, value) {
        sortedmachineScopyTime[key] = sortRecordsByDateTime(value!);
      });
      //await prefs.setString('machineScopyTime', jsonEncode(sortedmachineScopyTime));
      await saveMachineScopyTimePtIDToFirestore(machineName, newInfo, patientAndExamInformation);
    }
    setState(() {
      selectedPatientNameAndScopyName = '환자';
      noPatient = false;
      _isPressedMachine = false;
    });


  }

  void deleteItemFromFirestore(String machineName, Map<String, dynamic> scopyTimePtName) async {
    final firestore = FirebaseFirestore.instance;

    if (scopyTimePtName['환자이름'] == "없음") {
      try {
        String id = scopyTimePtName['환자id'];
        QuerySnapshot querySnapshot = await firestore.collection('patients')
            .where('id', isEqualTo: id)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          for (var doc in querySnapshot.docs) {
            await firestore.collection('patients').doc(doc.id).delete();
          }
        }
      } catch (e) {
        print('Error deleting document: $e');
      }
    } else {
      try {
        String id = scopyTimePtName['환자id'];
        QuerySnapshot querySnapshot = await firestore.collection('patients')
            .where('id', isEqualTo: id)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          for (var doc in querySnapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String scope = scopyTimePtName['일련번호'];
            if (data['sig기계']==scopyTimePtName['일련번호']) {
              data['sig세척기계'] = "";
              data['sig세척시간'] = "";
            } else if(GSFmachine.containsKey(scope)  ) {
              if(data['위세척기계'] is String) {
                data['위세척기계'] = "";
                data['위내시경세척시간'] = "";
              }
              if(data['위세척기계'] is List) {
                int indexOfItem = data['위내시경기계'].indexOf(scope);
                data['위내시경세척시간'].removeAt(indexOfItem);
                data['위세척기계'].removeAt(indexOfItem);
              }
            } else if(CSFmachine.containsKey(scope)) {
              if (data['대장세척기계'] is String) {
                data['대장세척기계'] = "";
                data['대장내시경세척시간'] = "";
              }
              if (data['대장세척기계'] is List) {
                int indexOfItem = data['대장내시경기계'].indexOf(scope);
                data['대장내시경세척시간'].removeAt(indexOfItem);
                data['대장세척기계'].removeAt(indexOfItem);
              }
            }
            await firestore.collection('patients').doc(doc.id).update(data);
          }
        }
        print('Document successfully deleted.');
      } catch (e) {
        print('Error deleting document: $e');
      }
    }
  }


  void deleteItem(String machineName, Map endoscopyTimePtName) {
    setState(() {
      machineScopyTimePtName[machineName]!.remove(endoscopyTimePtName);
    });
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
            machineWasherChange[machineName] = sortwasherChangeByDateTime(machineWasherChange[machineName]!);
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
                                      _deleteMachineWasherChangeDate(machineName, machineWasherChange[machineName]![index], setState);
                                    });
                                  },
                                  icon: Icon(Icons.delete, size: 20),
                                ),
                                // IconButton(
                                //   onPressed: () => makingExcelFileforEachWashingMachineReport(machineName, machineWasherChange[machineName]![index]) ,
                                //   icon: Icon(Icons.mail, size: 20),
                                //),
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
    String oldWasherChangeDate = machineWasherChange[machineName]![index];
    if (picked != null && !machineWasherChange[machineName]!.contains(DateFormat('yyyy-MM-dd').format(picked))) {
      setState(() {
        machineWasherChange[machineName]![index]= DateFormat('yyyy-MM-dd').format(picked);
      });
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setString('machineWasherChange', jsonEncode(machineWasherChange));
      updateMachineWasherChangeToFirestore(machineName, oldWasherChangeDate, picked);

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


  Future<void> _deleteMachineWasherChangeDate(String machineName, String changeDate, StateSetter setState) async {
    setState(() {
      if (machineWasherChange[machineName] != null) {
        machineWasherChange[machineName]!.remove(changeDate);
      }
    });
    _deleteMachineWasherChangeDateFromFirebase(machineName, changeDate);
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

  List<String> sortwasherChangeByDateTime(List<String> records) {
    records.sort((a, b) {
      // '시간-날짜' 값을 DateTime 으로 파싱합니다.
      DateTime dateTimeA = DateTime.parse(a);
      DateTime dateTimeB = DateTime.parse(b);

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
    sortRecordsByDateTime(tempList);
    return tempList;
  }

  List<Widget> buildEndoscopyButtons(List<String> data) {
    List<Widget> rows = [];
    List<Widget> buttons = [];

    // 데이터를 순회하며 endoscopyButton 위젯을 생성
    for (var i = 0; i < data.length; i++) {
      buttons.add(
        endoscopyButton(
          onPressed: () => _onPressedScopy(data[i]),
          text: data[i],
          isSelected: _isPressedScopy && endoscopySelection,
        ),
      );

      // 매 5개의 버튼이나 마지막 버튼에 도달했을 때 Row 위젯에 추가
      if ((i + 1) % 3 == 0 || i == data.length - 1) {
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

  String generateUniqueId() {
    var uuid = Uuid();
    return uuid.v4(); // v4는 랜덤 UUID를 생성합니다.
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
    "위검진_외래" : "", "위수면_일반":"", "위조직":"0", "CLO":false, "위절제술":"0", "위응급":false, "PEG":false, "위내시경기계":"", "위세척기계":"", "위내시경세척시간":"",
    "대장검진_외래":"", "대장수면_일반":"", "대장조직":"0", "대장절제술":"0", "대장응급":false, "대장내시경기계":"", "대장세척기계":"", "대장내시경세척시간":"",
    "sig기계":"", "sig조직":"0","sig절제술":"0","sig응급":false,
  };
  String selectedPatientNameAndScopyName = "환자";

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
             child: ListView.separated(
                  shrinkWrap: true,
                 itemCount: patientInfoList.length,
                 itemBuilder: (BuildContext context, int index) {
                   var patient = patientInfoList[index];
                   // '위내시경기계', '대장내시경기계', 'sig기계'에 대한 정보를 리스트로 변환합니다.
                   // String 타입이 아닌 경우 빈 리스트([])를 기본값으로 사용합니다.

                   List<dynamic> scopes = [];
                   List<dynamic> colonScopes = [];
                   List<dynamic> sigScopes = [];

                   if (patient['위내시경기계'] is List) {
                     scopes = patient['위내시경기계'];
                   } else if (patient['위내시경기계'] != "") {
                      scopes.add(patient['위내시경기계']);
                   }
                   if (patient['대장내시경기계'] is List) {
                     colonScopes = patient['대장내시경기계'];
                   } else if (patient['대장내시경기계'] != "") {
                     colonScopes.add(patient['대장내시경기계']);
                   }
                   if (patient['sig기계'] is List) {
                     sigScopes = patient['sig기계'];
                   } else if (patient['sig기계'] != "") {
                     sigScopes.add(patient['sig기계']);
                   }

                   return ListTile(
                     title: Text("${patient['이름']}(${patient['환자번호']}) ${patient['성별']}/${patient['나이']} ${patient['시간']}"),
                     subtitle: SingleChildScrollView(
                       scrollDirection: Axis.horizontal, // 가로 스크롤 가능하게 설정
                       child: Row(
                         children: [
                           if (scopes.isNotEmpty) ...scopes.map((scope) => ElevatedButton(
                             child: Text('위 $scope'),
                             onPressed: () {
                               setState(() {
                                 selectedScopyName = scope;
                                 selectedPatientNameAndScopyName = patient['이름'] + " (위내시경 " + scope + ")";
                                 patientAndExamInformation = Map<String, dynamic>.from(patient);
                                 Navigator.of(context).pop();
                               });
                             },
                           )).toList() else SizedBox(),
                           if (colonScopes.isNotEmpty) SizedBox(width: 10),
                           if (colonScopes.isNotEmpty) ...colonScopes.map((scope) => ElevatedButton(
                             child: Text('대장 $scope'),
                             onPressed: () {
                               setState(() {
                                 selectedScopyName = scope;
                                 selectedPatientNameAndScopyName = patient['이름'] + " (대장내시경  " + scope + ")";
                                 patientAndExamInformation = Map<String, dynamic>.from(patient);
                                 Navigator.of(context).pop();
                               });
                             },
                           )).toList() ,
                           if (sigScopes.isNotEmpty) SizedBox(width: 10),
                           if (sigScopes.isNotEmpty) ...sigScopes.map((scope) => ElevatedButton(
                             child: Text('Sig $scope'),
                             onPressed: () {
                               setState(() {
                                 selectedScopyName = scope;
                                 selectedPatientNameAndScopyName = patient['이름'] + " (sig " + scope + ")";
                                 patientAndExamInformation = Map<String, dynamic>.from(patient);
                                 Navigator.of(context).pop();
                               });
                             },
                           )).toList() ,
                         ],
                       ),
                     ),
                   );
                 },

               separatorBuilder: (BuildContext context, int index) => const Divider(),
             ),
           ),
          );
        }
    );
  }



  @override
  Widget build(BuildContext context) {

    void onEdit(String newName, String newDate, String PtName, Map<String, dynamic> oldScopyTimePtMap, String machineName) {

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
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, // 가로 방향으로 스크롤 가능하게 설정
              child: Row(
                children: [
                  machineButton(index: 1, machineName: '1호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine),
                  SizedBox(width: 10,),
                  machineButton(index: 2, machineName: '2호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine),
                  SizedBox(width: 10,),
                  machineButton(index: 3, machineName: '3호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine),
                  SizedBox(width: 10,),
                  machineButton(index: 4, machineName: '4호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine),
                  SizedBox(width: 10,),
                  machineButton(index: 5, machineName: '5호기', isPressedMachine: _isPressedMachine, selectedIndexMachine: _selectedIndexMachine, onPressedMachine: _onPressedMachine)
                ],
              ),
            ),
            SizedBox(height: 10,),
            Row(
              children: [
                Expanded(
                  flex: 4,
                    child: ElevatedButton(
                      onPressed: showPatientInfoDialog,
                      child: Text(
                        selectedPatientNameAndScopyName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(const Color(0xFF6497b1)),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15), // 모서리를 둥글지 않게 설정
                          ),
                        ),
                        fixedSize: MaterialStateProperty.all(Size.fromHeight(50)),
                      ),
                    )
                ),
                SizedBox(width: 10,),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () {
                      noPatient = true;
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('내시경 기계 선택'),
                              content: Container(
                                height: 300,
                                width: double.maxFinite,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: buildEndoscopyButtons(scopyShortName),
                                  ),
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      },
                                    child: Text('닫기'))
                              ],
                            );
                          }
                      );
                    },
                    onLongPress: () {
                      setState(() {
                        selectedScopyName = "...";
                      });
                    },
                    child: Text(
                      endoscopySelection ? selectedScopyName : '...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16
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
              ],
            ),
            SizedBox(height: 10,),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _store(selectedMachineName, selectedScopyName, patientAndExamInformation, appBarDate),
                    child: Text(
                      '저장',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(const Color(0xFF5F5D9C)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // 모서리를 둥글지 않게 설정
                        ),
                      ),
                      fixedSize: MaterialStateProperty.all(Size.fromHeight(50)),
                    ),
                  ),
                ),
              ],
            ),

            // Row(
            //   children: <Widget> [
            //
            //     ElevatedButton(
            //         onPressed: () {
            //           setState(() {
            //             displayTodayOrNot.forEach((key, value) {
            //               displayTodayOrNot[key] = true;
            //             });
            //           });
            //         },
            //         child: Text('오늘 표시')
            //     ),
            //
            //   ],
            // ),
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
                        onDelete: (String machineName, Map<String, dynamic> scopyTimePtName) async {
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
                        onDelete: (String machineName, Map<String, dynamic> scopyTimePtName) async {
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
                        onDelete: (String machineName, Map<String,dynamic> scopyTimePtName) async {
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
                        onDelete: (String machineName, Map<String, dynamic> scopyTimePtName) async {
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
                        onDelete: (String machineName, Map<String, dynamic> scopyTimePtName) async {
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
        ),
        // 기존에 있던 세척실 탭의 코드를 여기에 넣습니다.
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            displayTodayOrNot.forEach((key, value) {
              displayTodayOrNot[key] = true;
            });
          });
        },
        child: Text(
            '오늘',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurpleAccent,
                fontSize: 15,
            ),
        ),
        tooltip: '카메라 모드로 이동', // 'Move to Camera Mode'
      ),
    );

  }
}

Widget endoscopyForEachMachineWidget({
  //required Map<String, List?> machineScopyTime,
  required List scopyTimePtNameList,
  required String machineName,
  required Function onDelete,
  required Function(String, String, String, Map<String, dynamic>, String) onEdit,
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
  final Map<String, dynamic> scopyTimePtName;
  final VoidCallback onPressed;
  final Function(String, String, String, Map<String, dynamic>, String) onEdit;
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
            color: displayTodayOrNot[machineName]! ? Colors.lightBlue[200] : Colors.grey,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child : Column(
            children: displayTodayOrNot[machineName]! ? [
              Text(
                scopyTimePtName['일련번호']!,
                style: TextStyle(
                  color: Colors.white,
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
    print (widget.scopyTimePtMap);
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
      title: Text('시간 수정'),
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
          onPressed: () async {
            final newName = _nameController.text;
            final knownDateAndTime = DateTime.parse(widget.scopyTimePtMap['날짜-시간']);
            final newTime = DateTime(
              knownDateAndTime.year,
              knownDateAndTime.month,
              knownDateAndTime.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );//.add(Duration(hours: 9));
            final formattedNewTime = DateFormat('yyyy-MM-dd HH:mm').format(newTime);
            String patientId = widget.scopyTimePtMap['환자id'];
            String scopeType = "";
            String scopeWashTime = "";
            int index = 0;
            FirebaseFirestore firestore = FirebaseFirestore.instance;
            try {
              QuerySnapshot query = await firestore.collection('patients')
                  .where('id', isEqualTo: patientId)
                  .get();

              if (query.docs.isNotEmpty) {
                for (var doc in query.docs) {
                  Map<String, dynamic> patientAndExaminationInformation  = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);

                  if (doc['대장내시경기계'].contains(widget.scopyTimePtMap['일련번호'])) {
                    index = doc['대장내시경기계'].indexOf(widget.scopyTimePtMap['일련번호']);
                    patientAndExaminationInformation['대장내시경기계'][index] = newName;
                    patientAndExaminationInformation['대장내시경세척시간'][index] = formattedNewTime;
                  }
                  if (doc['위내시경기계'].contains(widget.scopyTimePtMap['일련번호'])) {
                    index = doc['위내시경기계'].indexOf(widget.scopyTimePtMap['일련번호']);
                    patientAndExaminationInformation['위내시경기계'][index] = newName;
                    patientAndExaminationInformation['위내시경세척시간'][index] = formattedNewTime;
                  }
                  await firestore.collection('patients').doc(doc.id).update(
                      patientAndExaminationInformation
                  );
                  print('Document successfully updated.');
                }
              } else {
                print('No document found for the given patient ID.');
              }
            } catch (e) {
              print('Error updating document: $e');
            }

            Navigator.of(context).pop({"일련번호":newName, "날짜-시간":formattedNewTime, '환자이름':PtName});
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