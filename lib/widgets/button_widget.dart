// import 'package:flutter/material.dart';

// class ButtonWidget extends StatelessWidget {
//   final String text;
//   final bool isPressed;
//   final VoidCallback onPressed;

//   const ButtonWidget({
//     Key key,
//     this.text,
//     this.isPressed = false,
//     this.onPressed,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: onPressed,
//       child: Text(text),
//       style: ButtonStyle(
//         shape: MaterialStateProperty.all(
//           RoundedRectangleBorder(
//             side: BorderSide(
//               color: isPressed ? Colors.blue : Colors.grey,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
