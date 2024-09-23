import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Column(
        children: [
          MyCounter(
            count: count,
          ),
          MyCounter(
            count: count,
          ),
          TextButton(
            child: Text('Increment'),
            onPressed: () {
              setState(() {
                count++;
              });
            },
          )
        ],
      ),
    );
  }
}

class MyCounter extends StatelessWidget {
  int count;
  MyCounter({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Text('$count');
  }
}
