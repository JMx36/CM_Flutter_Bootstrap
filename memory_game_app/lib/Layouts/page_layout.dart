import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
      assetName,
      width: 24,
      height: 24,
      semanticsLabel: 'Stats Logo',
      colorFilter: colorFilter,
    ),
    label: label,
  );
}

class PageLayout extends StatefulWidget {
  const PageLayout({super.key, required this.title});
  final String title;
  @override
  State<PageLayout> createState() => PageLayoutState();
}

class PageLayoutState extends State<PageLayout> {
  int _selectedIndex = 1;

  ColorFilter? _tryGetColorFilter(int targetIdx) {
    return _selectedIndex != targetIdx
        ? null
        : ColorFilter.mode(Colors.white, ui.BlendMode.srcIn);
  }

  final User? user = FirebaseAuth.instance.currentUser;
  final int trophies = 100;
  final int streak = 15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.blue,
        actions: [
          Row(
            children: [
              Text(user?.email?.split("@")[0] ?? "No Name"),
              PopupMenuButton(
                color: Theme.of(context).colorScheme.inversePrimary,
                offset: .fromDirection(90, 50),
                onSelected: (value) {
                  FirebaseAuth.instance.signOut();
                  // showDialog(
                  //   context: context,
                  //   builder: (BuildContext context) {
                  //     return AlertDialog(content: Text("HELLo"));
                  //   },
                  // );
                },
                icon: SvgPicture.asset(
                  'assets/profile-icon.svg',
                  height: 48,
                  width: 48,
                  colorFilter: ColorFilter.mode(
                    Colors.white,
                    ui.BlendMode.srcIn,
                  ),
                ),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(value: 1, child: Text("Log out")),
                ],
              ),
            ],
          ),
        ],
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
