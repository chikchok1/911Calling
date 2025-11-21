import 'package:flutter/material.dart';
import '../tabs/emergency_tab.dart';
import '../tabs/guide_tab.dart';
import '../tabs/ai_analysis_tab.dart';
import '../tabs/aed_locator_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const EmergencyTab(),
    const GuideTab(),
    const AIAnalysisTab(),
    const AEDLocatorTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: '가이드',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'AI 분석',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on),
              label: 'AED',
            ),
          ],
        ),
      ),
    );
  }
}
