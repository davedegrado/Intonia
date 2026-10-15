import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart' show AppThemeSetting, brandCyan, brandIndigo, brandViolet;
import '../../../app/main_shell.dart';
import '../../../app/note_text.dart';
import '../../../app/status_chips.dart';
import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';
import '../../../core/pitch/pitch_detection_result.dart';
import '../../../core/pitch/pitch_recognition_config.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/intonia_mascot.dart';
import '../../settings/application/settings_providers.dart';
import '../../tuner/application/tuner_controller.dart';

/// Home: la mascotte e il riconoscimento delle note in tempo reale.
/// Il microfono parte solo col pulsante e si ferma su stop, cambio di
/// sezione o schermata, app in background.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  /// Ultima nota riconosciuta in questa apertura dell'app (non salvata).
  PitchDetectionResult? _lastNote;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Solo hidden/paused (app in background): "inactive" scatta anche mentre
    // è aperto il dialog del permesso microfono e annullerebbe l'avvio.
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      ref.read(tunerControllerProvider.notifier).stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tunerControllerProvider, (previous, next) {
      final detection = next.detection;
      if (detection != null && detection.isStable) {
        setState(() => _lastNote = detection);
      }
    });
    final theme = Theme.of(context);
    final tuner = ref.watch(tunerControllerProvider);
    final detection = tuner.detection;
    final hasPitch = tuner.active && detection != null && detection.isStable;
    final inTune = hasPitch && detection.cents.abs() <= PitchRecognitionConfig.inTuneCents;

    final message = tuner.permissionDenied
        ? 'Permesso microfono negato: abilitalo nelle impostazioni del telefono.'
        : !tuner.active
            ? 'Canta o suona una nota:\nti dico qual è!'
            : !hasPitch
                ? 'Ti ascolto…\ncanta o suona una nota.'
                : inTune
                    ? 'Perfettamente intonata!'
                    : 'Ci sei quasi: aggiusta un pochino.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intonia'),
        actions: const [StatusChips()],
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Mascotte e microfono si adattano all'altezza disponibile; sotto
            // una certa altezza la pagina scorre invece di andare in overflow.
            final height = math.max(constraints.maxHeight, 480.0);
            final mascotSize = (height * 0.30).clamp(110.0, 260.0);
            final micSize = (height * 0.17).clamp(84.0, 128.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SpeechBubble(
                      message: message,
                      isError: tuner.permissionDenied,
                    ),
                    const SizedBox(height: 4),
                    IntoniaMascot(
                      key: const ValueKey('home-mascot'),
                      mood: tuner.active ? MascotMood.listening : MascotMood.idle,
                      size: mascotSize,
                      greetOnAppear: true,
                    ),
                    const SizedBox(height: 8),
                    _MicButton(
                      size: micSize,
                      active: tuner.active,
                      onPressed: () {
                        final controller = ref.read(tunerControllerProvider.notifier);
                        tuner.active ? controller.stop() : controller.start();
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tuner.active ? 'Ferma ascolto' : 'Avvia ascolto',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    _NoteCard(
                      detection: hasPitch ? detection : _lastNote,
                      live: hasPitch,
                    ),
                    const SizedBox(height: 12),
                    const _QuickActions(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Fumetto della mascotte.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        key: const ValueKey('home-bubble'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isError ? colors.error : colors.primary.withValues(alpha: 0.6),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            message,
            key: ValueKey(message),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isError ? colors.error : null,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Grande pulsante circolare del riconoscimento, con alone luminoso.
class _MicButton extends StatefulWidget {
  const _MicButton({required this.size, required this.active, required this.onPressed});

  final double size;
  final bool active;
  final VoidCallback onPressed;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _sync();
    }
  }

  /// L'anello pulsa solo durante l'ascolto: a riposo nessuna animazione.
  void _sync() {
    if (widget.active) {
      _pulse.repeat();
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final ring = size * 0.15;

    return Semantics(
      button: true,
      label: widget.active ? 'Ferma il riconoscimento' : 'Avvia il riconoscimento delle note',
      child: SizedBox(
        width: size + ring * 2,
        height: size + ring * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Onda che si espande durante l'ascolto.
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                return Opacity(
                  opacity: widget.active ? (1 - t) * 0.7 : 0,
                  child: Container(
                    width: size + ring * 2 * t,
                    height: size + ring * 2 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: brandCyan, width: 3),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.active ? [brandCyan, brandIndigo] : [brandIndigo, brandViolet],
                ),
                border: Border.all(color: brandCyan.withValues(alpha: 0.8), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: (widget.active ? brandCyan : brandIndigo).withValues(alpha: 0.45),
                    blurRadius: size * 0.3,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: const ValueKey('home-mic'),
                  customBorder: const CircleBorder(),
                  onTap: widget.onPressed,
                  child: Icon(
                    widget.active ? Icons.stop_rounded : Icons.mic,
                    size: size * 0.42,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nota riconosciuta (in diretta) o l'ultima riconosciuta, con lo scostamento.
/// Altezza fissa: la pagina non "salta" quando compare la prima nota.
class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.detection, required this.live});

  final PitchDetectionResult? detection;
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final notation = ref.watch(notationProvider);
    final detection = this.detection;

    return SizedBox(
      height: 76,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: detection == null
              ? Center(
                  child: Text(
                    'Qui vedrai la nota riconosciuta e quanto sei intonato.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NoteText(
                            NoteSpeller.spellRoot(detection.note),
                            notation: notation,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                              height: 1.1,
                            ),
                            octaveColor: colors.onSurfaceVariant,
                          ),
                          Text(live ? 'Nota rilevata' : 'Ultima nota',
                              style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${detection.cents >= 0 ? '+' : ''}${detection.cents.toStringAsFixed(0)} cent',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: detection.cents.abs() <= PitchRecognitionConfig.inTuneCents
                                ? const Color(0xFF22C55E)
                                : colors.error,
                          ),
                        ),
                        Text('Scostamento', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Accesso rapido: notazione, tema, impostazioni.
class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notation = ref.watch(notationProvider);
    final themeSetting = ref.watch(themeSettingProvider);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _QuickAction(
              key: const ValueKey('quick-notation'),
              icon: Icons.music_note_outlined,
              label: 'Notazione',
              value: notation == NoteNotation.italian ? 'DO RE MI' : 'C D E',
              onTap: () => ref.read(notationProvider.notifier).setNotation(
                    notation == NoteNotation.italian ? NoteNotation.english : NoteNotation.italian,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickAction(
              key: const ValueKey('quick-theme'),
              icon: Icons.brightness_6_outlined,
              label: 'Tema',
              value: themeLabel(themeSetting),
              onTap: () => _chooseTheme(context, ref),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickAction(
              key: const ValueKey('quick-settings'),
              icon: Icons.settings_outlined,
              label: 'Impostazioni',
              onTap: () => pushFullScreen(context, ref, '/settings'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseTheme(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(themeSettingProvider);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final setting in AppThemeSetting.values)
                  ListTile(
                    title: Text(themeLabel(setting)),
                    trailing: setting == current ? const Icon(Icons.check) : null,
                    onTap: () {
                      ref.read(themeSettingProvider.notifier).setThemeSetting(setting);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Nome del tema come nelle impostazioni.
String themeLabel(AppThemeSetting setting) => switch (setting) {
      AppThemeSetting.system => 'Sistema',
      AppThemeSetting.light => 'Chiaro',
      AppThemeSetting.dark => 'Scuro',
      AppThemeSetting.neon => 'Neon',
    };

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (value != null)
                Text(value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
