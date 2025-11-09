import 'dart:io';

/// Simple icon generator that creates SVG files which can be converted to PNG
/// Run: dart run create_icon_svg.dart
void main() {
  print('🎨 Generating app icon SVG...');

  // Create assets directory
  Directory('assets').createSync(recursive: true);

  // Generate main icon with background
  final iconWithBg = createDumbbellSVG(withBackground: true);
  File('assets/icon.svg').writeAsStringSync(iconWithBg);
  print('✓ Generated: assets/icon.svg');

  // Generate foreground icon without background
  final iconFg = createDumbbellSVG(withBackground: false);
  File('assets/icon_foreground.svg').writeAsStringSync(iconFg);
  print('✓ Generated: assets/icon_foreground.svg');

  print('');
  print('📝 Manual conversion needed:');
  print('   1. Open SVG files in a browser or design tool');
  print('   2. Export/Save as PNG at 1024x1024px');
  print('   3. Save as assets/icon.png and assets/icon_foreground.png');
  print('');
  print('Or use online converter:');
  print('   - https://cloudconvert.com/svg-to-png');
  print('   - Set output to 1024x1024px');
  print('');
  print('After conversion:');
  print('   1. Run: flutter pub run flutter_launcher_icons');
  print('   2. Run: flutter run');
}

String createDumbbellSVG({required bool withBackground}) {
  const size = 1024;
  const center = size / 2.0;
  final scale = withBackground ? 0.45 : 0.4;

  // Dumbbell dimensions
  final barWidth = size * scale * 0.8;
  final barHeight = size * 0.04;
  final plateWidth = size * 0.035;
  final plateHeight = size * scale * 0.4;
  final clipWidth = size * 0.025;
  final clipHeight = size * scale * 0.15;

  final leftX = center - barWidth / 2;
  final rightX = center + barWidth / 2;

  final buffer = StringBuffer();

  // SVG header
  buffer.writeln(
      '<svg width="$size" height="$size" xmlns="http://www.w3.org/2000/svg">');

  // Background (if needed)
  if (withBackground) {
    buffer.writeln('  <defs>');
    buffer.writeln(
        '    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">');
    buffer.writeln(
        '      <stop offset="0%" style="stop-color:#FF6B35;stop-opacity:1" />');
    buffer.writeln(
        '      <stop offset="100%" style="stop-color:#E55A2B;stop-opacity:1" />');
    buffer.writeln('    </linearGradient>');
    buffer.writeln('  </defs>');
    buffer.writeln(
        '  <rect width="$size" height="$size" fill="url(#bgGradient)" />');
  }

  // Center bar
  buffer.writeln(
      '  <rect x="${center - barWidth / 2}" y="${center - barHeight / 2}" ');
  buffer.writeln(
      '        width="$barWidth" height="$barHeight" rx="${barHeight / 2}" fill="white" />');

  // Left plates
  _addPlate(
      buffer, leftX + plateWidth * 0.5, center, plateWidth, plateHeight * 1.2);
  _addPlate(buffer, leftX + plateWidth * 2, center, plateWidth, plateHeight);
  _addPlate(
      buffer, leftX + plateWidth * 3.5, center, plateWidth, plateHeight * 0.85);
  _addClip(buffer, leftX + plateWidth * 5, center, clipWidth, clipHeight);

  // Right plates
  _addPlate(
      buffer, rightX - plateWidth * 0.5, center, plateWidth, plateHeight * 1.2);
  _addPlate(buffer, rightX - plateWidth * 2, center, plateWidth, plateHeight);
  _addPlate(buffer, rightX - plateWidth * 3.5, center, plateWidth,
      plateHeight * 0.85);
  _addClip(buffer, rightX - plateWidth * 5, center, clipWidth, clipHeight);

  // Checkmark (if with background)
  if (withBackground) {
    final checkSize = size * 0.08;
    final checkX = center + barWidth * 0.35;
    final checkY = center - plateHeight * 0.8;

    buffer.writeln('  <path d="M ${checkX - checkSize * 0.4} $checkY ');
    buffer.writeln(
        '           L ${checkX - checkSize * 0.1} ${checkY + checkSize * 0.35} ');
    buffer.writeln(
        '           L ${checkX + checkSize * 0.4} ${checkY - checkSize * 0.25}" ');
    buffer.writeln('        stroke="#4CAF50" stroke-width="${size * 0.015}" ');
    buffer.writeln(
        '        stroke-linecap="round" stroke-linejoin="round" fill="none" />');
  }

  buffer.writeln('</svg>');

  return buffer.toString();
}

void _addPlate(
    StringBuffer buffer, double x, double y, double width, double height) {
  final rx = width * 0.3;
  buffer.writeln('  <rect x="${x - width / 2}" y="${y - height / 2}" ');
  buffer.writeln(
      '        width="$width" height="$height" rx="$rx" fill="white" />');
}

void _addClip(
    StringBuffer buffer, double x, double y, double width, double height) {
  final rx = width * 0.3;
  buffer.writeln('  <rect x="${x - width / 2}" y="${y - height / 2}" ');
  buffer.writeln(
      '        width="$width" height="$height" rx="$rx" fill="white" />');
}
