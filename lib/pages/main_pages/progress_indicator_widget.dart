// progress_indicator_widget.dart
import 'package:flutter/material.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final String type;
  final double progress;

  const ProgressIndicatorWidget({Key? key, required this.type, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 7,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary),
              ),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(type),
      ],
    );
  }
}
