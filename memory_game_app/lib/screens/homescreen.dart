import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:memory_game_app/screens/game.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final int trophies = 100;
  final int streak = 25;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 20,
          left: 10,
          child: Column(
            spacing: 20,
            children: [
              Row(
                spacing: 10,
                children: [
                  SvgPicture.asset(
                    'assets/trophy.svg',
                    semanticsLabel: 'Trophy Logo',
                    height: 50,
                    width: 50,
                  ),
                  TextCategoryData(type: .trophies),
                ],
              ),
              Row(
                spacing: 2,
                children: [
                  Icon(Icons.bolt_rounded, size: 60),
                  TextCategoryData(type: .streak),
                ],
              ),
            ],
          ),
        ),
        Center(child: DifficultySelect()),
      ],
    );
  }
}

enum TextCategoryType { trophies, streak }

class TextCategoryData extends StatefulWidget {
  final TextCategoryType type;
  const TextCategoryData({super.key, required this.type});

  @override
  State<TextCategoryData> createState() => _TextCategoryDataState();
}

class _TextCategoryDataState extends State<TextCategoryData>
    with WidgetsBindingObserver {
  int value = -1;
  final User? user = FirebaseAuth.instance.currentUser;
  String userID = "";
  DatabaseReference? dbRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    userID = user?.uid ?? "";

    dbRef = FirebaseDatabase.instance.ref(
      "$userID/${widget.type.name.toLowerCase()}",
    );
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      value < 0 ? 0.toString() : value.toString(),
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // screen came back into view
      fetchData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void fetchData() async {
    try {
      if (dbRef == null) {
        print("No database ref");
        return;
      }

      final snapshot = await dbRef!.get();

      if (snapshot.exists) {
        setState(() {
          value = snapshot.value as int;
        });
      }
    } catch (e) {
      print("Error fetching history: $e");
    }
  }
}

class DifficultySelect extends StatefulWidget {
  const DifficultySelect({super.key});

  @override
  State<DifficultySelect> createState() => _DifficultySelectState();
}

enum DifficultyType { easy, medium, hard }

class _DifficultySelectState extends State<DifficultySelect> {
  DifficultyType selectedType = DifficultyType.easy;

  int currIdx = 0;

  static final difficulties = DifficultyType.values
      .map((value) => value.name.toUpperCase())
      .toList(growable: false);

  void handleIdx(int direction) {
    setState(() {
      currIdx = direction < 0
          ? max(0, currIdx - 1)
          : min(difficulties.length - 1, currIdx + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      mainAxisAlignment: .center,
      children: [
        Row(
          mainAxisAlignment: .center,
          spacing: 20,
          children: [
            ElevatedButton(
              onPressed: currIdx == 0
                  ? null
                  : () {
                      handleIdx(-1);
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(0, 0),
                shape: TriangleBorder(true),
                padding: EdgeInsets.all(20),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: SizedBox(
                height: 50,
                width: 10,
              ), // leave empty or put icon/text
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: const <Color>[
                  Color.fromARGB(255, 2, 110, 42),
                  Color.fromARGB(255, 139, 139, 5),
                  Color.fromARGB(255, 147, 25, 3),
                ][currIdx],
              ),
              width: 200,
              height: 200,
            ), // leave empty or put icon/text
            ElevatedButton(
              onPressed: currIdx == difficulties.length - 1
                  ? null
                  : () {
                      handleIdx(1);
                    },

              style: ElevatedButton.styleFrom(
                minimumSize: Size(0, 0),
                shape: TriangleBorder(false),
                padding: EdgeInsets.all(20),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: SizedBox(
                height: 50,
                width: 5,
              ), // leave empty or put icon/text
            ),
          ],
        ),
        Text(
          difficulties[currIdx],
          style: Theme.of(context).textTheme.displaySmall,
        ),
        ElevatedButton(
          style: ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(100, 50)),
            backgroundColor: WidgetStateColor.fromMap({
              WidgetState.pressed: Theme.of(context).colorScheme.onPrimary,
              WidgetState.any: Theme.of(context).colorScheme.inversePrimary,
            }),
            textStyle: WidgetStatePropertyAll(
              Theme.of(context).textTheme.displaySmall,
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Game(
                  type: DifficultyType.values[currIdx],
                  userName:
                      FirebaseAuth.instance.currentUser?.email ?? "No Name",
                ),
              ),
            );
          },
          child: Text("Play"),
        ),
      ],
    );
  }
}

class TriangleBorder extends OutlinedBorder {
  bool isLeftFacing;

  TriangleBorder(this.isLeftFacing);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double radius = 4.0;
    final double w = rect.width;
    final double h = rect.height;

    final path = Path();

    // Define direction multipliers for flipping horizontally
    final double left = isLeftFacing ? 0 : w;
    final double right = isLeftFacing ? w : 0;
    final bool clockwise = !isLeftFacing;
    final double widthOffset = (isLeftFacing ? radius * 2 : -radius * 2);
    final double cornerRadius = radius * 2;

    // Left-middle corner
    path.moveTo(left + widthOffset, h / 2 - radius - 1);
    path.arcToPoint(
      Offset(left + widthOffset, h / 2 + radius * 1.4),
      radius: Radius.circular(cornerRadius),
      clockwise: clockwise,
    );

    // Bottom-right corner
    path.lineTo(right - widthOffset, h - radius * 1.4);
    path.arcToPoint(
      Offset(right, h - radius * 1.4),
      radius: Radius.circular(cornerRadius),
      clockwise: clockwise,
    );

    // Top-right corner
    path.lineTo(right, radius * 1.4);
    path.arcToPoint(
      Offset(right - widthOffset, radius * 1.4),
      radius: Radius.circular(cornerRadius),
      clockwise: clockwise,
    );

    path.close();

    return path;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // Nothing extra to paint
  }

  @override
  TriangleBorder copyWith({BorderSide? side}) {
    return TriangleBorder(isLeftFacing);
  }

  @override
  ShapeBorder scale(double t) => this;
}
