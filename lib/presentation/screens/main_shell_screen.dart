import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/active_timer_notifier.dart';
import '../notifiers/study_diary_notifier.dart';
import 'dashboard_screen.dart';
import 'diary_screen.dart';
import 'study_page_screen.dart';

class MainShellScreen extends StatefulWidget {
  final ActiveTimerNotifier? timerNotifier;
  final StudyDiaryNotifier? diaryNotifier;
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.timerNotifier,
    this.diaryNotifier,
    this.initialIndex = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _selectedIndex;

  StudyDiaryNotifier _resolveDiaryNotifier(BuildContext context) =>
      widget.diaryNotifier ?? context.read<StudyDiaryNotifier>();

  ActiveTimerNotifier _resolveTimerNotifier(BuildContext context) =>
      widget.timerNotifier ?? context.read<ActiveTimerNotifier>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resolveDiaryNotifier(context).loadSessions();
      }
    });
  }

  @override
  void didUpdateWidget(covariant MainShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diaryNotifier != widget.diaryNotifier) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _resolveDiaryNotifier(context).loadSessions();
        }
      });
    }
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final ActiveTimerNotifier timerN = _resolveTimerNotifier(context);
    final StudyDiaryNotifier diaryN = _resolveDiaryNotifier(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          DashboardScreen(
            diaryNotifier: diaryN,
            timerNotifier: timerN,
            onNavigateToStudy: () => _selectTab(1),
          ),
          StudyPageScreen(
            timerNotifier: timerN,
            diaryNotifier: diaryN,
          ),
          DiaryScreen(diaryNotifier: diaryN),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('bottomNavBar'),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            key: Key('dashboardTab'),
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            key: Key('studyTab'),
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Study',
          ),
          NavigationDestination(
            key: Key('diaryTab'),
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Diary',
          ),
        ],
      ),
    );
  }
}
