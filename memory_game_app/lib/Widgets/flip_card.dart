import 'package:flutter/material.dart';
import 'dart:math';

class FlipCardController {
  void Function()? flip;
  void Function()? block;
}

class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Icon icon;
  final Color color;
  final Function(Color, Icon, FlipCardController) onShown;
  bool Function()? isAllowedToFlip;
  FlipCardController? controller;
  FlipCard({
    super.key,
    this.controller,
    this.isAllowedToFlip,
    required this.onShown,
    required this.icon,
    required this.color,
    required this.front,
    required this.back,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  bool isFront = true;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isBlocked = false;
  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!.flip = flipCard;
      widget.controller!.block = blockCard;
    }
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Assign flip callback if a new controller is provided
    if (widget.controller != null) {
      widget.controller!.flip = flipCard;
    }
  }

  void blockCard() {
    isBlocked = true;
  }

  void flipCard() {
    if (isBlocked) {
      return;
    }

    if (isFront) {
      if (widget.isAllowedToFlip != null && !widget.isAllowedToFlip!.call()) {
        // print("not allowed");
        return;
      }
      _controller.forward();
      widget.onShown(widget.color, widget.icon, widget.controller!);
    } else {
      _controller.reverse();
    }
    isFront = !isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isUnder = (_animation.value > pi / 2);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(_animation.value),
            child: isUnder ? widget.back : widget.front,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
