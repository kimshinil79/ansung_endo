import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ansung_endo/providers/patient_model_provider.dart';
import 'package:provider/provider.dart';

class sortDetail extends StatefulWidget {

  final DateTime startDate;
  final DateTime endDate;
  final TabController tabController;

  sortDetail({
    Key?  key,
    required this.startDate,
    required this.endDate,
    required this.tabController,
}):super(key:key);

  @override
  _sortDetailState createState() => _sortDetailState();
}

class _sortDetailState extends State<sortDetail> {

  List<String> queryConditions = [];
  String selectedDoc = "";
  List<String> docs = ['이병수', '권순범', '김신일', '한융희', '이기섭'];
  String selectedRoom = "";
  List<String> Rooms = ['1', '2', '3'];
  Map<String, String> gsfRelatedItems = {'일반':"위-일반", "외래":"위-외래", "수면":"위-수면","검진":"위-검진", "Bx":"위-Bx", "Polypectomy":"위-polypectomy",
                "CLO":"CLO", "PEG":"PEG", "응급":"위-응급", "위내시경":"위내시경"};
  Map<String, String> csfRelatedItems = {'일반':"대장-일반", "외래":"대장-외래", "수면":"대장-수면","검진":"대장-검진", "Bx":"대장-Bx", "Polypectomy":"대장-polypectomy",
    "응급":"대장-응급", "대장내시경":"대장내시경"};
  Map<String, String> sigRelatedItems = {"Bx":"sig-Bx", "Polypectomy":"sig-polypectomy","응급":"Sig-응급", "S상결장경":"S상결장경"};


  bool gsf =false;
  bool gsfNonGumjin = false;
  bool gsfGumjin = false;
  bool gsfSleep = false;
  bool gsfNonSleep = false;
  bool gsfBx = false;
  bool gsfPolypectomy = false;
  bool CLO = false;
  bool PEG = false;
  bool gsfEmergency = false;

  bool csf = false;
  bool csfNonGumjin = false;
  bool csfGumjin = false;
  bool csfSleep = false;
  bool csfNonSleep = false;
  bool csfBx = false;
  bool csfPolypectomy = false;
  bool csfEmergency = false;

  bool sig = false;
  bool sigBx = false;
  bool sigPolypectomy = false;
  bool sigEmergency = false;




  Widget _dropDownMenu(String title, List<String> items, String selectedItem) {
    // 'None' 옵션을 특별히 처리하지 않고, 단지 드롭다운 목록에만 표시
    List<String> menuItems = ['None', ...items];

    return Expanded(
      child: DropdownButton<String>(
        itemHeight: 50,
        // 선택된 아이템이 없거나 'None'이 선택된 경우, value를 null로 설정
        value: selectedItem.isEmpty || selectedItem == 'None' ? null : selectedItem,
        // 언제나 title을 보여주기 위해 hint 사용
        hint: Center(
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
        items: menuItems.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value == 'None' ? null : value,  // 'None' 선택 시 null 값을 할당하여 드롭다운에 아무 것도 선택되지 않은 것처럼 보이게 함
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    value == 'None' ? "-" : (title == "Room" ? value + '번방' : value),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            if (newValue == null || newValue == 'None') {
              // 'None' 선택 시 또는 null인 경우 내부 상태를 비워 '선택 없음' 상태를 반영
              if (title == '의사') {
                selectedDoc = '';
                queryConditions.removeWhere((element) => docs.contains(element));
              } else if (title == "Room") {
                selectedRoom = '';
                queryConditions.removeWhere((element) => Rooms.contains(element[0]));
              }
            } else {
              // 다른 값이 선택되면, 해당 값을 저장
              if (title == '의사') {
                docs.forEach((element) {
                  if(queryConditions.contains(element)) {
                    queryConditions.remove(element);
                  }
                });
                selectedDoc = newValue;
                queryConditions.add(selectedDoc);
              } else if (title == "Room") {
                Rooms.forEach((element) {
                  if(queryConditions.contains(element+'번방')) {
                    queryConditions.remove(element+'번방');
                  }
                });
                selectedRoom = newValue;
                queryConditions.add(selectedRoom+'번방');
              }
            }
          });
        },
      ),
    );
  }

  Widget checkBoxWidget(String title, String source, bool value, Function(bool?) onChanged) {

    return Row(
      children: [
        Text(title, style: TextStyle(fontWeight: value? FontWeight.bold:FontWeight.normal)),
        Checkbox(
            value: value,
            onChanged: (newValue) {
              setState(() {
                value = newValue!;
                if (value) {
                  if (source == "gsf") {
                    if (!queryConditions.contains(gsfRelatedItems[title]) && value) {
                      queryConditions.add(gsfRelatedItems[title]!);
                      queryConditions.remove('위내시경');
                    }
                  }
                  if (source == "csf") {
                    if (!queryConditions.contains(csfRelatedItems[title]) && value) {
                      queryConditions.add(csfRelatedItems[title]!);
                      queryConditions.remove('대장내시경');
                    }
                  }
                  if (source =="sig") {
                    if (!queryConditions.contains(sigRelatedItems[title]) && value) {
                      queryConditions.add(sigRelatedItems[title]!);
                      queryConditions.remove('S상결장경');
                    }
                  }
                } else {
                  if (source == "gsf") {
                    queryConditions.remove(gsfRelatedItems[title]);
                    if (title == "위내시경") {
                      queryConditions.removeWhere((element) => gsfRelatedItems.containsValue(element));
                      gsfNonGumjin = false;
                      gsfGumjin = false;
                      gsfSleep = false;
                      gsfNonSleep = false;
                      gsfBx = false;
                      gsfPolypectomy = false;
                      CLO = false;
                      PEG = false;
                      gsfEmergency = false;
                    }
                  }
                  if (source == "csf") {
                    queryConditions.remove(csfRelatedItems[title]);
                    if (title == "대장내시경") {
                      queryConditions.removeWhere((element) => csfRelatedItems.containsValue(element));
                      csf = false;
                      csfNonGumjin = false;
                      csfGumjin = false;
                      csfSleep = false;
                      csfNonSleep = false;
                      csfBx = false;
                      csfPolypectomy = false;
                      csfEmergency = false;
                    }
                  }
                  if (source == "sig") {
                    queryConditions.remove(sigRelatedItems[title]);
                    if (title == "S상결장경") {
                      queryConditions.removeWhere((element) => sigRelatedItems.containsValue(element));
                      sigBx = false;
                      sigPolypectomy = false;
                      sigEmergency = false;
                    }
                  }
                }
                onChanged(value);
                List<String> tempQueryConditions = [];
                for (var item in [...gsfRelatedItems.values, ...csfRelatedItems.values, ...sigRelatedItems.values]) {
                  if (queryConditions.contains(item)) {
                    tempQueryConditions.add(item);
                  }
                }
                queryConditions = tempQueryConditions;
                print ('queryConditions: $queryConditions');
              });
            }
        ),
      ],
    );
  }

  Future<List> _searchPatientAndCondition() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    var querySnapshot = await firestore.collection('patients').
    where('날짜', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(widget.startDate!)).
    where('날짜', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(widget.endDate!)).get();

    List<Map<String, dynamic>> finalList = [];
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      finalList.add(data);
    }
    if (selectedDoc.isNotEmpty) {
      finalList = finalList.where((data)=> data['의사']==selectedDoc).toList();
    }
    if (selectedRoom.isNotEmpty) {
      finalList = finalList.where((data)=> data['Room']==selectedRoom).toList();
    }
    if (gsf) {
      finalList = finalList.where((data)=> data['위내시경'].length !=0).toList();
      List<Map<String, dynamic>> tempGSFList = [];
      List<Map<String, dynamic>> tempGSFGumjinList = [];
      List<Map<String, dynamic>> tempGSFNonGumjinList = [];
      List<Map<String, dynamic>> tempGSFSleepingList = [];
      List<Map<String, dynamic>> tempGSFNonSleepingList = [];
      if (gsfGumjin || gsfNonGumjin) {
        if (gsfGumjin) {
          tempGSFGumjinList = finalList.where((data)=> data['위검진_외래']=="검진").toList();
        }
        if (gsfNonGumjin) {
          tempGSFNonGumjinList = finalList.where((data)=> data['위검진_외래']=="외래").toList();
        }
      }
      tempGSFList = {...tempGSFGumjinList, ...tempGSFNonGumjinList}.toList();
      if (gsfGumjin || gsfNonGumjin ) {
        finalList = tempGSFList;
      }

      if (gsfSleep || gsfNonSleep) {
        if (gsfSleep) {
          tempGSFSleepingList = finalList.where((data)=> data['위수면_일반']=="수면").toList();
        }
        if (gsfNonSleep) {
          tempGSFNonSleepingList = finalList.where((data)=> data['위수면_일반']=="일반").toList();
        }
        tempGSFList = {...tempGSFSleepingList, ...tempGSFNonSleepingList}.toList();
      }
      if (gsfSleep || gsfNonSleep) {
        finalList = tempGSFList;
      }


      if (gsfBx) {
        finalList = finalList.where((data)=> data['위조직'] != '0').toList();
      }
      if (gsfPolypectomy) {
        finalList = finalList.where((data)=> data['위절제술'] != '0').toList();
      }
      if (CLO) {
        finalList = finalList.where((data)=> data['CLO'] == true).toList();
      }
      if (gsfEmergency) {
        finalList = finalList.where((data)=> data['위응급'] == true).toList();
      }
      if (PEG) {
        finalList = finalList.where((data)=> data['PEG'] == true).toList();
      }
    }

    if (csf) {
      finalList = finalList.where((data)=> data['대장내시경'].length !=0).toList();
      List<Map<String, dynamic>> tempCSFList = [];
      List<Map<String, dynamic>> tempCSFGumjinList = [];
      List<Map<String, dynamic>> tempCSFNonGumjinList = [];
      List<Map<String, dynamic>> tempCSFSleepingList = [];
      List<Map<String, dynamic>> tempCSFNonSleepingList = [];
      if (csfGumjin || csfNonGumjin) {
        if (csfGumjin) {
          tempCSFGumjinList = finalList.where((data)=> data['대장검진_외래']=="검진").toList();
        }
        if (csfNonGumjin) {
          tempCSFNonGumjinList = finalList.where((data)=> data['대장검진_외래']=="외래").toList();
        }
      }
      tempCSFList = {...tempCSFGumjinList, ...tempCSFNonGumjinList}.toList();
      if (csfGumjin || csfNonGumjin ) {
        finalList = tempCSFList;
      }

      if (csfSleep || csfNonSleep) {
        if (csfSleep) {
          tempCSFSleepingList = finalList.where((data)=> data['대장수면_일반']=="수면").toList();
        }
        if (csfNonSleep) {
          tempCSFNonSleepingList = finalList.where((data)=> data['대장수면_일반']=="일반").toList();
        }
        tempCSFList = { ...tempCSFSleepingList, ...tempCSFNonSleepingList}.toList();
      }
      if (csfSleep || csfNonSleep) {
        finalList = tempCSFList;
      }

      if (csfBx) {
        finalList = finalList.where((data)=> data['대장조직'] != '0').toList();
      }
      if (csfPolypectomy) {
        finalList = finalList.where((data)=> data['대장절제술'] != '0').toList();
      }

      if (csfEmergency) {
        finalList = finalList.where((data)=> data['대장응급'] == true).toList();
      }


    }
    if (sig) {
      finalList = finalList.where((data)=> data['sig'].length !=0).toList();

      if (sigBx) {
        finalList = finalList.where((data)=> data['sig조직'] != '0').toList();
      }
      if (sigPolypectomy) {
        finalList = finalList.where((data)=> data['sig절제술'] != '0').toList();
      }

      if (sigEmergency) {
        finalList = finalList.where((data)=> data['sig응급'] == true).toList();
      }
    }

    return finalList;
  }

  Map<String, String> createSummaryFromDoc(Map<String, dynamic> doc) {
    String gsfSummary = "";
    String csfSummary = "";
    String sigSummary = "";


    if (doc['위내시경'].isNotEmpty) {
      gsfSummary = gsfSummary+'위('+doc['위검진_외래'] + " "+doc['위수면_일반']+", scope:";

      for (var scope in doc['위내시경'].keys.toList()) {
        gsfSummary += scope+" ";
      }
      if(doc['위조직'] != "0") {
        gsfSummary += ', Bx:'+doc['위조직'];
      }
      if(doc['위절제술'] != "0") {
        gsfSummary += ' ,용종절제술:'+doc['위절제술'];
      }
      if(doc['CLO']) {
        gsfSummary += ', CLO, ';
      }
      gsfSummary+=')';
    }
    if (doc['대장내시경'].isNotEmpty) {
      csfSummary = csfSummary+'대장('+doc['대장검진_외래'] + " "+doc['대장수면_일반']+", scope:";

      for (var scope in doc['대장내시경'].keys.toList()) {
        csfSummary += scope+" ";
      }
      if(doc['대장조직'] != "0") {
        csfSummary += ', Bx:'+doc['대장조직'];
      }
      if(doc['대장절제술'] != "0") {
        csfSummary += ', 용종절제술:'+doc['대장절제술'];
      }
      csfSummary += ')';
    }
    if (doc['sig'].isNotEmpty) {

      sigSummary += 'sig( ';
      for (var scope in doc['sig'].keys.toList()) {
        sigSummary += scope+" ";
      }
      if(doc['sig조직'] != "0") {
        sigSummary += 'Bx:'+doc['sig조직']+", ";
      }
      if(doc['sig절제술'] != "0") {
        sigSummary += '용종절제술:'+doc['sig절제술'] + ", ";
      }
      sigSummary += ")";
    }

    return {'gsfSummary':gsfSummary, 'csfSummary':csfSummary, 'sigSummary':sigSummary};
  }


  void _showPatientsInfo() async {
    List sortedList = await _searchPatientAndCondition();
    String formattedStartDate = DateFormat('yy-MM-dd').format(widget.startDate!);
    String formattedEndDate = DateFormat('yy-MM-dd').format(widget.endDate!);
    String queryConditionsAsString = formattedStartDate == formattedEndDate? formattedStartDate+", "
        : '$formattedStartDate~$formattedEndDate, ';
    queryConditions.forEach((element) {
      queryConditionsAsString += element+", ";
    });
    if (queryConditionsAsString.endsWith(', ')) {
      queryConditionsAsString = queryConditionsAsString.substring(0, queryConditionsAsString.length-2);
    }


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('환자 정보 (총:${sortedList.length}명)'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('검색조건 : ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),),
                Text(queryConditionsAsString, style: TextStyle(fontStyle: FontStyle.italic),),
                SizedBox(height: 10,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedList.map((doc) {
                    Map<String, String> fullSummary = createSummaryFromDoc(doc);
                    final String gsfSummary =fullSummary['gsfSummary']!;
                    final String csfSummary =fullSummary['csfSummary']!;
                    final String sigSummary =fullSummary['sigSummary']!;

                    return Container(
                      margin: EdgeInsets.all(4.0),
                      padding: EdgeInsets.all(2),
                      width: double.infinity,// 각 타일 사이의 공간을 추가합니다.
                      decoration: BoxDecoration(
                        color: Colors.purple[50], // 배경색 설정
                        border: Border.all(
                          color: Colors.deepPurpleAccent, // 테두리 색상
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
                      child: GestureDetector(
                        onTap:() {
                          Provider.of<PatientModel>(context, listen: false).updatePatient(doc);
                          Navigator.of(context).pop(); // 다이얼로그 닫기
                          widget.tabController.animateTo(0);

                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                '${doc['이름']}(${doc['환자번호']}), ${doc['성별']}/${doc['나이']}, ${doc['날짜'].substring(5)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),

                              ),
                            ),
                            SizedBox(height: 5,),
                            if(gsfSummary.isNotEmpty) Text(
                                "> $gsfSummary"
                            ),
                            if(csfSummary.isNotEmpty) Text(
                                "> $csfSummary"
                            ),
                            if(sigSummary.isNotEmpty) Text(
                                "> $sigSummary"
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                    'done by ${doc['의사']}',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey
                                    ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      // 여기서 필요한 정보를 추가하시면 됩니다.
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('닫기'),
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
    return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: <Widget>[
                  Text('의사: ', style: TextStyle(fontWeight: FontWeight.bold),),
                  SizedBox(width: 10,),
                  _dropDownMenu('의사', docs, selectedDoc),
                  SizedBox(width: 30,),
                  Text('Room: ', style: TextStyle(fontWeight: FontWeight.bold),),
                  SizedBox(width: 10,),
                  _dropDownMenu('Room', Rooms, selectedRoom),
                ],
              ),

              checkBoxWidget('위내시경', "gsf", gsf, (bool? value) => setState(() => gsf = value!)),
              gsf? Container(
                padding: EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: Colors.lightBlue[50], // 배경색 설정
                  border: Border.all(
                    color: Colors.blue, // 테두리 색상
                    width: 3.0, // 테두리 두께
                  ),
                  borderRadius: BorderRadius.circular(12), // 테두리 둥글게
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        checkBoxWidget('외래', "gsf", gsfNonGumjin, (bool? value) => setState(() => gsfNonGumjin = value!)),
                        checkBoxWidget('검진', "gsf", gsfGumjin, (bool? value) => setState(() => gsfGumjin = value!)),
                        checkBoxWidget('수면', "gsf", gsfSleep, (bool? value) => setState(() => gsfSleep = value!)),
                        checkBoxWidget('일반', "gsf", gsfNonSleep, (bool? value) => setState(() => gsfNonSleep = value!)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        checkBoxWidget('Bx', "gsf", gsfBx, (bool? value) => setState(() => gsfBx = value!)),
                        checkBoxWidget('CLO', "gsf", CLO, (bool? value) => setState(() => CLO = value!)),
                        checkBoxWidget('Polypectomy', "gsf", gsfPolypectomy, (bool? value) => setState(() => gsfPolypectomy = value!)),
                      ],
                    ),
                    Row(
                      children: [
                        checkBoxWidget('PEG', "gsf", PEG, (bool? value) => setState(() => PEG = value!)),
                        checkBoxWidget('응급', "gsf", gsfEmergency, (bool? value) => setState(() => gsfEmergency = value!)),
                      ],
                    )
                  ],
                ),
              ):SizedBox(),
              SizedBox(height: 10,),
              checkBoxWidget('대장내시경', "csf", csf, (bool? value) => setState(() => csf = value!)),
              csf? Container(
                padding: EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50], // 배경색 설정
                  border: Border.all(
                    color: Colors.purple, // 테두리 색상
                    width: 3.0, // 테두리 두께
                  ),
                  borderRadius: BorderRadius.circular(12), // 테두리 둥글게
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        checkBoxWidget('외래', "csf", csfNonGumjin, (bool? value) => setState(() => csfNonGumjin = value!)),
                        checkBoxWidget('검진', "csf", csfGumjin, (bool? value) => setState(() => csfGumjin = value!)),
                        checkBoxWidget('수면', "csf", csfSleep, (bool? value) => setState(() => csfSleep = value!)),
                        checkBoxWidget('일반', "csf", csfNonSleep, (bool? value) => setState(() => csfNonSleep = value!)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        checkBoxWidget('Bx', "csf", csfBx, (bool? value) => setState(() => csfBx = value!)),
                        checkBoxWidget('Polypectomy', "csf", csfPolypectomy, (bool? value) => setState(() => csfPolypectomy = value!)),
                        checkBoxWidget('응급', "csf", csfEmergency, (bool? value) => setState(() => csfEmergency = value!)),
                      ],
                    ),
                  ],
                ),
              ):SizedBox(),
              SizedBox(height: 10,),
              checkBoxWidget('S상결장경', "sig", sig, (bool? value) => setState(() => sig = value!)),
              sig? Container(
                padding: EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: Colors.green[50], // 배경색 설정
                  border: Border.all(
                    color: Colors.green, // 테두리 색상
                    width: 3.0, // 테두리 두께
                  ),
                  borderRadius: BorderRadius.circular(12), // 테두리 둥글게
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        checkBoxWidget('Bx', "sig", sigBx, (bool? value) => setState(() => sigBx = value!)),
                        checkBoxWidget('Polypectomy', "sig", sigPolypectomy, (bool? value) => setState(() => sigPolypectomy = value!)),
                        checkBoxWidget('응급', "sig", sigEmergency, (bool? value) => setState(() => sigEmergency = value!)),
                      ],
                    ),
                  ],
                ),
              ):SizedBox(),
              SizedBox(height: 10,),
              ElevatedButton(
                onPressed: () => _showPatientsInfo(),
                child: Text(
                  '검색',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(const Color(0xBFAE1E49)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // 모서리를 둥글지 않게 설정
                    ),
                  ),
                  fixedSize: MaterialStateProperty.all(Size.fromHeight(50)),
                ),
              ),
              
            ],
          ),
        );
  }
}

// Future<List> _searchPatientsOrCondition() async {
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   var querySnapshot = await firestore.collection('patients').
//   where('날짜', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startDate)).
//   where('날짜', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endDate)).get();
//   List<Map<String, dynamic>> finalList = [];
//   List<Map<String, dynamic>> templList = [];
//   List<Map<String, dynamic>> docList = [];
//   List<Map<String, dynamic>> roomList = [];
//   List<Map<String, dynamic>> gsfList = [];
//   List<Map<String, dynamic>> csfList = [];
//   List<Map<String, dynamic>> sigList = [];
//   List<Map<String, dynamic>> gsfGumjinList = [];
//   List<Map<String, dynamic>> csfGumjinList = [];
//   List<Map<String, dynamic>> gsfOutPatientList = [];
//   List<Map<String, dynamic>> csfOutPatientList = [];
//   List<Map<String, dynamic>> gsfSleepList = [];
//   List<Map<String, dynamic>> csfSleepList = [];
//   List<Map<String, dynamic>> gsfNonSleepList = [];
//   List<Map<String, dynamic>> csfNonSleepList = [];
//   List<Map<String, dynamic>> gsfBxList = [];
//   List<Map<String, dynamic>> csfBxList = [];
//   List<Map<String, dynamic>> sigBxList = [];
//   List<Map<String, dynamic>> gsfPolypectomyList = [];
//   List<Map<String, dynamic>> csfPolypectomyList = [];
//   List<Map<String, dynamic>> sigPolypectomyList = [];
//   List<Map<String, dynamic>> CLOList = [];
//   List<Map<String, dynamic>> gsfEmergencyList = [];
//   List<Map<String, dynamic>> csfEmergencyList = [];
//   List<Map<String, dynamic>> sigEmergencyList = [];
//   List<Map<String, dynamic>> PEGList = [];
//
//
//
//
//   for (var doc in querySnapshot.docs) {
//     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//     templList.add(data);
//     }
//   if (selectedDoc.isNotEmpty) {
//     docList = templList.where((data)=> data['의사']==selectedDoc).toList();
//   }
//   if (selectedRoom.isNotEmpty) {
//     roomList = templList.where((data)=> data['Room']==selectedRoom).toList();
//   }
//   if (gsf) {
//     gsfList = templList.where((data)=> data['위내시경'].length !=0).toList();
//     if (gumjin) {
//       gsfGumjinList = templList.where((data)=> data['위검진_외래']=='검진').toList();
//     }
//     if (outPatient) {
//       gsfOutPatientList = templList.where((data)=> data['위검진_외래']=='외래').toList();
//     }
//     if (sleep) {
//       gsfSleepList = templList.where((data)=> data['위수면_일반']=='수면').toList();
//     }
//     if (nonSleep) {
//       gsfNonSleepList = templList.where((data)=> data['위수면_일반']=='일반').toList();
//     }
//     if (Bx) {
//       gsfBxList = templList.where((data)=> data['위조직'] !='0').toList();
//     }
//     if (polypectomy) {
//       gsfPolypectomyList = templList.where((data)=> data['위절제술'] !='0').toList();
//     }
//     if (emergency) {
//       gsfEmergencyList = templList.where((data)=> data['위응급'] == true).toList();
//     }
//   }
//   if(csf) {
//     csfList = templList.where((data)=> data['대장내시경'].length !=0).toList();
//     if (gumjin) {
//       csfGumjinList = templList.where((data)=> data['대장검진_외래']=='검진').toList();
//     }
//     if (outPatient) {
//       gsfOutPatientList = templList.where((data)=> data['대장검진_외래']=='외래').toList();
//     }
//     if (sleep) {
//       csfSleepList = templList.where((data)=> data['대장수면_일반']=='수면').toList();
//     }
//     if (nonSleep) {
//       csfNonSleepList = templList.where((data)=> data['대장수면_일반']=='일반').toList();
//     }
//     if (Bx) {
//       csfBxList = templList.where((data)=> data['대장조직'] !='0').toList();
//     }
//     if (polypectomy) {
//       csfPolypectomyList = templList.where((data)=> data['대장절제술'] !='0').toList();
//     }
//     if (emergency) {
//       csfEmergencyList = templList.where((data)=> data['대장응급'] == true).toList();
//     }
//   }
//   if(sig) {
//     sigList = templList.where((data)=> data['대장검진_외래']=='외래').toList();
//     if (Bx) {
//       sigBxList = templList.where((data)=> data['sig조직'] !='0').toList();
//     }
//     if (polypectomy) {
//       sigPolypectomyList = templList.where((data)=> data['sig절제술'] !='0').toList();
//     }
//     if (emergency) {
//       sigEmergencyList = templList.where((data)=> data['sig응급'] == true).toList();
//     }
//   }
//   if(PEG) {
//     PEGList = templList.where((data)=> data['PEG'] == true).toList();
//   }
//
//   Set<Map<String, dynamic>> finalSet= {...docList, ...roomList, ...gsfList, ...csfList, ...sigList,
//     ...gsfGumjinList, ...csfGumjinList, ...gsfOutPatientList, ...csfOutPatientList, ...gsfSleepList, ...csfSleepList,
//     ...gsfNonSleepList, ...csfNonSleepList, ...gsfBxList, ...csfBxList, ...sigBxList, ...gsfPolypectomyList, ...csfPolypectomyList,
//     ...sigPolypectomyList, ...CLOList, ...gsfEmergencyList, ...csfEmergencyList, ...sigEmergencyList, ...PEGList
//   };
//
//   finalList = finalSet.toList();
//
//   return finalList;
//   }