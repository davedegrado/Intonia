import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Testo della licenza MIT del SoundFont FluidR3 incluso nell'app.
const fluidR3LicenseAsset = 'soundfonts/licenses/FLUIDR3-COPYING.txt';

/// Registra le licenze degli asset di terze parti, così compaiono nella
/// pagina "Licenze" insieme a quelle dei pacchetti Dart. La licenza MIT
/// richiede di includere copyright e testo della licenza nelle copie
/// distribuite.
void registerThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(fluidR3LicenseAsset);
    yield LicenseEntryWithLineBreaks(const ['Fluid (R3) SoundFont'], text);
  });
}
