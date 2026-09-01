import 'package:flutter/material.dart';

/// Launch / home emblem: gold EE, lime leaf, blue plug, bolt, gold frame.
class AppEmblem extends StatelessWidget {
  const AppEmblem({super.key, this.size = 128});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Energy Eniwhere',
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/brand/ee_emblem.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
