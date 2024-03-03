import 'package:flutter/material.dart';

class endoscopyForEachMachineWidget extends StatefulWidget {

  final List<dynamic> endoscopyAndTimeList;

  const endoscopyForEachMachineWidget({super.key, required this.endoscopyAndTimeList});

  @override
  State<endoscopyForEachMachineWidget> createState() => _endoscopyForEachMachineWidgetState();
}

class _endoscopyForEachMachineWidgetState extends State<endoscopyForEachMachineWidget> {
  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey<String>('endoscopyList');
    return ListView.builder(
        itemCount: widget.endoscopyAndTimeList.length,
        itemBuilder: (context, index) {
          final endoscopyName = widget.endoscopyAndTimeList[0];
          final time = widget.endoscopyAndTimeList[1];
          print (endoscopyName);
          print (time);
          return ElevatedButton(
              onPressed: () {},
              child: Column(
                children: [
                  Text(endoscopyName),
                  Text(time),
                ],

          ),
          );}
    );

  }
}
