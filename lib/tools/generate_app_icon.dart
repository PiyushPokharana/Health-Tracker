import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Run this file to generate app icons
/// Usage: flutter run lib/tools/generate_app_icon.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🎨 Generating app icons...');

  // Generate main icon (1024x1024) with orange background
  await generateIcon(
    size: 1024,
    filename: 'assets/icon.png',
    withBackground: true,
  );

  // Generate foreground icon (1024x1024) transparent background
  await generateIcon(
    size: 1024,
    filename: 'assets/icon_foreground.png',
    withBackground: false,
  );

  print('✅ Icons generated successfully!');
  print('📁 Files saved:');
  print('   - assets/icon.png');
  print('   - assets/icon_foreground.png');
  print('');
  print('🚀 Next steps:');
  print('   1. Run: flutter pub run flutter_launcher_icons');
  print('   2. Run: flutter run');
  print('   3. Check your app drawer for the new icon!');

  exit(0);
}

Future<void> generateIcon({
  required int size,
  required String filename,
  required bool withBackground,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();

  // Draw background if needed
  if (withBackground) {
    // Orange gradient background
    final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    paint.shader = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(size.toDouble(), size.toDouble()),
      [
        const Color(0xFFFF6B35), // Orange
        const Color(0xFFE55A2B), // Darker orange
      ],
    );
    canvas.drawRect(rect, paint);
  }

  // Draw dumbbell icon (based on user's image)
  paint.shader = null;
  paint.color = Colors.white;
  paint.style = PaintingStyle.fill;

  final center = size / 2.0;
  final scale =
      withBackground ? 0.45 : 0.4; // Slightly smaller for adaptive icon

  // Dumbbell dimensions
  final barWidth = size * scale * 0.8;
  final barHeight = size * 0.04;
  final plateWidth = size * 0.035;
  final plateHeight = size * scale * 0.4;
  final clipWidth = size * 0.025;
  final clipHeight = size * scale * 0.15;

  // Draw center bar
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center, center),
        width: barWidth,
        height: barHeight,
      ),
      Radius.circular(barHeight / 2),
    ),
    paint,
  );

  // Left side plates (3 plates)
  final leftX = center - barWidth / 2;

  // Outer left plate
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(leftX + plateWidth * 0.5, center),
        width: plateWidth,
        height: plateHeight * 1.2,
      ),
      Radius.circular(plateWidth * 0.3),
    ),
    paint,
  );

  // Middle left plate
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(leftX + plateWidth * 2, center),
        width: plateWidth,
        height: plateHeight,
      ),
      Radius.circular(plateWidth * 0.3),
    ),
    paint,
  );

  // Inner left plate
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(leftX + plateWidth * 3.5, center),
        width: plateWidth,
        height: plateHeight * 0.85,
      ),
      Radius.circular(plateWidth * 0.3),
    ),
    paint,
  );

  // Left clip
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(leftX + plateWidth * 5, center),
        width: clipWidth,
        height: clipHeight,
      ),
      Radius.circular(clipWidth * 0.3),
    ),
    paint,
  );

  // Right side plates (3 plates) - mirror of left
  final rightX = center + barWidth / 2;

  // Outer right plate
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rightX - plateWidth * 0.5, center),
        width: plateWidth,
        height: plateHeight * 1.2,
      ),
      Radius.circular(plateWidth * 0.3),
    ),
    paint,
  );

  // Middle right plate
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rightX - plateWidth * 2, center),
        width: plateWidth,
        height: plateHeight,
      ),
      Radius.circular(plateWidth * 0.3),
    ),
    paint,
  );

  // Inner right plate
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rightX - plateWidth * 3.5, center),
        width: plateWidth,
        height: plateHeight * 0.85,
      ),
      Radius.circular(plateWidth * 0.3),
    ),
    paint,
  );

  // Right clip
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rightX - plateWidth * 5, center),
        width: clipWidth,
        height: clipHeight,
      ),
      Radius.circular(clipWidth * 0.3),
    ),
    paint,
  );

  // Optional: Add checkmark accent in corner (subtle, small)
  if (withBackground) {
    paint.color = const Color(0xFF4CAF50); // Green
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size * 0.015;
    paint.strokeCap = StrokeCap.round;

    final checkSize = size * 0.08;
    final checkX = center + barWidth * 0.35;
    final checkY = center - plateHeight * 0.8;

    final path = Path();
    path.moveTo(checkX - checkSize * 0.4, checkY);
    path.lineTo(checkX - checkSize * 0.1, checkY + checkSize * 0.35);
    path.lineTo(checkX + checkSize * 0.4, checkY - checkSize * 0.25);
    canvas.drawPath(path, paint);
  }

  // Convert to image and save
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  // Save to file
  final file = File(filename);
  await file.create(recursive: true);
  await file.writeAsBytes(bytes);

  print(
      '✓ Generated: $filename (${(bytes.length / 1024).toStringAsFixed(1)} KB)');
}
