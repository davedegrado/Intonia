// Genera le immagini statiche della mascotte usate dai widget nativi
// (Android e iOS), disegnate con lo stesso MascotPainter dell'app.
//
//   flutter test tool/render_widget_mascot_test.dart
//
// Scrive i PNG in android/app/src/main/res/drawable-nodpi/ e
// ios/IntoniaWidget/Assets.xcassets/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/features/mascot/domain/mascot_mood.dart';
import 'package:vocal_scale_trainer/features/mascot/presentation/intonia_mascot.dart';

Future<List<int>> _render(MascotMood mood, double t, int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    // Margine attorno alla figura (braccia alzate, saltello, scintille).
    ..translate(size * 0.08, size * 0.1)
    ..scale(0.84);
  MascotPainter(
    loop: AlwaysStoppedAnimation(t),
    change: const AlwaysStoppedAnimation(1),
    mood: mood,
    previousMood: mood,
    onDark: true,
  ).paint(canvas, ui.Size.square(size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void main() {
  test('render widget mascot images', () async {
    const outputs = {
      // Allenamento di oggi già fatto: contenta, braccia alzate.
      'widget_mascot_happy': (MascotMood.success, 0.12),
      // Da allenare oggi: saluta e invita.
      'widget_mascot_invite': (MascotMood.greeting, 0.05),
    };
    for (final entry in outputs.entries) {
      final png = await _render(entry.value.$1, entry.value.$2, 512);
      File('android/app/src/main/res/drawable-nodpi/${entry.key}.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
      final iosName = entry.key == 'widget_mascot_happy' ? 'MascotHappy' : 'MascotInvite';
      final dir = Directory('ios/IntoniaWidget/Assets.xcassets/$iosName.imageset')
        ..createSync(recursive: true);
      File('${dir.path}/$iosName.png').writeAsBytesSync(png);
      File('${dir.path}/Contents.json').writeAsStringSync('''
{
  "images" : [
    { "filename" : "$iosName.png", "idiom" : "universal" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
''');
    }
  });
}
