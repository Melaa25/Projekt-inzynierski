import 'package:flutter/material.dart';

/// Centruje zawartość i ogranicza jej maksymalną szerokość na dużych
/// ekranach (web, desktop), żeby listy i karty nie rozciągały się
/// na całą szerokość okna. Na telefonie (wąski ekran) nie zmienia niczego.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 900,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}