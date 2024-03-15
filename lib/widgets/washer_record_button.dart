// washer_button.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WasherRecordButton extends StatelessWidget {
  final String machineName;
  final int scopyCount;
  final VoidCallback onPressed;
  final String lastChangeDate;

  const WasherRecordButton({
    Key? key,
    required this.machineName,
    required this.scopyCount,
    required this.onPressed,
    required this.lastChangeDate,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yy/MM/dd').format(DateTime.parse(lastChangeDate));

    return ElevatedButton(
      onPressed: onPressed,
      child: Column(
        children: <Widget>[
          Text('$machineName($scopyCount)'),
          Text(formattedDate),
        ],
      ),
      style: ButtonStyle(
        padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.zero),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // 모서리를 직선으로 설정
          ),
        ),
      ),
    );
  }
}
