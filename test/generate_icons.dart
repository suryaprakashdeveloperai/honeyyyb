import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyyyb/theme/neo_brutalism_theme.dart';
import 'package:honeyyyb/widgets/honeybee_logo.dart';

void main() {
  test('Generate Honeybee App Launcher Icons', () async {
    final sizes = {
      'assets/icon/app_icon.png': 1024,
      'assets/images/honeybee_logo.png': 512,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-maskable-512.png': 512,
      'web/icons/Icon-maskable-192.png': 192,
      'web/favicon.png': 64,
    };

    for (final entry in sizes.entries) {
      final path = entry.key;
      final size = entry.value.toDouble();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

      // Draw Honey Yellow background with rounded rect / neo-brutalist border
      final bgPaint = Paint()..color = NeoColors.honeyYellow;
      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.04;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(size * 0.02, size * 0.02, size * 0.96, size * 0.96),
        Radius.circular(size * 0.22),
      );

      // Fill bg
      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(rrect, borderPaint);

      // Center and scale the honeybee painter
      canvas.save();
      final beeSize = size * 0.72;
      canvas.translate((size - beeSize) / 2, (size - beeSize) / 2);

      final painter = LowPolyHoneybeePainter();
      painter.paint(canvas, Size(beeSize, beeSize));
      canvas.restore();

      final picture = recorder.endRecording();
      final image = await picture.toImage(entry.value, entry.value);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('Generated icon: $path (${entry.value}x${entry.value})');
    }
  });
}
