// washer_button.dart
import 'package:flutter/material.dart';

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
    return ElevatedButton(
      onPressed: onPressed,
      child: Column(
        children: <Widget>[
          Text(machineName),
          Text('$lastChangeDate($scopyCount)'),
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
