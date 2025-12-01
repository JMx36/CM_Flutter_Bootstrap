import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:memory_game_app/Widgets/flip_card.dart';
import 'package:memory_game_app/screens/homescreen.dart';

const m_difficultySettings = {
  DifficultyType.easy: {"rows": 2, "columns": 2, "max_flips": 4},
  DifficultyType.medium: {"rows": 9, "columns": 6, "max_flips": 35},
  DifficultyType.hard: {"rows": 10, "columns": 7, "max_flips": 40},
};

const m_Colors = [
  Colors.deepOrange,
  Colors.blue,
  Colors.lightGreen,
  Colors.deepPurple,
  Colors.amber,
];

const m_Icons = [
  Icon(Icons.bathtub_rounded),
  Icon(Icons.ac_unit_rounded),
  Icon(Icons.account_tree_rounded),
  Icon(Icons.air_rounded),
  Icon(Icons.adb_rounded),
  Icon(Icons.ads_click_rounded),
  Icon(Icons.airplanemode_on_rounded),
];

class Game extends StatefulWidget {
  final DifficultyType type;
  final String userName;

  const Game({
    super.key,
    this.userName = "No Name",
    this.type = DifficultyType.easy,
  });

  @override
  State<Game> createState() => GameState();
}

class GameState extends State<Game> {
  int currentFlips = 0;
  int startingFlips = 0;
  List<Widget> board = [];
  Color? currColor;
  Icon? currIcon;
  int duration = 0;
  Timer? timer;
  Timer? cardCleanUptimer;

  DateTime? startTime;

  FlipCardController? firstCardController;
  FlipCardController? secondCardController;
  int totalpairs = 0;

  String toTimeFormat(int seconds) {
    int minutes = seconds ~/ 60;
    int leftOverSeconds = seconds % 60;

    return "${minutes.toString().padLeft(2, '0')}:${leftOverSeconds.toString().padLeft(2, '0')}";
  }

  bool isAllowedToFlip() {
    return firstCardController == null || secondCardController == null;
  }

  void cardSelected(Color color, Icon icon, FlipCardController controller) {
    setState(() {
      currentFlips--;
    });
    if (firstCardController == null) {
      currColor = color;
      currIcon = icon;
      firstCardController = controller;
    } else {
      secondCardController = controller;

      if (currColor == color && currIcon == icon) {
        --totalpairs;
        resetCards(true);

        if (totalpairs <= 0) {
          handleGameEnd();
        }

        return;
      }

      if (currentFlips > 0) {
        Future.delayed(Duration(seconds: 1), () {
          resetCards(false);
        });
      }
    }

    if (currentFlips <= 0) {
      handleGameEnd();
    }
  }

  Future<void> handleGameEnd() async {
    // print("Ends");
    bool gameWon = totalpairs <= 0;
    String userID = FirebaseAuth.instance.currentUser?.uid ?? "";
    final dbRef = FirebaseDatabase.instance.ref("$userID/history");

    final difference = DateTime.now().difference(startTime!); // Duration
    final seconds = difference.inSeconds;

    await dbRef.push().set({
      "difficulty": widget.type.name,
      "created_at": DateTime.now().toIso8601String(),
      "played_at": startTime!.toIso8601String(),
      "duration": seconds,
      "flips": startingFlips - currentFlips,
      "completed": gameWon,
    });

    final streakDbRef = FirebaseDatabase.instance.ref("$userID/streak");
    final streakSnapShot = await streakDbRef.get();
    if (streakSnapShot.exists) {
      int currStreak = streakSnapShot.value as int;
      streakDbRef.set(currStreak + 1);
    } else {
      streakDbRef.set(1);
    }

    if (gameWon) {
      final trophiesDbRef = FirebaseDatabase.instance.ref("$userID/trophies");
      final trophiesSnapShot = await trophiesDbRef.get();
      if (trophiesSnapShot.exists) {
        int currTrophies = trophiesSnapShot.value as int;
        trophiesDbRef.set(currTrophies + 1);
      } else {
        trophiesDbRef.set(1);
      }
    }

    timer?.cancel();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            gameWon ? "You won!" : "You lost :(",
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          backgroundColor: gameWon
              ? const ui.Color.fromARGB(255, 41, 161, 14)
              : const ui.Color.fromARGB(255, 155, 18, 16),
          content: Text(
            "Click on the arrow on the top left to go back",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      },
    );
  }

  void resetCards(bool block) {
    // print("resetting");

    if (block) {
      firstCardController?.block?.call();
      secondCardController?.block?.call();
    } else {
      firstCardController?.flip?.call();
      secondCardController?.flip?.call();
    }

    firstCardController = null;
    secondCardController = null;
  }

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    startingFlips = m_difficultySettings[widget.type]!["max_flips"]!;
    currentFlips = m_difficultySettings[widget.type]!["max_flips"]!;
    board = generateBoard(widget.type, cardSelected, isAllowedToFlip);
    final int rows = m_difficultySettings[widget.type]!["rows"]!;
    final int columns = m_difficultySettings[widget.type]!["columns"]!;
    totalpairs = (rows * columns) ~/ 2;

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        duration++;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    cardCleanUptimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.blue,
        actions: [
          Row(
            children: [
              Text(widget.userName),
              PopupMenuButton(
                color: Theme.of(context).colorScheme.inversePrimary,
                offset: .fromDirection(90, 50),
                onSelected: (value) => {},
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
      body: Padding(
        padding: .fromLTRB(5, 20, 5, 0),
        child: Center(
          child: Center(
            child: Column(
              spacing: 80,
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer_sharp, size: 50),
                        Text(
                          toTimeFormat(duration),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/card_play.svg',
                          semanticsLabel: 'Card Play Logo',
                          width: 50,
                          height: 50,
                        ),
                        Text(
                          currentFlips.toString(),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(20, 0, 20, 0),
                  child: GridView(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      crossAxisCount:
                          m_difficultySettings[widget.type]!["columns"]!,
                    ),
                    children: board,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<(Color, Icon)> allPairs = [];

List<Widget> generateBoard(
  DifficultyType type,
  void Function(Color, Icon, FlipCardController) onPressed,
  bool Function() isAllowedToFlip,
) {
  if (!m_difficultySettings.containsKey(type)) {
    return [];
  }

  final int rows = m_difficultySettings[type]!["rows"]!;
  final int columns = m_difficultySettings[type]!["columns"]!;

  // There needs to be at least 1 even
  if (rows % 2 != 0 && columns % 2 != 0) {
    return [];
  }

  final int totalPairs = (rows * columns) ~/ 2;

  if (allPairs.isEmpty) {
    for (Icon icon in m_Icons) {
      for (Color color in m_Colors) {
        allPairs.add((color, icon));
      }
    }
  }

  allPairs.shuffle();

  List<Widget> cards = [];
  for (int i = 0; i < totalPairs; ++i) {
    cards.add(
      FlipCard(
        controller: FlipCardController(),
        isAllowedToFlip: isAllowedToFlip,
        icon: allPairs[i].$2,
        color: allPairs[i].$1,
        onShown: onPressed,
        back: Container(
          width: 60,
          height: 80,
          color: allPairs[i].$1,
          child: allPairs[i].$2,
        ),
        front: Container(
          width: 60,
          height: 80,
          color: const ui.Color.fromARGB(221, 85, 8, 102),
        ),
      ),
    );
    cards.add(
      FlipCard(
        controller: FlipCardController(),
        isAllowedToFlip: isAllowedToFlip,
        icon: allPairs[i].$2,
        color: allPairs[i].$1,
        onShown: onPressed,
        back: Container(
          width: 60,
          height: 80,
          color: allPairs[i].$1,
          child: allPairs[i].$2,
        ),
        front: Container(
          width: 60,
          height: 80,
          color: const ui.Color.fromARGB(221, 85, 8, 102),
        ),
      ),
    );
  }

  cards.shuffle();
  return cards;
}
