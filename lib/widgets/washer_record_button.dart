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
    final formattedDate = DateFormat('MM/dd').format(DateTime.parse(lastChangeDate));

    return ElevatedButton(
      onPressed: onPressed,
      child: Column(
        children: <Widget>[
          Text(
              '$machineName',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
          ),
          Text(
              '${scopyCount.toString()}회',
            style: TextStyle(
              //fontWeight: FontWeight.bold,
              color: Colors.white,
            ),),
          Text(formattedDate),
        ],
      ),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.teal.withOpacity(0.5)),
        padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.zero),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: const Color(0xFF007F73), width: 2.0),// 모서리를 직선으로 설정
          ),
        ),
      ),
    );
  }
}
