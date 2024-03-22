import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExaminationRoom extends StatefulWidget {
  @override
  _ExaminationRoomState createState() => _ExaminationRoomState();
}

class _ExaminationRoomState  extends State<ExaminationRoom> {

  final firestore = FirebaseFirestore.instance;

  Map<String, dynamic> patientAndExamInformation = {"환자번호":"", '이름':"", '성별':"", '나이':"", "생일":"", "의사":"", "날짜":"",
    "위검진_외래" : "", "위수면_일반":"", "위조직":0, "위절제술":0, "위응급":false, "위내시경기계":"",
    "대장검진_외래":"", "대장수면_일반":"", "대장조직":0, "대장절제":0, "대장응급":false, "대장내시경기계":"",
  };

  final List<String> docs = ['이병수', '권순범', '김신일','한융희'];
  final List<String> numAsString = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];



  final Map<String, String> GSFmachine = {'073':'KG391K073', '180':'5G391K180', '153':'5G391K153','256':'7G391K256','257':'7G391k257',
    '259':'7G391K259','407':'2G348K407', '405':'2G348K405','390':'2G348K390', '333':'2G348K333', '694':'5G348K694'};
  final Map<String, String> CSFmachine = {'039':'7C692K039', '166':'6C692K166', '098':'5C692K098', '219':'1C664K219', '379':'1C665K379', '515':'1C666K515',};

  bool? GSF = true;
  bool? CSF = false;
  String? selectedDoctor;
  String appBarDate = "";


  Map<String, TextEditingController> controllders = {};
  Map<String, String> fullPatientInformation = {};

  @override
  void initState() {
    super.initState();
    selectedDoctor = patientAndExamInformation['의사'];
    appBarDate = "Today";
    patientAndExamInformation.forEach((key, value) {
      controllders[key] = TextEditingController(text: value.toString());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute
          .of(context)
          ?.settings
          .arguments as Map<String, dynamic>?;
      print('!!!!');
      if (args != null) {
        // args에서 성별 값이 있을 경우, fullPatientInformation 맵을 데이트합니다.
        // 예를 들어, 성별 값의 키가 '성별'이라고 가정합니다.
        print ('?????${args}');
        setState(() {
          patientAndExamInformation['성별'] = args['성별']; // 'M' 또는 'F'
          patientAndExamInformation['환자번호'] = args['환자번호'] ?? patientAndExamInformation['환자번호'];
          controllders['환자번호']?.text = patientAndExamInformation['환자번호'];
          patientAndExamInformation['이름'] = args['이름'] ?? patientAndExamInformation['이름'];
          controllders['이름']?.text = patientAndExamInformation['이름'];
          patientAndExamInformation['나이'] = args['나이'] ?? patientAndExamInformation['나이'];
          controllders['나이']?.text = patientAndExamInformation['나이'];
          patientAndExamInformation['생일'] = args['생일'] ?? patientAndExamInformation['생일'];
          controllders['생일']?.text = patientAndExamInformation['생일'];
          // patientAndExamInformation['위검진/외래'] = args['위검진/외래'];
          // patientAndExamInformation['위수면/일반'] = args['위수면/일반'];
          // patientAndExamInformation['위조직'] = args['위조직'];
          // patientAndExamInformation['위절제술'] = args['위절제술'];
          // patientAndExamInformation['위내시경기계'] = GSFmachine[args['위내시경기계']];
          // patientAndExamInformation['위응급'] = args['위응급'];
          // patientAndExamInformation['대장검진/외래'] = args['대장검진/외래'];
          // patientAndExamInformation['대장수면/일반'] = args['대장수면/일반'];
          // patientAndExamInformation['대장조직'] = args['대장조직'];
          // patientAndExamInformation['대장절제술'] = args['대장절제술'];
          // patientAndExamInformation['대장내시경기계'] = CSFmachine[args['대장내시경기계']] ;
          // patientAndExamInformation['대장응급'] = args['대장응급'];
        });
      }
    });
  }

  @override
  void dispose() {
    controllders.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Future<void> updatePatientAndExamInfo(String patientNumber, String name, Map<String, dynamic> newInfo) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    print ('여기는 함수 안');
    
    QuerySnapshot querySnapshot = await firestore.collection('patients').where('환자번호', isEqualTo:patientNumber).where('이름', isEqualTo: name).get();
    print ('query:$querySnapshot');

    if (querySnapshot.docs.isEmpty) {
      print ('해당하는 환자 정보를 찾을 수 없습니다. ');
    } else {
      for (var doc in querySnapshot.docs) {
        await firestore.collection('patients').doc(doc.id).update(newInfo);
        print ('문서 업데이트 완료');
      }
    }
  }

  Widget _buildRadioSelection(String title, String firstElement, String secondElement) {
    return Container(
      padding: EdgeInsets.all(1.0), // 내부 여백을 추가합니다.
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black54, // 테두리 색상
          width: 1.0, // 테두리 두께
        ),
        borderRadius: BorderRadius.circular(5.0), // 테두리 모서리를 둥글게 합니다.
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
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
    return TextFormField(
      controller: controllders[title],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: title,
        labelStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold, // 글씨를 굵게
          color: Colors.red, // 색상을 빨간색으로
        ),
        border: OutlineInputBorder( // 테두리 추가
          borderSide: BorderSide(
            color: Colors.blue, // 테두리 색상
            width: 2.0, // 테두리 두께
          ),
        ),
      ),
      onChanged: (value) {
        patientAndExamInformation[title] = value;
        //controllders['이름']?.text = value;
      },
    );
  }

  Widget _dropDownInExamRoom(String title, List<String> items) {
    return DropdownButton<String> (
      itemHeight: 70,
      value: items.contains(patientAndExamInformation[title])
          ? patientAndExamInformation[title]
          : null,
      hint: Text(title),
      isExpanded: true,
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          patientAndExamInformation[title] = value;
        });
      },
    );
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
        patientAndExamInformation['날짜'] = selectedDate;
      });
    }
  }


  Widget _buildForm(Map<String, dynamic> fullPatientInformation) {

    if (patientAndExamInformation != null ) {
      print ('haha:$patientAndExamInformation');
    }

    final DateFormat DateFormatForAppBarDate = DateFormat('yyyy-MM-dd');

    final String formattedDateForAppBar = DateFormatForAppBarDate.format(selectedDate);
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
            // Expanded(
            //   child: Text('의사', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
            // ),
            Expanded(
                child: _dropDownInExamRoom('의사', docs),
            ),
            Expanded(
              child:ElevatedButton(
                onPressed:() => _selectDate(context),
                child: Text(
                    appBarDate,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15
                    )
                ),
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero
                    )
                  )
                ),

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
                        Text('위 내시경', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Checkbox(
                          tristate:false,
                          value: GSF,
                          onChanged: (value) {
                            setState(() {
                              GSF = value;
                            });
                          },
                        ),
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
                            Row(
                              children: [
                                Expanded(
                                    child: _dropDownInExamRoom('위조직', numAsString )),
                                SizedBox(width: 10,),
                                Expanded(
                                    child:  _dropDownInExamRoom('위절제술', numAsString )),
                                SizedBox(width: 10,),
                                Expanded(
                                    child: Row(
                                      children: [
                                        Text('응급', style: TextStyle(fontSize: 18)),
                                        SizedBox(width: 10),
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
                                    ))
                              ],
                            ),
                            SizedBox(width: 10,),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('위내시경 모델명', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                                ),
                                Expanded(
                                  child: _dropDownInExamRoom('위내시경기계', GSFmachine.keys.toList()),
                                )
                              ],
                            ),
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
                        Text('대장 내시경', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                            Row(
                              children: [
                                Expanded(
                                    child: _dropDownInExamRoom('대장조직', numAsString )),
                                SizedBox(width: 10,),
                                Expanded(
                                    child: _dropDownInExamRoom('대장절제', numAsString )),
                                SizedBox(width: 10,),
                                Expanded(
                                    child: Row(
                                      children: [
                                        Text('응급', style: TextStyle(fontSize: 18)),
                                        SizedBox(width: 10),
                                        Checkbox(
                                          tristate:false,
                                          value: patientAndExamInformation['대장응급'],
                                          onChanged: (value) {
                                            setState(() {
                                              patientAndExamInformation['대장응급'] = value;
                                            });
                                          },
                                        ),
                                      ],
                                    ))
                              ],
                            ),
                            SizedBox(width: 10,),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('대장내시경 모델명', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                                ),
                                Expanded(
                                  child: _dropDownInExamRoom('대장내시경기계', CSFmachine.keys.toList()),
                                )
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
    // Obtain a list of the available cameras on the device.
    final cameras = await availableCameras();

    // Get a specific camera from the list of available cameras.
    final firstCamera = cameras.first;

    // Navigate to a new route and pass the camera to it.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePictureScreen(camera: firstCamera),
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

    return Scaffold(
      body: SingleChildScrollView(
        child:Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildForm(patientAndExamInformation),
            ),
            ElevatedButton(
              child: Text('저장'),
              onPressed: () async {
                if (appBarDate == 'Today') {
                  patientAndExamInformation['날짜'] = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
                }
                final String patientNumber = patientAndExamInformation['환자번호'];
                final String patientName = patientAndExamInformation['이름'];
                try {
                  await updatePatientAndExamInfo(patientNumber,patientName, patientAndExamInformation);
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
                print('full:$patientAndExamInformation');
              },
              style: ButtonStyle(
                minimumSize: MaterialStateProperty.all(Size(double.infinity, 40)),
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

  const TakePictureScreen({Key? key, required this.camera}) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
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
                  builder: (context) => DisplayPictureScreen(imagePath: image.path),
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

  DisplayPictureScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}
class _DisplayPictureScreenState extends State<DisplayPictureScreen> {

  String _recognizedText = "";
  Map<String, TextEditingController> controllers = {};
  Map<String, String> patientInformation = {'환자번호':"", '이름':"", '성별':"", '나이':"", "생일":"", "날짜":""};
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
      TextEditingController controller = TextEditingController(text: patientInformation[key]);
      controllers[key] = controller; // Map에 TextEditingController를 저장합니다.
    }

    setState(() {
      _recognizedText = scannedText; // Update the state with the recognized text
    });
    print(" info : $patientInformation");

    textRecognizer.close(); // It's good practice to close the recognizer when it's no longer needed

    return patientInformation;
  }


  @override
  Widget build(BuildContext context) {

    String imagePath = widget.imagePath;

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
                    patientInformation['날짜'] = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

                      try {
                        await firestore.collection('patients').add(patientInformation);
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
                      print('fromCamera:$patientInformation');

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
    List<Widget> fields = controllers.keys.map((String key) {
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
