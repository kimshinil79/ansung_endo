import 'package:flutter/material.dart';

class machineButton extends StatefulWidget {
  final int index;
  final String machineName;
  final bool isPressedMachine;
  final int selectedIndexMachine;
  final Function(int, String) onPressedMachine;

  machineButton({
    Key? key,
    required this.index,
    required this.machineName,
    required this.isPressedMachine,
    required this.selectedIndexMachine,
    required this.onPressedMachine,
  }) : super(key: key);

  @override
  _machineButtonState createState() => _machineButtonState();
}

class _machineButtonState extends State<machineButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 1.1; // 클릭 시 10% 크기 증가
      print ('clicked1');
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0; // 클릭 해제 시 원래 크기로 복귀
    });
    print ('clicked2');
    widget.onPressedMachine(widget.index, widget.machineName);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      child: Transform.scale(
        scale: widget.isPressedMachine && widget.selectedIndexMachine == widget.index ? 1.1:1.0,
        child: ElevatedButton(
          onPressed: null, // GestureDetector가 처리하므로 여기서는 비활성화
          child: Text(
            widget.machineName,
            style: TextStyle(color: Colors.white),
          ),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
                widget.isPressedMachine && widget.selectedIndexMachine == widget.index ? Colors.indigo : Colors.lightBlueAccent,
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                side: BorderSide(
                  width: widget.isPressedMachine && widget.selectedIndexMachine == widget.index ? 3.0 : 2.0,
                  color: widget.isPressedMachine && widget.selectedIndexMachine == widget.index
                      ? Colors.lightBlueAccent
                      : Colors.indigo,
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
