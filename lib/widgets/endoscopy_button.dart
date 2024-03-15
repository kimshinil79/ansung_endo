import 'package:flutter/material.dart';

class endoscopyButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isSelected;

  const endoscopyButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.isSelected = false,
  }) : super(key: key);

  @override
  _endoscopyButtonState createState() => _endoscopyButtonState();
}

class _endoscopyButtonState extends State<endoscopyButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 1.1; // 클릭 시 10% 크기 증가
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.1; // 클릭 해제 시 원래 크기로 복귀
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      child: Transform.scale(
        scale: widget.isSelected ? 1.1:1.0,
        child: ElevatedButton(
          onPressed: null, // GestureDetector가 처리하므로 여기서는 null 처리
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
                widget.isSelected ? const Color(0xFFFFF455) : const Color(0xFFFFC700),

            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // 모서리 둥글게 처리 제거
                side: BorderSide(
                  width: widget.isSelected ? 3.0:2.0,
                  color: widget.isSelected ? const Color(0xFFFFF455) : const Color(0xFFFFF455)
                ),
              ),
            ),
          ),
          child: Text(
            widget.text,
            style: TextStyle(color: Colors.indigo),
          ),
        ),
      ),
    );
  }
}
