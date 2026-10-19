// Genera le scene statiche con la mascotte usate dal widget nativo della
// serie (Android e iOS): alone, nuvole viola, note e la mascotte disegnata
// dallo stesso IntoniaMascot dell'app.
//
//   flutter test tool/render_widget_mascot_test.dart
//
// Scrive i PNG in android/app/src/main/res/drawable-nodpi/ e
// ios/IntoniaWidget/Assets.xcassets/.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/features/mascot/domain/mascot_mood.dart';
import 'package:vocal_scale_trainer/features/mascot/presentation/intonia_mascot.dart';

const _cyan = Color(0xFF5EEAF4);
const _sky = Color(0xFF7DD3FC);
const _magenta = Color(0xFFE879F9);

/// Nuvole viola nella parte bassa, sfumate verso destra per fondersi con lo
/// sfondo del widget.
class _Clouds extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.saveLayer(Offset.zero & size, Paint());
    void cloud(List<(double, double, double)> puffs, Color top, Color bottom) {
      final path = Path();
      for (final (x, y, r) in puffs) {
        path.addOval(Rect.fromCircle(center: Offset(x * w, y * h), radius: r * h));
      }
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ).createShader(Rect.fromLTWH(0, h * 0.62, w, h * 0.38)),
      );
    }

    cloud([(0.02, 1.02, 0.30), (0.26, 0.97, 0.24), (0.46, 1.06, 0.26)], const Color(0xFF5B3FC4),
        const Color(0xFF2B1F78));
    cloud([(0.62, 1.02, 0.24), (0.84, 0.97, 0.25), (1.04, 1.05, 0.27)], const Color(0xFF6A46D6),
        const Color(0xFF33238A));
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.white, Color(0x00FFFFFF)],
          stops: [0, 0.72, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Clouds oldDelegate) => false;
}

Widget _sparkle(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.85),
        boxShadow: [BoxShadow(color: _cyan.withValues(alpha: 0.8), blurRadius: size * 2)],
      ),
    );

Widget _scene(MascotMood mood, double w, double h) {
  final mascot = math.min(h * 0.86, w * 0.78);
  Widget at(double left, double top, Widget child) =>
      Positioned(left: left * w, top: top * h, child: child);
  return SizedBox(
    width: w,
    height: h,
    child: Stack(
      children: [
        // Alone ciano e viola dietro la mascotte.
        Positioned(
          left: w * 0.47 - mascot * 0.78,
          top: h * 0.5 - mascot * 0.72,
          width: mascot * 1.56,
          height: mascot * 1.44,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x6622D3EE), Color(0x337C5CFA), Color(0x007C5CFA)],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _Clouds())),
        at(0.07, 0.14,
            Icon(Icons.music_note_rounded, size: h * 0.16, color: _cyan.withValues(alpha: 0.9))),
        at(0.20, 0.30,
            Icon(Icons.music_note_rounded, size: h * 0.09, color: _sky.withValues(alpha: 0.65))),
        at(0.76, 0.10,
            Icon(Icons.favorite_rounded, size: h * 0.13, color: _magenta.withValues(alpha: 0.8))),
        at(0.80, 0.50,
            Icon(Icons.queue_music_rounded, size: h * 0.14, color: _sky.withValues(alpha: 0.75))),
        at(0.05, 0.60, _sparkle(h * 0.045)),
        at(0.66, 0.04, _sparkle(h * 0.035)),
        at(0.86, 0.34, _sparkle(h * 0.03)),
        Positioned(
          left: w * 0.47 - mascot / 2,
          top: (h - mascot) / 2 + h * 0.02,
          child: IntoniaMascot(mood: mood, size: mascot, interactive: false),
        ),
      ],
    ),
  );
}

void main() {
  const outputs = {
    // Allenamento di oggi fatto: contenta, braccia alzate.
    'happy': MascotMood.success,
    // Da allenare oggi: invita.
    'invite': MascotMood.idle,
  };
  for (final entry in outputs.entries) {
    testWidgets('render widget scene ${entry.key}', (tester) async {
      // Icone (note, cuore) dal font Material incluso nell'app.
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();

      const w = 510.0, h = 480.0;
      tester.view.physicalSize = const Size(w, h);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(Theme(
        data: ThemeData(brightness: Brightness.dark),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: const ValueKey('scene'),
              child: _scene(entry.value, w, h),
            ),
          ),
        ),
      ));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('scene')));
      final png = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        return bytes!.buffer.asUint8List();
      });

      File('android/app/src/main/res/drawable-nodpi/widget_scene_${entry.key}.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!);
      final iosName = entry.key == 'happy' ? 'SceneHappy' : 'SceneInvite';
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
    });
  }
}
