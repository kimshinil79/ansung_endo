import 'package:flutter/material.dart';

class endoscopyButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
      style: ButtonStyle(
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            side: BorderSide(
              width: 2.0,
              color: isSelected ? Colors.red : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
