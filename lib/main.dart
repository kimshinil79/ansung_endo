import 'package:ansung_endo/tabs/examination_room.dart';
import 'package:ansung_endo/tabs/settings.dart';
import 'package:ansung_endo/tabs/statistics_page.dart';
import 'package:ansung_endo/tabs/washing_room.dart';
import 'package:flutter/cupertino.dart';
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
      debugShowCheckedModeBanner: false,
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
    _tabController = TabController(length: 4, vsync: this);
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                  '안성 성모 내시경센터 v1.3',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 2.0,
                        color: const Color(0xFF00A88B).withOpacity(0.5),
                      ),
                      // 필요하다면 더 많은 Shadow 객체를 리스트에 추가할 수 있습니다.
                    ],
                  ),
              ),
            ),
            Image.asset(
              'assets/images/ansung.png', // assets 폴더에 이미지를 위치시켜야 합니다.
              width: 40, // 이미지의 너비를 조절
              height: 40, // 이미지의 높이를 조절
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExaminationRoom(), // 검사실 탭의 위젯
          WashingRoom(),
          StatisticsPage(),
          SettingsPage(),// 세척실 탭의 위젯
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
              Tab(icon:Icon(Icons.bar_chart), text:'통계'),
              Tab(icon:Icon(Icons.settings), text:'설정'),
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
