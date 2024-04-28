//import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';


class ExaminationRoom extends StatefulWidget {
  @override
  _ExaminationRoomState createState() => _ExaminationRoomState();
}

class _ExaminationRoomState  extends State<ExaminationRoom> with AutomaticKeepAliveClientMixin {

  final firestore = FirebaseFirestore.instance;

  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic> patientAndExamInformation = {"id":"", "환자번호":"", '이름':"", '성별':"", '나이':"", "Room":"", "생일":"", "의사":"", "날짜":"", "시간":"",
    "위검진_외래" : "검진", "위수면_일반":"수면", "위조직":"0", "CLO":false, "위절제술":"0", "위응급":false, "PEG":false,
    "위내시경":{},
    "대장검진_외래":"외래", "대장수면_일반":"수면", "대장조직":"0", "대장절제술":"0", "대장응급":false,
    "대장내시경":{},
    "sig": {}, "sig조직":"0","sig절제술":"0","sig응급":false,
  };

  final List<String> docs = ['이병수', '권순범', '김신일','한융희', '이기섭'];
  final List<String> rooms = ['1','2','3'];
  final List<String> numAsString = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];



   Map<String, String> GSFmachine = {'073':'KG391K073', '180':'5G391K180', '153':'5G391K153','256':'7G391K256','257':'7G391k257',
    '259':'7G391K259','407':'2G348K407', '405':'2G348K405','390':'2G348K390', '333':'2G348K333', '694':'5G348K694'};
   Map<String, String> CSFmachine = {'039':'7C692K039', '166':'6C692K166', '098':'5C692K098', '219':'1C664K219', '379':'1C665K379', '515':'1C666K515',};

  bool? GSF = true;
  bool? CSF = false;
  bool? sig = false;
  bool? gsfEtc = false;
  bool? csfETc = false;
  String? selectedDoctor;
  String appBarDate = "";
  int totalExamNum = 0;
  bool? newData = true;
  bool? editing = false;
  bool storeButtonDisabled = true;

  DateTime selectedDateInPatientInfoDialog = DateTime.now();
  Map<String, TextEditingController> controllders = {};
  Map<String, String> fullPatientInformation = {};
  List<String> selectedGSFMachines = [];
  List<String> selectedCSFMachines = [];
  List<String> selectedSigMachines = [];

  @override
  void initState()  {
    super.initState();
    fetchScopes('GSF');

    fetchScopes('CSF');
    selectedDoctor = patientAndExamInformation['의사'];

    appBarDate = "Today";
    patientAndExamInformation.forEach((key, value) {
      if (key != "위내시경" && key != "대장내시경" && key != "sig") {
        controllders[key] = TextEditingController(text: value.toString());
      }

    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute
          .of(context)
          ?.settings
          .arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          patientAndExamInformation['id'] = args['id'];
          patientAndExamInformation['성별'] = args['성별']; // 'M' 또는 'F'
          patientAndExamInformation['환자번호'] = args['환자번호'] ?? patientAndExamInformation['환자번호'];
          controllders['환자번호']?.text = patientAndExamInformation['환자번호'];
          patientAndExamInformation['이름'] = args['이름'] ?? patientAndExamInformation['이름'];
          controllders['이름']?.text = patientAndExamInformation['이름'];
          patientAndExamInformation['나이'] = args['나이'] ?? patientAndExamInformation['나이'];
          controllders['나이']?.text = patientAndExamInformation['나이'];
          patientAndExamInformation['생일'] = args['생일'] ?? patientAndExamInformation['생일'];
          controllders['생일']?.text = patientAndExamInformation['생일'];
          patientAndExamInformation['Room'] = args['Room'];
          patientAndExamInformation['의사'] = args['의사'];
          controllders['Room']?.text = patientAndExamInformation['Room'];
          controllders['의사']?.text = patientAndExamInformation['의사'];
        });
      }
    });
    refresh();
  }

  @override
  void dispose() {
    controllders.forEach((key, controller) {
      if (key != "위내시경" && key != "대장내시경" && key != "sig"){
        controller.dispose();
      }
    });
    super.dispose();
  }

  Future<void> fetchScopes(String scopeType) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference docRef = await firestore.collection('scopes').doc(scopeType);

    docRef.get().then((DocumentSnapshot document) {
      if (document.exists) {
        setState(() async {
          if (scopeType == 'GSF') {
            GSFmachine = Map<String, String>.from(document.data() as Map<String, dynamic>);
            GSFmachine = await sortMapByKey(GSFmachine);
          } else if (scopeType == 'CSF') {
            CSFmachine = Map<String, String>.from(document.data() as Map<String, dynamic>);
            CSFmachine = await sortMapByKey(CSFmachine);
          }
        });
      } else {
        print('No such document!');
      }
    }).catchError((error) {
      print("Error getting document: $error");
    });


  }


  String generateUniqueId() {
    var uuid = Uuid();
    return uuid.v4(); // v4는 랜덤 UUID를 생성합니다.
  }

  bool comparePatientInfo(Map<String, dynamic> info1, Map<String, dynamic> info2) {
    // 먼저, 두 맵의 길이가 동일한지 확인합니다.
    if (info1.length != info2.length) {
      return false;
    }

    // 각 키에 대해 두 맵이 동일한 값을 갖고 있는지 확인합니다.
    for (String key in info1.keys) {
      // 두 맵 중 하나라도 해당 키를 포함하지 않거나 값이 다르면 false 반환
      if (!info2.containsKey(key) || info1[key] != info2[key]) {
        return false;
      }
    }

    // 모든 검사를 통과했다면, 두 맵은 동일합니다.
    return true;
  }




  Future<void> updatePatientAndExamInfo(Map<String, dynamic> newInfo) async {

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    if (GSF == false) {
      patientAndExamInformation["위검진_외래"] = "";
      patientAndExamInformation["위수면_일반"] = "";
      patientAndExamInformation["위조직"] = "0";
      patientAndExamInformation["CLO"] = false;
      patientAndExamInformation["위절제술"] = "0";
      patientAndExamInformation["위응급"] = false;
      patientAndExamInformation["PEG"] = false;
      patientAndExamInformation['위내시경'] = {};
      // patientAndExamInformation["위내시경기계"] = <String>[];
      // patientAndExamInformation["위세척기계"] = <String>[];
      // patientAndExamInformation["위내시경세척시간"] = <String>[];
    }
    if (CSF == false) {
      patientAndExamInformation["대장검진_외래"] = "";
      patientAndExamInformation["대장수면_일반"] = "";
      patientAndExamInformation["대장조직"] = "0";
      patientAndExamInformation["대장절제술"] = "0";
      patientAndExamInformation["대장응급"] = false;
      patientAndExamInformation['대장내시경'] = {};
      // patientAndExamInformation["대장내시경기계"] = <String>[];
      // patientAndExamInformation["대장세척기계"] = <String>[];
      // patientAndExamInformation["대장내시경세척시간"] = <String>[];
    }
    if (sig == false) {
      patientAndExamInformation["sig조직"] = "0";
      patientAndExamInformation["sig절제술"] = "0";
      patientAndExamInformation["sig응급"] = false;
      patientAndExamInformation['sig'] = {};
      // patientAndExamInformation["sig기계"] = <String>[];
      // patientAndExamInformation["sig세척기계"] = <String>[];
      // patientAndExamInformation["sig세척시간"] = <String>[];
    }

    QuerySnapshot querySnapshot = await firestore.collection('patients').where('id', isEqualTo:newInfo['id']).get();
    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        await firestore.collection('patients').doc(doc.id).update(newInfo);
        refresh();
      }
    }

  }

  Widget _buildRadioSelection(String title, String firstElement, String secondElement) {
    return Container(
      padding: EdgeInsets.all(1.0), // 내부 여백을 추가합니다.
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.indigoAccent, // 테두리 색상
          width: 2.0, // 테두리 두께
        ),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [ // 그림자 목록 설정
          BoxShadow(
            color: Colors.black.withOpacity(0.5), // 그림자 색상 설정 (투명도 포함)
            spreadRadius: 1, // 그림자의 범위 설정
            blurRadius: 6, // 그림자의 블러 효과 설정
            offset: Offset(0, 3), // x,y 오프셋 설정 (가로, 세로 방향)
          ),
        ],
        // 테두리 모서리를 둥글게 합니다.
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigoAccent.withOpacity(0.5))),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Radio<String>(
                value: firstElement,
                groupValue: patientAndExamInformation[title],
                onChanged: (String? value) {
                  setState(() {
                    patientAndExamInformation[title] = value;
                  });
                },
              ),
              Text(firstElement),
              Radio<String>(
                value: secondElement,
                groupValue: patientAndExamInformation[title],
                onChanged: (String? value) {
                  setState(() {
                    patientAndExamInformation[title] = value;
                  });
                },
              ),
              Text(secondElement),
            ],
          ),
        ],

      ),
    );
  }

  Widget _textFormInExamRoom(String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border:Border.all(
          width: 2,
          color: Colors.indigoAccent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5), // 그림자 색상 설정 (투명도 포함)
            spreadRadius: 1, // 그림자의 넓이 설정
            blurRadius: 6, // 그림자의 블러 효과 설정
            offset: Offset(0, 3), // x, y 오프셋 설정 (가로, 세로 방향)
          ),
        ],
        borderRadius: BorderRadius.circular(10), // 모서리 둥글기 설정
      ),
      child: TextFormField(
        controller: controllders[title],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          //alignLabelWithHint: true,
          labelText: title,
          labelStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold, // 글씨를 굵게
            color: Colors.indigoAccent.withOpacity(0.3),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) {
          patientAndExamInformation[title] = value;
          //controllders['이름']?.text = value;
        },
      ),
    );
  }

  Widget _buildGSFMachinesSelection(String title, Map<String, String> scopeType, List<String> selectedScopesList) {
    return Wrap(
      spacing: 8.0, // Chip 간의 가로 간격
      runSpacing: 4.0, // Chip 간의 세로 간격
      children: scopeType.keys.map<Widget>((String key) {
        return GestureDetector(
          onLongPress: () {
            // Show a dialog to confirm deletion
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("이 항목을 제거하시겠습니까?"),
                  content: Text("내시경 이름: $key"),
                  actions: <Widget>[
                    TextButton(
                      child: Text('아니오'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text('네'),
                      onPressed: () async {
                        try {
                          String docName = "";
                          if (title == '위내시경') {
                            docName = 'GSF';
                          } else if (title == '대장내시경') {
                            docName = 'CSF';
                          }
                          DocumentReference docRef = firestore.collection('scopes').doc(docName);
                          await docRef.update({
                            key: FieldValue.delete() // This will delete the specific field from the document
                          });
                          setState(() {
                            scopeType.remove(key);
                            selectedScopesList.remove(key);
                            patientAndExamInformation[title].removeWhere((element) => element == key);
                          });
                          Navigator.of(context).pop();
                        } catch (e) {
                          print("Error deleting item: $e");
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: ChoiceChip(
            label: Text(key),
            selected: selectedScopesList.contains(key),
            onSelected: (bool selected) {
              setState(() {
                if (selected) {
                  selectedScopesList.add(key);
                  if (patientAndExamInformation[title].isEmpty) {
                    patientAndExamInformation[title] = {};
                  }
                  if (!patientAndExamInformation[title].containsKey(key)){
                    print ('scope : $key');
                    patientAndExamInformation[title][key] = {"세척기계":"", "세척시간":""};
                    print (patientAndExamInformation);
                  }

                } else {
                  selectedScopesList.removeWhere((String name) => name == key);
                  patientAndExamInformation[title].remove(key);
                }
              });
            },
            selectedColor: Colors.lightBlueAccent,
            pressElevation: 0,
            backgroundColor: Colors.grey[200],
            labelStyle: TextStyle(color: Colors.black),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: selectedScopesList.contains(key) ? Colors.red : Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }).toList()
        ..add(
          // Adding the IconButton as a separate Widget
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _addNewScopeDialog(scopeType, title),
          ),
        ),
    );
  }



  void _addNewScopeDialog(Map<String, String> scopeType, String title) {
    TextEditingController shortNameController = TextEditingController();
    TextEditingController fullNameController = TextEditingController();
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("내시경 추가"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: shortNameController,
                decoration: InputDecoration(labelText: '축약이름'),
              ),
              TextField(
                controller: fullNameController,
                decoration: InputDecoration(labelText: '전체이름'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('추가'),
              onPressed: () async {
                String shortName = shortNameController.text;
                String fullName = fullNameController.text;

                // Firestore에 저장
                String docName = "";
                if (title == "위내시경기계") {
                  docName = 'GSF';
                }
                if (title == "대장내시경기계") {
                  docName = "CSF";
                }
                DocumentReference docRef = firestore.collection('scopes').doc(docName);
                Map<String, String> newScope = {shortName: fullName};

                // Firestore 문서 업데이트
                docRef.set(newScope, SetOptions(merge: true)).then((_) {
                  print('Scope added successfully');
                  setState(() {
                    scopeType[shortName] = fullName;
                  });
                  Navigator.of(context).pop();
                }).catchError((error) {
                  print('Failed to add scope: $error');
                });
              },
            ),
          ],
        );
      },
    );
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

  Widget _dropDownForSig(List<String> items) {
    return DropdownButton<String> (
      itemHeight: 50,
      value: null,
      hint: Center(
        //alignment: Alignment.center,
        child: Text(
          'sig기계',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.indigoAccent.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ),
      isExpanded: true,
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          patientAndExamInformation['sig'] = {'세척기계':"", '세척시간':""};
        });
      },
    );
  }

  Widget _dropDownInExamRoom(String title, List<String> items) {
    return DropdownButton<String> (
      itemHeight: 50,
      value: items.contains(patientAndExamInformation[title])
          ? patientAndExamInformation[title] != "0" ? patientAndExamInformation[title] :
          title == "Room"? patientAndExamInformation[title]+'번방' : null
          : null,
      hint: Center(
        //alignment: Alignment.center,
        child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigoAccent.withOpacity(0.5),
            ),
          textAlign: TextAlign.center,
        ),
      ),
      isExpanded: true,
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                    title == "Room"? value+'번방' : value,
                    textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          patientAndExamInformation[title] = value;
        });
      },
    );
  }



  String stomachBxRadioValue = '없음';
  Map<String, String> stomachOrColonBxOrpolypectomy = {'stomachBx':'없음', 'colonBx':'없음', 'stomachPolypectomy':'없음', 'colonPolypectomy':"없음"};

  Widget _dropDownForScopes(String title, String anatomyandProcedure, List<String> items) {

    return DropdownButton<String> (
      itemHeight: 50,
      value: patientAndExamInformation[title] == '0' ? null : patientAndExamInformation[title],
      hint: Center(
        //alignment: Alignment.center,
        child: Text(
          '없음',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ),
      isExpanded: true,
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          patientAndExamInformation[title] = value;
          stomachOrColonBxOrpolypectomy[anatomyandProcedure] = value!;
        });
      },
    );
  }

  Widget _buildStomachBxRadioButtonGroup(String title, String anatomyandProcedure) {
    List<String> labels = ['없음', '1', '2', '3'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: labels.map((String label) {
        return Expanded(
          child: Row(
            children: <Widget>[
              Radio<String>(
                value: label,
                groupValue: stomachOrColonBxOrpolypectomy[anatomyandProcedure],
                onChanged: (String? value) {
                  setState(() {
                    stomachOrColonBxOrpolypectomy[anatomyandProcedure] = value!;
                    patientAndExamInformation[title] = value == '없음' ? '0' : value;
                    controllders[title]?.text = patientAndExamInformation[title];
                  });
                },
              ),
              SizedBox(width: 4), // 라디오 버튼과 텍스트 사이의 간격 조정
              Text(label),
            ],
          )

        );
      }).toList(),
    );
  }



  DateTime selectedDate = DateTime.now();




  Future<void> _selectDate(BuildContext context) async {
    //DateTime selectedDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // 초기 선택된 날짜
      firstDate: DateTime(2000), // 선택 가능한 가장 이른 날짜
      lastDate: DateTime(2025), // 선택 가능한 가장 늦은 날짜
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked; // 선택된 날짜로 상태 업데이트
        patientAndExamInformation['날짜'] = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchPatientInfoByDate(DateTime date) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> todayPatients = [];

    String DateString = DateFormat('yyyy-MM-dd').format(date);

    try{
      QuerySnapshot querySnapshot = await firestore.collection('patients')
          .where('날짜', isEqualTo:DateString)
          .get();

      for(var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if(data['이름'] != '없음') {
          todayPatients.add(data);
        }
      }
    } catch (e) {
      print ("데이터를 가져오지 못했습니다. :$e");
    }

    return todayPatients;
  }


  void showPatientInfoDialog() async {

    List<Map<String, dynamic>> patientInfoList = await fetchPatientInfoByDate(selectedDateInPatientInfoDialog);
    Future<void> _selectDateInPatientInfoDialog(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDateInPatientInfoDialog,
        firstDate: DateTime(2000),
        lastDate: DateTime(2025),
      );
      if (picked != null && picked != selectedDateInPatientInfoDialog) {
        setState(()  {
          selectedDateInPatientInfoDialog = picked;
          selectedDate = picked;
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
              Text("환자 목록"),
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
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      newData = false;
                      selectedGSFMachines = [];
                      selectedCSFMachines = [];
                      patientAndExamInformation = Map<String, dynamic>.from(patient);
                      controllders['환자번호']?.text = patientAndExamInformation['환자번호'] ?? '';
                      controllders['이름']?.text = patientAndExamInformation['이름'] ?? '';
                      controllders['성별']?.text = patientAndExamInformation['성별'] ?? '';
                      controllders['나이']?.text = patientAndExamInformation['나이'] ?? '';
                      controllders['생일']?.text = patientAndExamInformation['생일'] ?? '';
                      appBarDate = patientAndExamInformation['날짜'] ?? 'Today';
                      controllders['날짜']?.text = patientAndExamInformation['날짜'] ?? '';
                      controllders['Room']?.text = patientAndExamInformation['Room'] ?? '';
                      controllders['의사']?.text = patientAndExamInformation['의사'] ?? '';
                      controllders['날짜']?.text = patientAndExamInformation['날짜'] ?? '';
                      controllders['시간']?.text = patientAndExamInformation['시간'] ?? '';

                      if (!patient.containsKey('위내시경')) {
                        GSF = false;
                      } else if (patient['위내시경'].isEmpty) {
                        GSF = false;
                      } else {
                        GSF = true;
                        controllders['위검진_외래']?.text = patientAndExamInformation['위검진_외래'] ?? '';
                        controllders['위수면_일반']?.text = patientAndExamInformation['위수면_일반'] ?? '';
                        controllders['위조직']?.text = patientAndExamInformation['위조직'] ?? '';
                        controllders['위절제술']?.text = patientAndExamInformation['위절제술'] ?? '';
                        for (var scope in patientAndExamInformation['위내시경'].keys.toList()){
                          selectedGSFMachines.add(scope);
                        }
                      }
                      if (!patient.containsKey('대장내시경')) {
                        CSF = false;
                      } else if (patient['대장내시경'].isEmpty) {
                        CSF = false;
                      } else {
                        CSF = true;
                        controllders['대장검진_외래']?.text = patientAndExamInformation['대장검진_외래'] ?? '';
                        controllders['대장수면_일반']?.text = patientAndExamInformation['대장수면_일반'] ?? '';
                        controllders['대장조직']?.text = patientAndExamInformation['대장조직'] ?? '';
                        controllders['대장절제술']?.text = patientAndExamInformation['대장절제술'] ?? '';
                        //controllders['대장내시경기계']?.text = patientAndExamInformation['대장내시경기계'] ?? '';
                        for (var scope in patientAndExamInformation['대장내시경'].keys.toList()){
                          selectedCSFMachines.add(scope);
                        }

                      }
                      if (!patient.containsKey('sig')) {
                        sig = false;
                      } else if ((patient['sig']).isEmpty) {
                        sig = false;
                      } else {
                        sig = true;
                        controllders['sig조직'] = patientAndExamInformation['sig조직']?? '0';
                        controllders['sig절제술'] = patientAndExamInformation['sig절제술']?? '0';
                        controllders['sig응급'] = patientAndExamInformation['sig응급']?? false;
                        for (var scope in patientAndExamInformation['대장내시경'].keys.toList()){
                          selectedSigMachines.add(scope);
                        }

                      }
                    });
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final result = await showDialog(
                          context: context,
                          builder: (BuildContext deletcontext) {
                            return AlertDialog(
                              title: Text('항목 삭제'),
                              content: Text("이 항목을 삭제하시겠습니까?"),
                              actions: <Widget>[
                                TextButton(
                                    onPressed: () => Navigator.of(deletcontext).pop(true),
                                    child: Text('예')
                                ),
                                TextButton(
                                    onPressed: () => Navigator.of(deletcontext).pop(false),
                                    child: Text('아니오'),
                                ),
                              ],
                            );

                          }
                      );
                      if (result == true) {
                        final id = patientInfoList[index]['id'];
                        await deleteDocumentByPatientNumber(id);
                        Navigator.of(context).pop();
                        showPatientInfoDialog();
                        refresh();
                      }
                    },
                  ),
                );
              },
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

  Future<void> deleteDocumentByPatientNumber(String id) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // 'patients' 컬렉션에서 '환자번호'가 일치하는 문서를 찾습니다.
      QuerySnapshot querySnapshot = await firestore
          .collection('patients')
          .where('id', isEqualTo: id)
          .get();

      // 찾은 문서들을 삭제합니다.
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      print('문서 삭제 완료');
    } catch (e) {
      print('문서 삭제 중 오류 발생: $e');
    }
  }

  void refresh() async {
    final List patientNum = await  fetchPatientInfoByDate(DateTime.now());
    setState(() {
      totalExamNum = patientNum.length;
    });
  }


  Widget _buildForm(Map<String, dynamic> fullPatientInformation) {

    // if (patientAndExamInformation != null ) {
    //   print ('haha:$patientAndExamInformation');
    // }

    final DateFormat DateFormatForAppBarDate = DateFormat('yyyy-MM-dd');

    final String formattedDateForAppBar = DateFormatForAppBarDate.format(selectedDate);
    appBarDate = formattedDateForAppBar;
    final String formattedToday = DateFormatForAppBarDate.format(DateTime.now());
    appBarDate = (formattedToday == formattedDateForAppBar) ? 'Today' : formattedDateForAppBar;


    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _textFormInExamRoom('환자번호'),
            ),
            SizedBox(width: 20,),
            Expanded(
              child: _textFormInExamRoom('이름'),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _buildRadioSelection('성별', 'M', 'F')
            ),
            SizedBox(width: 10,),
            Expanded(
                child: _textFormInExamRoom('나이'),
            ),
            SizedBox(width: 10,),
            Expanded(
              child: _textFormInExamRoom('생일'),
            )
          ],
        ),
        SizedBox(height: 10,),
        Row(
          children: [
            Expanded(
              child:ElevatedButton(
                onPressed:() => _selectDate(context),
                child: Text(
                    appBarDate,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    )
                ),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(const Color(0xFF6AD4DD)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                          color: Colors.indigoAccent,
                          width: 2
                      ),
                    )
                  )
                ),

              )
            ),
            SizedBox(width: 10,),
            Expanded(
                child: _dropDownInExamRoom('Room', rooms),
            ),
            SizedBox(width: 10,),
            Expanded(
              child: _dropDownInExamRoom('의사', docs),
            )
          ],
        ),
        Row(
          children: [
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                            '위 내시경',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2.0, 2.0),
                                    blurRadius: 2.0,
                                    color: Colors.blueGrey.withOpacity(0.5),
                                  ),
                                ],
                            )
                        ),
                        Checkbox(
                          tristate:false,
                          value: GSF,
                          onChanged: (value) {
                            setState(() {
                              GSF = value;
                            });
                          },
                        ),
                        Spacer(),
                        IconButton(
                            onPressed: refresh,
                            icon: Icon(Icons.refresh),
                            iconSize: 40,
                        ),
                        SizedBox(width: 10,),
                        ElevatedButton(
                            onPressed: showPatientInfoDialog,
                            child: Text('$totalExamNum명', style: TextStyle(fontSize: 20, color: Colors.white),),
                            style: ButtonStyle(
                              // 배경 색상 설정
                              backgroundColor: MaterialStateProperty.all(Colors.indigo),
                              // 테두리 모양 및 색상 설정
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0), // 테두리 둥근 정도 조절
                                  side: BorderSide(color: Colors.indigoAccent), // 테두리 색상 및 두께 조절
                                ),
                              ),
                            ),
                        )
                      ],
                    ),
                    SizedBox(height: 10,),
                    Visibility(
                      visible: GSF!,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color:Colors.purple,
                                width: 2.0,
                            ),

                        ),
                        child: Column(
                          children:[
                            Row(
                              children: [
                                Expanded(
                                    child: _buildRadioSelection('위검진_외래', '검진', '외래')
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                    child: _buildRadioSelection('위수면_일반', '수면', '일반',)
                                )

                              ],
                            ),
                            SizedBox(height: 10,),
                            Divider(color: Colors.purple,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '위 조직검사 : [',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.indigoAccent.withOpacity(0.5),
                                      ),

                                    ),
                                    Expanded(
                                        child: _dropDownForScopes('위조직', 'stomach', numAsString )
                                    ),
                                    Text(
                                      ']',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.indigoAccent.withOpacity(0.5),
                                      ),

                                    ),
                                    SizedBox(width: 20,),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text('CLO', style: TextStyle(fontSize: 18)),
                                          Checkbox(
                                              tristate: false,
                                              value: patientAndExamInformation['CLO']?? false,
                                              onChanged: (value) {
                                                setState(() {
                                                  patientAndExamInformation['CLO'] = value;
                                                });
                                              }
                                          )
                                        ],
                                      ),
                                    ),

                                  ],
                                ),
                                _buildStomachBxRadioButtonGroup('위조직', 'stomach'),
                              ],
                            ),
                            Divider(color: Colors.purple,),
                            //SizedBox(width: 10,),
                            Column(
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    '위 내시경 기계',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.indigoAccent.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                _buildGSFMachinesSelection('위내시경', GSFmachine, selectedGSFMachines),
                              ],
                            ),
                            Divider(color: Colors.purple,),
                            Row(
                              children: [
                                Text(
                                    '기타',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.indigoAccent.withOpacity(0.5)
                                  ),
                                ),
                                Checkbox(
                                  tristate:false,
                                  value: gsfEtc,
                                  onChanged: (value) {
                                    setState(() {
                                      gsfEtc = value;
                                    });
                                  },
                                ),
                                gsfEtc!? Container(
                                  child : Row(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '응급',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.black.withOpacity(0.5),
                                            ),
                                          ),
                                          Checkbox(
                                            tristate:false,
                                            value: patientAndExamInformation['위응급'],
                                            onChanged: (value) {
                                              setState(() {
                                                patientAndExamInformation['위응급'] = value;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'PEG',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.black.withOpacity(0.5),
                                            ),
                                              ),
                                          Checkbox(
                                            tristate:false,
                                            value: patientAndExamInformation['PEG'],
                                            onChanged: (value) {
                                              setState(() {
                                                patientAndExamInformation['PEG'] = value;
                                              });
                                            },
                                          ),
                                        ],
                                      ),

                                    ],
                                  )
                                ) : SizedBox()
                              ],
                            ),
                            gsfEtc!? Container(
                              child: Row(
                                children: [
                                  Text(
                                    '위 용종 절제술 : [',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black.withOpacity(0.5),
                                    ),

                                  ),
                                  Expanded(
                                      child: _dropDownForScopes('위절제술', 'stomachPolypectomy', numAsString )
                                  ),
                                  Text(
                                    ']',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ) : SizedBox()
                          ]
                        ),
                      ),
                    )

                  ],
                )
            )
          ],
        ),
        Row(
          children: [
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                            '대장 내시경',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            shadows: [
                              Shadow(
                                offset: Offset(2.0, 2.0),
                                blurRadius: 2.0,
                                color: Colors.blueGrey.withOpacity(0.5),
                              ),
                              // 필요하다면 더 많은 Shadow 객체를 리스트에 추가할 수 있습니다.
                            ],
                            )
                        ),
                        Checkbox(
                          tristate:false,
                          value: CSF,
                          onChanged: (value) {
                            setState(() {
                              CSF = value;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10,),
                    Visibility(
                      visible: CSF!,
                      child: Container(
                          padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color:Colors.purple,
                              width: 2.0,
                          )
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _buildRadioSelection('대장검진_외래', '검진', '외래')
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                    child: _buildRadioSelection('대장수면_일반', '수면', '일반',)
                                )

                              ],
                            ),
                            SizedBox(height: 10,),
                            Divider(color: Colors.purple,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '대장 용종절제술 : [',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.indigoAccent.withOpacity(0.5),
                                      ),

                                    ),
                                    Expanded(
                                        child: _dropDownForScopes('대장절제술', 'colonPolypectomy',numAsString )
                                    ),
                                    Text(
                                      ']',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.indigoAccent.withOpacity(0.5),
                                      ),

                                    ),
                                    SizedBox(width: 20,),
                                  ],
                                ),
                                _buildStomachBxRadioButtonGroup('대장절제술', 'colon'),
                              ],
                            ),
                            Divider(color: Colors.purple.withOpacity(0.5),),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '대장 조직검사 : [',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.indigoAccent.withOpacity(0.5),
                                      ),

                                    ),
                                    Expanded(
                                        child: _dropDownForScopes('대장조직', 'colonBx',numAsString )
                                    ),
                                    Text(
                                      ']',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.indigoAccent.withOpacity(0.5),
                                      ),

                                    ),
                                    SizedBox(width: 20,),
                                  ],
                                ),
                                _buildStomachBxRadioButtonGroup('대장조직', 'colonBx'),
                              ],
                            ),
                            Divider(color: Colors.purple,),
                            Column(
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    '대장 내시경 기계',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.indigoAccent.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                _buildGSFMachinesSelection('대장내시경', CSFmachine, selectedCSFMachines),
                              ],
                            ),

                          ],
                        )
                      ),
                    )

                  ],
                )
            )
          ],
        ),
        Row(
          children: [
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                            'S상 결장경',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            shadows: [
                              Shadow(
                                offset: Offset(2.0, 2.0),
                                blurRadius: 2.0,
                                color: Colors.blueGrey.withOpacity(0.5),
                              ),
                              // 필요하다면 더 많은 Shadow 객체를 리스트에 추가할 수 있습니다.
                            ],
                            ),
                        ),
                        Checkbox(
                          tristate:false,
                          value: sig,
                          onChanged: (value) {
                            setState(() {
                              sig = value;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10,),
                    Visibility(
                      visible: sig!,
                      child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              border: Border.all(
                                color:Colors.purple,
                                width: 2.0,
                              )
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Row(
                                        children: [
                                          Text('응급', style: TextStyle(fontSize: 18)),
                                          SizedBox(width: 10),
                                          Checkbox(
                                            tristate:false,
                                            value: patientAndExamInformation['sig응급']?? false,
                                            onChanged: (value) {
                                              setState(() {
                                                patientAndExamInformation['sig응급'] = value;
                                              });
                                            },
                                          ),
                                        ],
                                      )),
                                  Expanded(
                                      child: _dropDownInExamRoom('sig조직', numAsString )),
                                  SizedBox(width: 10,),
                                  Expanded(
                                      child: _dropDownInExamRoom('sig절제', numAsString )),
                                  SizedBox(width: 10,),
                                ],
                              ),
                              SizedBox(width: 10,),
                              Divider(color: Colors.purple,),
                              Column(
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'sig 모델명',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.indigoAccent.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  _buildGSFMachinesSelection('sig', {'219':'1C664K219', '694':'5G348K694'}, selectedCSFMachines),
                              ],
                              ),
                            ],
                          )
                      ),
                    )

                  ],
                )
            )
          ],
        )
      ],
    );
  }


  void _navigateToCamera(BuildContext context) async {
    newData = true;
    editing = false;
    // Obtain a list of the available cameras on the device.
    final cameras = await availableCameras();

    // Get a specific camera from the list of available cameras.
    final firstCamera = cameras.first;

    // Navigate to a new route and pass the camera to it.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePictureScreen(camera: firstCamera, previousRoom: patientAndExamInformation['Room'], previousDoc:patientAndExamInformation['의사']),
      ),
    );
  }

  void getRecognizedText(String imagePath) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage);

    String scannedText = "";
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        scannedText += "${line.text}\n";
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (patientAndExamInformation['의사'] !='' && patientAndExamInformation['Room'] != '') {
      if (GSF!) {
        storeButtonDisabled =  selectedGSFMachines.length>0 ? false : true;
      }
      if (CSF!) {
        storeButtonDisabled =  selectedCSFMachines.length>0 ? false : true;
      }
      if (sig!) {
        storeButtonDisabled = patientAndExamInformation['sig기계'] != "" ? false : true;
      }
    }



    return Scaffold(
      body: SingleChildScrollView(
        child:Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildForm(patientAndExamInformation),
            ),
            storeButtonDisabled? SizedBox(): ElevatedButton(
              child: Text(
                '저장',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              onPressed: () async {
                if (appBarDate == 'Today' && newData!) {
                  patientAndExamInformation['날짜'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  patientAndExamInformation['시간'] = DateFormat('HH:mm').format(DateTime.now());
                }
                if (appBarDate !="Today" && newData!) {
                  patientAndExamInformation['날짜'] = appBarDate;
                  final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    patientAndExamInformation['시간'] = pickedTime.hour.toString() + ":" + pickedTime.minute.toString();
                  }
                }
                // final String patientNumber = patientAndExamInformation['환자번호'];
                // final String patientName = patientAndExamInformation['이름'];
                // final String date = patientAndExamInformation['날짜'];
                // final String time = patientAndExamInformation['시간'];

                try {
                  await updatePatientAndExamInfo(patientAndExamInformation);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('환자 정보가 저장되었습니다.'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('환자 정보 저장 중 오류가 발생했습니다: $e'),
                    ),
                  );
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.teal),
                minimumSize: MaterialStateProperty.all(Size(double.infinity, 40)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0), // 테두리 둥근 정도 조절
                    side: BorderSide(color: Colors.indigoAccent), // 테두리 색상 및 두께 조절
                  ),
                ),
              ),
            ),
          ],
        ),

        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCamera(context),
        child: Icon(Icons.camera_alt),
        tooltip: '카메라 모드로 이동', // 'Move to Camera Mode'
      ),

      );

  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  final String previousRoom;
  final String previousDoc;

  const TakePictureScreen({
    Key? key,
    required this.camera,
    required this.previousRoom,
    required this.previousDoc,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previousRoom = widget.previousRoom;
    final previousDoc = widget.previousDoc;
    return Scaffold(
      appBar: AppBar(title: Text('환자 정보를 찍어주세요')),
      // You must wait until the controller is initialized before displaying the camera preview.
      // Use a FutureBuilder to display a loading spinner until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 60), // 화면 가로 방향으로 버튼이 차지할 최소 크기
            // 여기에 추가 스타일을 적용할 수 있습니다.
          ),
          onPressed: () async {
            try {
              await _initializeControllerFuture;
              final image = await _controller.takePicture();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DisplayPictureScreen(imagePath: image.path, previousRoom:previousRoom, previousDoc:previousDoc),
                ),
              );
            } catch (e) {
              print(e);
            }
          },
          child: Icon(Icons.camera_alt, size: 24), // Icon 크기 조정 가능
        ),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.

class DisplayPictureScreen extends StatefulWidget {

  final String imagePath;
  final previousRoom;
  final previousDoc;

  DisplayPictureScreen({
    Key? key,
    required this.imagePath,
    required this.previousRoom,
    required this.previousDoc,
  }) : super(key: key);

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}
class _DisplayPictureScreenState extends State<DisplayPictureScreen> {

  String _recognizedText = "";

  Map<String, TextEditingController> controllers = {};
  Map<String, dynamic> patientInformation =  {"id":"", "환자번호":"", '이름':"", '성별':"", '나이':"", "Room":"", "생일":"", "의사":"", "날짜":"", "시간":"",
    "위검진_외래" : "검진", "위수면_일반":"수면", "위조직":"0", "CLO":false, "위절제술":"0", "위응급":false, "PEG":false,
    "위내시경":{},
    "대장검진_외래":"외래", "대장수면_일반":"수면", "대장조직":"0", "대장절제술":"0", "대장응급":false,
    "대장내시경":{},
    "sig": {}, "sig조직":"0","sig절제술":"0","sig응급":false,
  };
  final firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    getRecognizedText(widget.imagePath);
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List extractInfo(String inputString, String divider) {
    // ": " 문자열로 입력을 나눕니다.
    List<String> parts = inputString.split(divider);
    // 나눈 부분 중 두 번째 요소(환자 번호)를 반환합니다.
    if (parts.length > 1) {
      return parts;
    } else {
      return ["info", "no Data"];
    }
  }


  Future<Map> getRecognizedText(String imagePath) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    final String today = DateFormat("yyyy-MM-dd").format(DateTime.now());

    String scannedText = "";

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        scannedText += "${line.text}\n";
        if (line.text.contains("환자번호")) {
          patientInformation['환자번호'] = extractInfo(line.text, ": ")[1];
        }
        if(line.text.contains("이름")) {
          patientInformation["이름"] = extractInfo(line.text, ": ")[1];
        }
        if(line.text.contains("성별/나이")) {
          final List genderAge = extractInfo(extractInfo(line.text, ": ")[1], "/") ;
          patientInformation["성별"] =  genderAge[0];
          patientInformation["나이"] = genderAge[1];
        }
        if(line.text.contains("생년월일")) {
          patientInformation["생일"] = extractInfo(line.text, ": ")[1];
        }
      }
    }

    for (var key in patientInformation.keys) {
      if (key == '환자번호' || key == "이름" || key =='성별' || key =='나이' || key =='생일') {
        TextEditingController controller = TextEditingController(text: patientInformation[key]);
        controllers[key] = controller; // Map에 TextEditingController를 저장합니다.
      }

    }

    setState(() {
      _recognizedText = scannedText; // Update the state with the recognized text
    });

    textRecognizer.close(); // It's good practice to close the recognizer when it's no longer needed

    return patientInformation;
  }


  @override
  Widget build(BuildContext context) {

    String imagePath = widget.imagePath;
    String previousRoom = widget.previousRoom;
    String previousDoc = widget.previousDoc;

    String generateUniqueId() {
      var uuid = Uuid();
      return uuid.v4(); // v4는 랜덤 UUID를 생성합니다.
    }

    return Scaffold(
        appBar: AppBar(title: Text('Display the Picture')),
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        body: SingleChildScrollView( // Use SingleChildScrollView to avoid overflow
          child: Column(
            children: [
              Image.file(
                File(widget.imagePath),
                width: 300,
                height: 300,
                fit: BoxFit.scaleDown
              ), // Show the image
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildPatientInformationForm(),
                // child: Text(
                //   _recognizedText.isEmpty ? 'Recognizing text...' : _recognizedText, // Show recognized text
                //   textAlign: TextAlign.left,
                // ),
              ),
              ElevatedButton(
                  onPressed: () async {
                    DateTime now = DateTime.now();
                    patientInformation['날짜'] = DateFormat('yyyy-MM-dd').format(now);
                    patientInformation['id'] = generateUniqueId();
                    patientInformation['Room'] = previousRoom;
                    patientInformation['의사'] = previousDoc;
                    patientInformation['시간'] = DateFormat('HH:mm').format(now);
                    patientInformation['위검진_외래'] = '검진';
                    patientInformation['위수면_일반'] = '수면';
                    patientInformation['위조직'] = "0";
                    patientInformation['CLO'] = false;
                    patientInformation['위내시경'] = {};
                    patientInformation['위절제술'] = "0";
                    patientInformation['위응급'] = false;
                    patientInformation['PEG'] = false;

                    patientInformation['대장검진_외래'] = "검진";
                    patientInformation['대장수면_일반'] = "수면";
                    patientInformation['대장조직'] = "0";
                    patientInformation['대장절제술'] = "0";
                    patientInformation['대장응급'] = false;
                    patientInformation['대장내시경'] = {};
                    patientInformation['sig조직'] = "0";
                    patientInformation['sig절제술'] = "0";
                    patientInformation['sig응급'] = false;
                    patientInformation['sig'] = {};
                    try {
                      String docName = patientInformation['이름']! + "_" + patientInformation['날짜']! + "_" + patientInformation['id']! ;
                      await firestore.collection('patients').doc(docName).set(patientInformation);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('환자 정보가 저장되었습니다.'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('환자 정보 저장 중 오류가 발생했습니다: $e'),
                        ),
                      );
                    }

                    Navigator.popUntil(context, ModalRoute.withName('/'));
                    Navigator.pushReplacementNamed(context, '/', arguments: patientInformation);
                  },
                  child: Text('저장'))
            ],
          ),
        )
    );
  }
  Widget _buildPatientInformationForm() {
    List<Widget> fields = controllers.keys
        .where((String key) => key != 'id' && key != '날짜' && key !="Room" && key != "의사")
        .map((String key) {
      return TextField(
        controller: controllers[key],
        decoration: InputDecoration(
          labelText: key, // 각 TextField의 라벨을 키 값으로 설정
        ),
        onChanged: (value) {
          patientInformation[key] = value;// 필요한 경우 여기에서 변경 사항을 처리할 수 있습니다.
        },
      );
    }).toList();

    return Column(children: fields);
  }
}
