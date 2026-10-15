import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/l10n.dart';
import '../../../app/main_shell.dart';
import '../../../app/neon_scene.dart';
import '../../../app/note_text.dart';
import '../../../app/status_chips.dart';
import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';
import '../../../core/pitch/pitch_detection_result.dart';
import '../../../core/pitch/pitch_recognition_config.dart';
import '../../guide/guide.dart';
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

  /// Festa della mascotte quando la nota diventa intonata (al massimo una
  /// ogni [_celebrationGap], così non "saltella" di continuo).
  static const _celebrationGap = Duration(seconds: 3);
  bool _wasInTune = false;
  DateTime? _lastCelebration;
  int _reactionId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGuideOnce());
  }

  /// Al primo avvio la mascotte presenta l'app una sola volta: completata,
  /// saltata o chiusa, la guida non si ripropone (si riapre dalle Impostazioni).
  Future<void> _showGuideOnce() async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final seen = await repository.loadGuideSeen();
    if (seen != false || !mounted) {
      return;
    }
    await showGuide(context, appGuideSteps(context.l10n));
    await repository.saveGuideSeen();
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

  void _onTuner(TunerState? previous, TunerState next) {
    final detection = next.detection;
    final stable = next.active && detection != null && detection.isStable;
    final inTune = stable && detection.cents.abs() <= PitchRecognitionConfig.inTuneCents;
    var celebrate = false;
    if (inTune && !_wasInTune) {
      final now = DateTime.now();
      final last = _lastCelebration;
      if (last == null || now.difference(last) >= _celebrationGap) {
        _lastCelebration = now;
        celebrate = true;
      }
    }
    _wasInTune = inTune;
    if (stable || celebrate) {
      setState(() {
        if (stable) {
          _lastNote = detection;
        }
        if (celebrate) {
          _reactionId++;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tunerControllerProvider, _onTuner);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final tuner = ref.watch(tunerControllerProvider);
    final detection = tuner.detection;
    final hasPitch = tuner.active && detection != null && detection.isStable;
    final inTune = hasPitch && detection.cents.abs() <= PitchRecognitionConfig.inTuneCents;

    final message = tuner.permissionDenied
        ? l10n.homeBubblePermissionDenied
        : !tuner.active
            ? l10n.homeBubbleIdle
            : !hasPitch
                ? l10n.homeBubbleListening
                : inTune
                    ? l10n.homeBubbleInTune
                    : l10n.homeBubbleAlmost;

    return SectionScaffold(
      title: l10n.appTitle,
      actions: const [StatusChips()],
      variant: SceneVariant.home,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Mascotte e microfono si adattano all'altezza disponibile; sotto
            // una certa altezza la pagina scorre invece di andare in overflow.
            final height = math.max(constraints.maxHeight, 480.0);
            final mascotSize = (height * 0.31).clamp(110.0, 270.0);
            final micSize = (height * 0.16).clamp(84.0, 124.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SpeechBubble(message: message, isError: tuner.permissionDenied),
                    const SizedBox(height: 6),
                    MascotStage(
                      size: mascotSize,
                      child: IntoniaMascot(
                        key: const ValueKey('home-mascot'),
                        mood: tuner.active ? MascotMood.listening : MascotMood.idle,
                        reaction: _reactionId == 0
                            ? null
                            : MascotReaction(mood: MascotMood.success, id: _reactionId),
                        size: mascotSize,
                        greetOnAppear: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _MicButton(
                      size: micSize,
                      active: tuner.active,
                      onPressed: () {
                        final controller = ref.read(tunerControllerProvider.notifier);
                        tuner.active ? controller.stop() : controller.start();
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tuner.active ? l10n.homeStopListening : l10n.homeStartListening,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    _NoteCard(detection: hasPitch ? detection : _lastNote, live: hasPitch),
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

/// Fumetto della mascotte, con la punta verso di lei.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.message, this.isError = false});

  static const maxLines = 2;
  static const verticalPadding = 12.0;

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final decor = context.decor;
    final border = isError
        ? colors.error
        : decor.ambient
            ? decor.heroBorder.withValues(alpha: 0.55)
            : colors.outlineVariant;
    final fill = decor.ambient ? colors.surface.withValues(alpha: 0.92) : colors.surface;
    final style = theme.textTheme.bodyLarge?.copyWith(
      color: isError ? colors.error : colors.onSurface,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
    // Altezza fissa per due righe, qualunque sia il messaggio o la lingua:
    // la mascotte sotto il fumetto non si sposta mai.
    final lineHeight = MediaQuery.textScalerOf(context).scale(style?.fontSize ?? 16) * 1.3;
    final height = (lineHeight * _SpeechBubble.maxLines).ceilToDouble() +
        _SpeechBubble.verticalPadding * 2 +
        2;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const ValueKey('home-bubble'),
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: _SpeechBubble.verticalPadding,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border, width: 1.2),
              boxShadow: decor.ambient
                  ? [
                      BoxShadow(
                        color: decor.glow.withValues(alpha: 0.35),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                message,
                key: ValueKey(message),
                textAlign: TextAlign.center,
                maxLines: _SpeechBubble.maxLines,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(22, 10),
            painter: _BubbleTailPainter(fill: fill, border: border),
          ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.fill, required this.border});

  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, -1)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, -1);
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.border != border;
}

/// Grande pulsante circolare del riconoscimento. Stessa forma in ogni tema;
/// in Neon con sfumatura viola, anello ciano e ombra colorata.
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
    final colors = Theme.of(context).colorScheme;
    final decor = context.decor;
    final size = widget.size;
    final ring = size * 0.14;
    final ringColor = decor.ambient ? decor.heroBorder : colors.outlineVariant;

    return Semantics(
      button: true,
      label: widget.active ? context.l10n.homeMicStopSemantics : context.l10n.homeMicStartSemantics,
      child: SizedBox.square(
        dimension: size + ring * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Anello esterno fisso.
            Container(
              width: size + ring,
              height: size + ring,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor.withValues(alpha: 0.45), width: 1.5),
              ),
            ),
            // Onda che si espande durante l'ascolto.
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                return Opacity(
                  opacity: widget.active ? (1 - t) * 0.8 : 0,
                  child: Container(
                    width: size + ring * 2 * t,
                    height: size + ring * 2 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: decor.heroBorder, width: 3),
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
                gradient: decor.heroGradient,
                // Bordo presente in ogni tema (trasparente fuori da Neon): la
                // geometria del pulsante non cambia.
                border: Border.all(
                  color:
                      decor.ambient ? decor.heroBorder.withValues(alpha: 0.9) : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: decor.ambient
                    ? [
                        BoxShadow(
                          color: decor.glow.withValues(alpha: 0.55),
                          blurRadius: size * 0.35,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: decor.heroBorder.withValues(alpha: 0.25),
                          blurRadius: size * 0.12,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: const ValueKey('home-mic'),
                  customBorder: const CircleBorder(),
                  onTap: widget.onPressed,
                  child: Icon(
                    widget.active ? Icons.stop_rounded : Icons.mic_rounded,
                    size: size * 0.44,
                    color: decor.onHero,
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

/// Nota riconosciuta (in diretta) o l'ultima riconosciuta: il nome della nota
/// in grande, lo scostamento in secondo piano. Altezza fissa, così la pagina
/// non "salta" quando compare la prima nota.
class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.detection, required this.live});

  final PitchDetectionResult? detection;
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final decor = context.decor;
    final notation = ref.watch(notationProvider);
    final l10n = context.l10n;
    final detection = this.detection;

    return SizedBox(
      height: 84,
      child: Card(
        key: const ValueKey('home-note-card'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: detection == null
              ? Center(
                  child: Text(
                    l10n.homeNotePlaceholder,
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
                          Text(live ? l10n.homeNoteDetected : l10n.homeLastNote,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: colors.onSurfaceVariant)),
                          NoteText(
                            NoteSpeller.spellRoot(detection.note),
                            notation: notation,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                              height: 1.1,
                            ),
                            octaveColor: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 44, color: colors.outlineVariant),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.homeDeviation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: colors.onSurfaceVariant)),
                        Text(
                          l10n.homeCents(
                            '${detection.cents >= 0 ? '+' : ''}${detection.cents.toStringAsFixed(0)}',
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: detection.cents.abs() <= PitchRecognitionConfig.inTuneCents
                                ? decor.success
                                : colors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Accesso rapido (secondario): notazione, tema, impostazioni.
class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notation = ref.watch(notationProvider);
    final themeSetting = ref.watch(themeSettingProvider);
    final l10n = context.l10n;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _QuickAction(
              key: const ValueKey('quick-notation'),
              icon: Icons.music_note_outlined,
              label: l10n.homeQuickNotation,
              value: notation == NoteNotation.italian
                  ? l10n.notationItalian
                  : l10n.notationInternational,
              onTap: () => ref.read(notationProvider.notifier).setNotation(
                    notation == NoteNotation.italian ? NoteNotation.english : NoteNotation.italian,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickAction(
              key: const ValueKey('quick-theme'),
              icon: Icons.palette_outlined,
              label: l10n.homeQuickTheme,
              value: themeLabel(l10n, themeSetting),
              onTap: () => _chooseTheme(context, ref),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickAction(
              key: const ValueKey('quick-settings'),
              icon: Icons.settings_outlined,
              label: l10n.homeQuickSettings,
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
                    title: Text(themeLabel(context.l10n, setting)),
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
String themeLabel(AppLocalizations l10n, AppThemeSetting setting) => switch (setting) {
      AppThemeSetting.system => l10n.themeSystem,
      AppThemeSetting.light => l10n.themeLight,
      AppThemeSetting.dark => l10n.themeDark,
      AppThemeSetting.neon => l10n.themeNeon,
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
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: colors.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (value != null)
                Text(value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
