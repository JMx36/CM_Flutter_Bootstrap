import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:memory_game_app/screens/history.dart';
import 'package:memory_game_app/screens/homescreen.dart';
import 'package:memory_game_app/screens/stats.dart';

import 'dart:ui' as ui;

const String historyLogoAssetName = 'assets/history.svg';
const String statsLogoAssetName = 'assets/stats.svg';

BottomNavigationBarItem getBottomNavItem(
  String assetName,
  String svgLabel,
  String label,
  ColorFilter? colorFilter,
) {
  return BottomNavigationBarItem(
    icon: SvgPicture.asset(
      historyLogoAssetName,
      width: 24,
      height: 24,
      semanticsLabel: 'Stats Logo',
      colorFilter: colorFilter,
    ),
    label: 'History',
  );
}

class PageLayout extends StatefulWidget {
  const PageLayout({super.key, required this.title});
  final String title;
  @override
  State<PageLayout> createState() => PageLayoutState();
}

class PageLayoutState extends State<PageLayout> {
  int _selectedIndex = 0;

  ColorFilter? _tryGetColorFilter(int targetIdx) {
    return _selectedIndex != targetIdx
        ? null
        : ColorFilter.mode(Colors.white, ui.BlendMode.srcIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: const <Widget>[
          HistoryScreen(),
          HomeScreen(),
          StatsScreen(),
        ][_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.inversePrimary,
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          items: <BottomNavigationBarItem>[
            getBottomNavItem(
              historyLogoAssetName,
              'History Logo',
              'History',
              _tryGetColorFilter(0),
            ),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            getBottomNavItem(
              statsLogoAssetName,
              'Statistics Logo',
              'Stats',
              _tryGetColorFilter(2),
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
