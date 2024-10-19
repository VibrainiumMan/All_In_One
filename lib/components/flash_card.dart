import 'package:flutter/material.dart';
import '../../auth/firestore_service.dart';

class FlashCard extends StatefulWidget {
  final String frontText;
  final String backText;
  final VoidCallback onDelete;
  final int priority;
  final String deckName;
  final String cardId;

  const FlashCard({
    required this.frontText,
    required this.backText,
    required this.onDelete,
    required this.priority,
    required this.deckName,
    required this.cardId,
  });

  @override
  _FlashCardState createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool isFlipped = false;
  bool _isButtonVisible = true;

  final FirestoreService flashCardManager = FirestoreService();

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

  void _updatePriority(int newPriority) {
    flashCardManager.updateFlashCardPriority(widget.deckName, widget.cardId, newPriority);
  }

  Future<void> _showPriorityDialog(BuildContext context) async {
    int selectedPriority = widget.priority;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Setting priority'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Set priority (1 - 10):'),
                  const SizedBox(height: 20),
                  Slider(
                    value: selectedPriority.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: selectedPriority.toString(),
                    onChanged: (value) {
                      setState(() {
                        selectedPriority = value.toInt();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _updatePriority(selectedPriority);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = getColorBasedOnPriority(widget.priority);

    return GestureDetector(
      onTap: flipCard,
      onLongPress: () {
        _showPriorityDialog(context);
      },
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
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(20),
              color: backgroundColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.backText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Priority: ${widget.priority}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
                : Container(
              key: const ValueKey(2),
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(20),
              color: backgroundColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.frontText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Priority: ${widget.priority}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
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
                  color: Colors.black,
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

Color getColorBasedOnPriority(int priority) {
  Color lowPriorityColor = Colors.green;
  Color highPriorityColor = Colors.red;

  return Color.lerp(lowPriorityColor, highPriorityColor, (priority - 1) / 9)!;
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