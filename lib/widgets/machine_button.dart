import 'package:flutter/material.dart';

ElevatedButton machineButton(int index, String machineName, bool isPressedMachine, int selectedIndexMachine, Function(int, String) onPressedMachine) {
  return ElevatedButton(
    onPressed: () => onPressedMachine(index, machineName),
    child: Text(machineName),
    style: ButtonStyle(
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          side: BorderSide(
            width: 2.0,
            color: isPressedMachine && selectedIndexMachine == index
                ? Colors.blue
                : Colors.grey,
          ),
        ),
      ),
    ),
  );
}