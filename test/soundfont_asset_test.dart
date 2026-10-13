import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/third_party_licenses.dart';
import 'package:vocal_scale_trainer/services/audio/piano_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the piano SoundFont used by the player is bundled as an asset', () async {
    final data = await rootBundle.load(PianoAudioService.assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, 12);

    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'sfbk');
  });

  test('the FluidR3 MIT license is bundled and registered', () async {
    registerThirdPartyLicenses();

    final licenses = await LicenseRegistry.licenses.toList();
    final fluid = licenses.where((l) => l.packages.contains('Fluid (R3) SoundFont'));

    expect(fluid, isNotEmpty);
    final text = fluid.first.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('Frank Wen'));
    expect(text, contains('Permission is hereby granted'));
  });
}
