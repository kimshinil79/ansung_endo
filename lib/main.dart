import 'package:ansung_endo/tabs/examination_room.dart';
import 'package:ansung_endo/tabs/washing_room.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('안성 성모 내시경센터'),
        // bottom: TabBar(
        //   controller: _tabController,
        //   tabs: [
        //     Tab(text: '검사실'),
        //     Tab(text: '세척실'),
        //   ],
        // ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExaminationRoom(), // 검사실 탭의 위젯
          WashingRoom(), // 세척실 탭의 위젯
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.blueGrey, // 탭 바의 배경색을 설정합니다.
        child: SizedBox(
          height: 60,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(Icons.search), text: '검사실'), // 아이콘 추가 가능
              Tab(icon: Icon(Icons.cleaning_services), text: '세척실'),
            ],
            // 탭 바의 선택된 탭 색상을 설정합니다.
            labelColor: Colors.white,
            // 탭 바의 선택되지 않은 탭 색상을 설정합니다.
            unselectedLabelColor: Colors.white12
          ),
        ),
      ),
    );
  }
}
