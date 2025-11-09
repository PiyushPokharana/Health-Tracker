import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';

// This is a utility script to generate a simple app icon programmatically
// Run this to create placeholder icons: dart run lib/tools/icon_generator.dart

void main() async {
  print('🎨 Generating app icons...');

  // Generate main icon (1024x1024)
  await generateIcon(1024, 'assets/icon.png', withBackground: true);

  // Generate foreground icon (1024x1024, transparent background)
  await generateIcon(1024, 'assets/icon_foreground.png', withBackground: false);

  print('✅ Icons generated successfully!');
  print('📁 Files saved:');
  print('   - assets/icon.png');
  print('   - assets/icon_foreground.png');
  print('');
  print('🚀 Next steps:');
  print('   1. Run: flutter pub get');
  print('   2. Run: flutter pub run flutter_launcher_icons');
  print('   3. Test: flutter run');
}

Future<void> generateIcon(int size, String filename,
    {required bool withBackground}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();

  // Draw background if needed
  if (withBackground) {
    // Orange gradient background
    paint.shader = ui.Gradient.linear(
      Offset(0, 0),
      Offset(size.toDouble(), size.toDouble()),
      [
        Color(0xFFFF6B35), // Orange
        Color(0xFFE55A2B), // Darker orange
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      paint,
    );
  }

  // Draw dumbbell icon
  paint.shader = null;
  paint.color = Colors.white;
  paint.style = PaintingStyle.fill;

  final center = size / 2.0;
  final dumbbellWidth = size * 0.6;
  final dumbbellHeight = size * 0.15;
  final weightRadius = size * 0.12;
  final handleWidth = dumbbellWidth * 0.4;

  // Draw bar (handle)
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center, center),
        width: handleWidth,
        height: dumbbellHeight * 0.5,
      ),
      Radius.circular(size * 0.02),
    ),
    paint,
  );

  // Draw left weight
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center - dumbbellWidth / 2 + weightRadius, center),
        width: weightRadius * 2,
        height: dumbbellHeight * 2,
      ),
      Radius.circular(size * 0.03),
    ),
    paint,
  );

  // Draw right weight
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center + dumbbellWidth / 2 - weightRadius, center),
        width: weightRadius * 2,
        height: dumbbellHeight * 2,
      ),
      Radius.circular(size * 0.03),
    ),
    paint,
  );

  // Draw checkmark accent
  paint.color = Color(0xFF4CAF50); // Green checkmark
  paint.style = PaintingStyle.stroke;
  paint.strokeWidth = size * 0.04;
  paint.strokeCap = StrokeCap.round;

  final checkSize = size * 0.15;
  final checkX = center + dumbbellWidth / 4;
  final checkY = center - dumbbellHeight * 1.5;

  final path = Path();
  path.moveTo(checkX - checkSize * 0.5, checkY);
  path.lineTo(checkX - checkSize * 0.2, checkY + checkSize * 0.4);
  path.lineTo(checkX + checkSize * 0.5, checkY - checkSize * 0.3);
  canvas.drawPath(path, paint);

  // Convert to image and save
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  // Save to file
  final file = File(filename);
  await file.create(recursive: true);
  await file.writeAsBytes(bytes);

  print('✓ Generated: $filename');
}
