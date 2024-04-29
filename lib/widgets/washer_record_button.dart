import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WasherRecordButton extends StatefulWidget {
  final String machineName;
  final int index;
  final int selectedIndexMachine;
  final int scopyCount;
  final Function onLongPressed;
  final Function(int, String) onPressedMachine;
  final bool isPressedMachine;
  final String lastChangeDate;

  const WasherRecordButton({
    Key? key,
    required this.machineName,
    required this.index,
    required this.selectedIndexMachine,
    required this.scopyCount,
    required this.onLongPressed,
    required this.onPressedMachine,
    required this.isPressedMachine,
    required this.lastChangeDate,
  }) : super(key: key);

  @override
  _WasherRecordButtonState createState() => _WasherRecordButtonState();
}

class _WasherRecordButtonState extends State<WasherRecordButton> {
  bool _isSelected = false;  // Tracking selection state
  double sizeIncrease =  1.0;

  void _toggleSelected() {
    setState(() {
      _isSelected = !_isSelected;
      print ('isPressedMachine:${widget.isPressedMachine}');
      print ("_isSelcted: $_isSelected");
      widget.onPressedMachine(widget.index, widget.machineName);
    });

  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      sizeIncrease = 1.2; // 클릭 시 10% 크기 증가
      print ('clicked1 ');
      widget.onPressedMachine(widget.index, widget.machineName);
    });

  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      sizeIncrease = 1.0; // 클릭 해제 시 원래 크기로 복귀
      print ('clicked2');
    });

  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MM/dd').format(DateTime.parse(widget.lastChangeDate));

    double screenWidth = MediaQuery.of(context).size.width;
    double paddingForButton = 10;

    return GestureDetector(
      //onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      //onLongPress: () => widget.onLongPressed(),  // Trigger function passed from parent
      child: Transform.scale(
        scale: widget.isPressedMachine && widget.selectedIndexMachine == widget.index ? 1.2:1.0,
        // duration: Duration(milliseconds: 500),
        // width: (screenWidth- paddingForButton*6)/5 * sizeIncrease,  // Base size is 100, adjust according to state
        // height: 70 * sizeIncrease,
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(10),
        //   border: Border.all(
        //     color: _isSelected ? Colors.indigoAccent : Color(0xFF007F73),
        //     width: 2,
        //   ),
        // ),
        child: ElevatedButton(
          onPressed: () => widget.onPressedMachine(widget.index, widget.machineName),  // Disable button's own press functionality
          onLongPress: () => widget.onLongPressed(),  // Disable button's own long press to handle it outside
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                widget.machineName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${widget.scopyCount}회',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              Text(formattedDate),
            ],
          ),
          style: ButtonStyle(
            backgroundColor:widget.isPressedMachine && widget.selectedIndexMachine == widget.index ? MaterialStateProperty.all(Colors.teal.withOpacity(0.8)) : MaterialStateProperty.all(Colors.teal.withOpacity(0.3)),
            padding: MaterialStateProperty.all(EdgeInsets.zero),
            shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                  color: _isSelected?Colors.indigoAccent : Color(0xFF007F73),
                  width: 2.0),  // Invisible border on button itself
            )
            ),
          ),
        ),
      ),
    );
  }
}
