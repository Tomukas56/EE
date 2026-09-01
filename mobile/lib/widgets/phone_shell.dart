import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// On web, show the app at a phone-sized frame so layout matches a real device.
class PhoneShell extends StatelessWidget {
  const PhoneShell({super.key, required this.child});

  final Widget child;

  static const double frameWidth = 390;
  static const double frameHeight = 844;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return ColoredBox(
      color: const Color(0xFF0E0E10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableW = math.max(0.0, constraints.maxWidth - 24);
          final availableH = math.max(0.0, constraints.maxHeight - 24);
          final scale = math.min(
            1.0,
            math.min(availableW / frameWidth, availableH / frameHeight),
          );
          final mq = MediaQuery.of(context);

          return Center(
            child: SizedBox(
              width: frameWidth * scale,
              height: frameHeight * scale,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: frameWidth,
                  height: frameHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: const Color(0xFF3A3A3C),
                        width: 10,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: MediaQuery(
                        data: mq.copyWith(
                          size: const Size(frameWidth, frameHeight),
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
                          viewPadding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
                          viewInsets: EdgeInsets.zero,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
