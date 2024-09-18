import 'package:flutter/material.dart';

class FlashCard extends StatefulWidget {
  final String frontText;
  final String backText;
  final VoidCallback onDelete;

  const FlashCard({
    required this.frontText,
    required this.backText,
    required this.onDelete,
  });

  @override
  _FlashCardState createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool isFlipped = false;
  bool _isButtonVisible = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..addListener(() {
        // Update button visibility based on animation progress
        setState(() {
          _isButtonVisible =
              _flipController.isDismissed || _flipController.isCompleted;
        });
      });

    _flipAnimation =
        Tween<double>(begin: 0.0, end: 3.14).animate(_flipController);
  }

  void flipCard() {
    if (_flipController.isAnimating) return;

    setState(() {
      isFlipped = !isFlipped;
      if (isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flipCard,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              return RotationYTransition(
                animation: _flipAnimation,
                child: child!,
              );
            },
            child: isFlipped
                ? Container(
                    key: const ValueKey(1),
                    padding: const EdgeInsets.all(20),
                    color: Theme.of(context).colorScheme.secondary,
                    child: Center(
                      child: Text(
                        widget.backText,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  )
                : Container(
                    key: const ValueKey(2),
                    padding: const EdgeInsets.all(20),
                    color: Theme.of(context).colorScheme.secondary,
                    child: Center(
                      child: Text(
                        widget.frontText,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Visibility(
              visible: _isButtonVisible,
              child: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: widget.onDelete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RotationYTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const RotationYTransition({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final angle = animation.value;
        final transform = Matrix4.rotationY(angle);

        // Flip the widget's front/back correctly during the animation
        if (angle > 3.14 / 2 && angle < 3 * 3.14 / 2) {
          // Flip back when the angle is between 90° and 270°
          return Transform(
            transform: transform..rotateY(3.14),
            alignment: Alignment.center,
            child: child,
          );
        }

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }
}
