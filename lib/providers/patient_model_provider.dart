import 'package:flutter/foundation.dart';

class PatientModel with ChangeNotifier {

  Map<String, dynamic> patientAndExamInformation = {};

  void updatePatient(Map<String, dynamic> patient) {
    patientAndExamInformation = patient;

    notifyListeners();  // 이 메서드가 호출되면, 이 객체를 듣고 있는 리스너들(위젯들)이 재빌드됩니다.
  }
}

