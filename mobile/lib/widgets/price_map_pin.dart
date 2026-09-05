import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

/// Cached teardrop pin; optional € label for street zoom.
class PricePinCache {
  PricePinCache();

  final Map<String, gmaps.BitmapDescriptor> _cache = {};

  Color hueColor({
    required bool selected,
    required bool live,
    required bool available,
  }) {
    if (selected) return const Color(0xFFFF6B35);
    if (live && available) return const Color(0xFF2EAD4B);
    if (live) return const Color(0xFFE53935);
    return const Color(0xFF0066FF);
  }

  Future<gmaps.BitmapDescriptor> icon({
    required double pixelRatio,
    required bool selected,
    required bool live,
    required bool available,
    required String? priceLabel,
  }) async {
    final color = hueColor(
      selected: selected,
      live: live,
      available: available,
    );
    final key =
        '${color.toARGB32()}|${priceLabel ?? ''}|${pixelRatio.toStringAsFixed(1)}';
    final hit = _cache[key];
    if (hit != null) return hit;
    final bytes = await _drawPin(
      color: color,
      priceLabel: priceLabel,
      pixelRatio: pixelRatio,
    );
    final icon = gmaps.BitmapDescriptor.fromBytes(bytes);
    _cache[key] = icon;
    return icon;
  }
}

Future<Uint8List> _drawPin({
  required Color color,
  required String? priceLabel,
  required double pixelRatio,
}) async {
  final dpr = pixelRatio.clamp(1.5, 3.0);
  final showPrice = priceLabel != null && priceLabel.isNotEmpty;
  final logicalW = showPrice ? 72.0 : 28.0;
  final logicalH = showPrice ? 44.0 : 36.0;
  final w = (logicalW * dpr).round();
  final h = (logicalH * dpr).round();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = color;

  if (showPrice) {
    final rect = RRect.fromLTRBR(
      1 * dpr,
      1 * dpr,
      w - 1 * dpr,
      h - 8 * dpr,
      Radius.circular(10 * dpr),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * dpr,
    );
    final tip = Path()
      ..moveTo(w / 2 - 5 * dpr, h - 8 * dpr)
      ..lineTo(w / 2, h.toDouble())
      ..lineTo(w / 2 + 5 * dpr, h - 8 * dpr)
      ..close();
    canvas.drawPath(tip, paint);

    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 12 * dpr,
        fontWeight: FontWeight.w800,
      ),
    )
      ..pushStyle(ui.TextStyle(color: Colors.white))
      ..addText(priceLabel);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: w.toDouble()));
    canvas.drawParagraph(paragraph, Offset(0, 8 * dpr));
  } else {
    final cx = w / 2;
    final cy = h * 0.38;
    final r = 9 * dpr;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * dpr,
    );
    final tip = Path()
      ..moveTo(cx - 6 * dpr, cy + 6 * dpr)
      ..lineTo(cx, h - 2 * dpr)
      ..lineTo(cx + 6 * dpr, cy + 6 * dpr)
      ..close();
    canvas.drawPath(tip, paint);
  }

  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
