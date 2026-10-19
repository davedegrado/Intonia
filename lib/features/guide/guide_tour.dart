import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_router.dart';
import '../../app/app_theme.dart';
import '../../app/l10n.dart';
import '../mascot/domain/mascot_mood.dart';
import '../mascot/presentation/intonia_mascot.dart';
import '../tuner/application/tuner_controller.dart';
import 'guide.dart';

/// Passaggio corrente della guida.
class GuideTourState {
  const GuideTourState({required this.steps, required this.index, this.forward = true});

  final List<GuideStep> steps;
  final int index;

  /// Si sta andando avanti (true) o indietro: un passaggio da saltare si
  /// salta nella stessa direzione.
  final bool forward;

  GuideStep get step => steps[index];
  bool get isFirst => index == 0;
  bool get isLast => index == steps.length - 1;
}

/// Guida attiva (null = nessuna guida aperta).
final guideTourProvider = NotifierProvider<GuideTourController, GuideTourState?>(
  GuideTourController.new,
);

class GuideTourController extends Notifier<GuideTourState?> {
  Completer<void>? _done;

  @override
  GuideTourState? build() {
    ref.onDispose(() => _complete());
    return null;
  }

  /// Avvia la guida (ne chiude un'eventuale altra); il future si completa
  /// alla chiusura.
  Future<void> start(List<GuideStep> steps) {
    _complete();
    if (steps.isEmpty) {
      state = null;
      return Future.value();
    }
    final done = _done = Completer<void>();
    state = GuideTourState(steps: steps, index: 0);
    return done.future;
  }

  void next() {
    final tour = state;
    if (tour == null) {
      return;
    }
    if (tour.isLast) {
      close();
    } else {
      state = GuideTourState(steps: tour.steps, index: tour.index + 1);
    }
  }

  void back() {
    final tour = state;
    if (tour != null && !tour.isFirst) {
      state = GuideTourState(steps: tour.steps, index: tour.index - 1, forward: false);
    }
  }

  /// Salta il passaggio corrente (elemento assente, sezione non
  /// raggiungibile) proseguendo nella direzione in cui si stava andando.
  void skip() {
    final tour = state;
    if (tour == null) {
      return;
    }
    if (tour.forward || tour.isFirst) {
      next();
    } else {
      back();
    }
  }

  /// Chiude la guida (fine, "Salta" o "Chiudi"): nessun overlay resta attivo.
  void close() {
    state = null;
    _complete();
  }

  void _complete() {
    final done = _done;
    _done = null;
    if (done != null && !done.isCompleted) {
      done.complete();
    }
  }
}

/// Livello della guida sopra tutta l'app: attenua l'interfaccia, mette in
/// risalto l'elemento di cui parla Intonia e mostra il riquadro con la
/// mascotte vicino all'elemento (o al centro se non c'è).
class GuideTourLayer extends ConsumerStatefulWidget {
  const GuideTourLayer({required this.child, super.key});

  final Widget child;

  /// Attesa dopo un cambio di sezione quando l'elemento non c'è ancora (le
  /// transizioni delle pagine con l'elemento si attendono direttamente).
  static const navigationSettle = Duration(milliseconds: 400);

  /// Limite all'attesa di una transizione di pagina.
  static const transitionTimeout = Duration(milliseconds: 1200);

  @override
  ConsumerState<GuideTourLayer> createState() => _GuideTourLayerState();
}

class _GuideTourLayerState extends ConsumerState<GuideTourLayer>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _layerKey = GlobalKey();

  /// Elemento evidenziato (coordinate del livello); null = nessuno.
  Rect? _target;

  /// Il passaggio ha un elemento ma non è disponibile ora.
  bool _missing = false;

  /// Incrementato a ogni nuovo passaggio: una misura in ritardo di un
  /// passaggio precedente viene scartata.
  int _token = 0;

  late final AnimationController _pulse;

  /// Segue l'elemento a ogni fotogramma mentre la guida è aperta (una
  /// categoria che si apre, una pagina che scorre) e si accorge quando
  /// compare l'elemento atteso da un passaggio da toccare.
  late final Ticker _tracker;

  /// La guida stessa sta cambiando sezione: i cambi di pagina che ne
  /// derivano non vanno trattati come navigazione dell'utente.
  bool _selfNavigating = false;

  /// Un passaggio è in preparazione: il riquadro resta nascosto e
  /// l'evidenziazione precedente non viene mostrata sulla nuova pagina.
  bool _preparing = false;

  /// L'utente ha appena cambiato pagina toccando l'elemento evidenziato: il
  /// passaggio successivo attende la fine della transizione.
  bool _userNavigated = false;

  late final _router = ref.read(appRouterProvider);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _tracker = createTicker(_track);
    WidgetsBinding.instance.addObserver(this);
    _router.routerDelegate.addListener(_onRouteChanged);
    // Livello ricreato con una guida già aperta (es. alla fine dello splash):
    // si rimisura il passaggio corrente.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tour = mounted ? ref.read(guideTourProvider) : null;
      if (tour != null) {
        _tracker.start();
        unawaited(_prepare(tour, navigate: false));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.routerDelegate.removeListener(_onRouteChanged);
    _tracker.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Ultima pagina aperta, anche se aperta con push (l'uri resta quello
  /// della scheda).
  String? get _location => _router.routerDelegate.currentConfiguration.lastOrNull?.matchedLocation;

  /// Pagina cambiata dall'utente. Se è quella attesa dal passaggio da
  /// toccare la guida prosegue; altrimenti (es. "indietro" di sistema) si
  /// rimisura, e se l'elemento non c'è più la spiegazione resta leggibile al
  /// centro.
  void _onRouteChanged() {
    final tour = ref.read(guideTourProvider);
    if (tour == null || _selfNavigating) {
      return;
    }
    final awaited = tour.step.awaitRoute;
    if (awaited != null && awaited == _location) {
      _userNavigated = true;
      ref.read(guideTourProvider.notifier).next();
      return;
    }
    _userNavigated = true;
    unawaited(_prepare(tour, navigate: false));
  }

  /// A ogni fotogramma: l'elemento atteso è comparso? L'elemento evidenziato
  /// si è spostato o ingrandito?
  void _track(Duration _) {
    final tour = ref.read(guideTourProvider);
    if (tour == null || _preparing || !mounted) {
      return;
    }
    final step = tour.step;
    final awaited = step.awaitTarget;
    if (awaited != null && GuideAnchor.contextOf(awaited) != null) {
      ref.read(guideTourProvider.notifier).next();
      return;
    }
    final target = step.target;
    final current = _target;
    final anchor = target == null || current == null ? null : GuideAnchor.contextOf(target);
    final rect = anchor == null ? null : _measure(anchor);
    if (rect != null && !_sameRect(rect, current!)) {
      setState(() => _target = rect);
    }
  }

  static bool _sameRect(Rect a, Rect b) =>
      (a.left - b.left).abs() < 0.5 &&
      (a.top - b.top).abs() < 0.5 &&
      (a.right - b.right).abs() < 0.5 &&
      (a.bottom - b.bottom).abs() < 0.5;

  @override
  void didChangeMetrics() {
    // Rotazione, tastiera, finestra ridimensionata: si rimisura.
    final tour = ref.read(guideTourProvider);
    if (tour != null) {
      unawaited(_prepare(tour, navigate: false));
    }
  }

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  Future<void> _prepare(GuideTourState tour, {bool navigate = true}) async {
    final token = ++_token;
    final step = tour.step;
    // Il riquadro sparisce finché il nuovo elemento non è misurato: niente
    // evidenziazione del passaggio precedente sulla nuova pagina.
    _preparing = true;
    _setStateSafely(() {
      _target = null;
      _missing = false;
    });
    final section = step.section;
    // Sezioni in cui solo l'utente può portare (es. l'esercizio aperto):
    // se non c'è più, quei passaggi si saltano.
    final unreachable =
        section != null && section != _location && !guideReachableSections.contains(section);
    if (unreachable) {
      // Subito, senza attendere un fotogramma per ciascuno dei passaggi saltati.
      scheduleMicrotask(() => _skip(token));
      return;
    }
    var navigated = _userNavigated;
    _userNavigated = false;
    if (navigate && section != null) {
      navigated = _goTo(section) || navigated;
    }
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted || token != _token) {
      return;
    }
    final awaited = step.awaitTarget;
    if (awaited != null && GuideAnchor.contextOf(awaited) != null) {
      // Già fatto (es. categoria già aperta).
      _skip(token);
      return;
    }
    final target = step.target;
    if (navigated) {
      final anchor = target == null ? null : GuideAnchor.contextOf(target);
      if (anchor != null && anchor.mounted) {
        await _routesSettled(anchor);
      } else {
        await Future<void>.delayed(GuideTourLayer.navigationSettle);
      }
      if (token == _token) {
        _selfNavigating = false;
      }
      if (!mounted || token != _token) {
        return;
      }
    }
    final anchor = target == null ? null : GuideAnchor.contextOf(target);
    if (anchor != null && anchor.mounted) {
      // L'elemento può essere fuori schermo in una pagina che scorre.
      await Scrollable.ensureVisible(
        anchor,
        alignment: 0.3,
        duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
      );
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted || token != _token) {
        return;
      }
    }
    // Si rilegge dopo le attese: l'elemento può essere stato smontato.
    final current = target == null ? null : GuideAnchor.contextOf(target);
    final rect = current != null && current.mounted ? _measure(current) : null;
    if (target != null && rect == null && step.skipIfMissing) {
      _skip(token);
      return;
    }
    _preparing = false;
    setState(() {
      _target = rect;
      _missing = target != null && rect == null;
    });
    if (rect == null || _reduceMotion) {
      _pulse.value = 0;
    } else if (step.interactive) {
      // Da toccare: l'onda continua finché l'utente non tocca.
      _pulse.repeat();
    } else {
      _pulse.repeat(count: 2);
    }
  }

  void _skip(int token) {
    if (token == _token) {
      _preparing = false;
      _selfNavigating = false;
      ref.read(guideTourProvider.notifier).skip();
    }
  }

  /// setState anche se chiamato mentre si costruisce un fotogramma.
  void _setStateSafely(VoidCallback update) {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      update();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      setState(update);
    }
  }

  /// Attende che le pagine attorno all'elemento abbiano finito di entrare o
  /// di scoprirsi (push, pop), così la misura è quella definitiva.
  Future<void> _routesSettled(BuildContext anchor) async {
    final waits = <Future<void>>[];
    BuildContext? context = anchor;
    while (context != null && context.mounted) {
      final route = ModalRoute.of(context);
      if (route == null) {
        break;
      }
      final entering = route.animation;
      if (entering != null && entering.status != AnimationStatus.completed) {
        waits.add(_untilStatus(entering, AnimationStatus.completed));
      }
      final covered = route.secondaryAnimation;
      if (covered != null && covered.status != AnimationStatus.dismissed) {
        waits.add(_untilStatus(covered, AnimationStatus.dismissed));
      }
      context = route.navigator?.context;
    }
    if (waits.isNotEmpty) {
      await Future.wait(waits).timeout(GuideTourLayer.transitionTimeout, onTimeout: () => []);
    }
  }

  static Future<void> _untilStatus(Animation<double> animation, AnimationStatus status) {
    final done = Completer<void>();
    void listener(AnimationStatus current) {
      if (current == status && !done.isCompleted) {
        animation.removeStatusListener(listener);
        done.complete();
      }
    }

    animation.addStatusListener(listener);
    return done.future;
  }

  /// Porta alla sezione del passaggio; true se ha cambiato schermata.
  bool _goTo(String section) {
    final router = _router;
    if (_location == section) {
      return false;
    }
    _selfNavigating = true;
    // Il riconoscimento in tempo reale vive solo nella Home.
    ref.read(tunerControllerProvider.notifier).stop();
    if (section == '/settings') {
      router.push(section);
    } else {
      router.go(section);
    }
    return true;
  }

  /// Rettangolo dell'elemento nel livello, se è visibile sulla schermata attuale.
  Rect? _measure(BuildContext anchor) {
    final box = anchor.findRenderObject();
    final layer = _layerKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize || layer is! RenderBox) {
      return null;
    }
    // Su una pagina coperta da un'altra (anche a un livello superiore, es.
    // le schede sotto un esercizio aperto) non si evidenzia nulla.
    BuildContext? context = anchor;
    while (context != null && context.mounted) {
      final route = ModalRoute.of(context);
      if (route == null) {
        break;
      }
      if (!route.isCurrent) {
        return null;
      }
      context = route.navigator?.context;
    }
    // Né in una scheda non visibile (le schede restano montate fuori scena).
    for (RenderObject? node = box; node != null && node != layer; node = node.parent) {
      if (node is RenderOffstage && node.offstage) {
        return null;
      }
    }
    final topLeft = box.localToGlobal(Offset.zero, ancestor: layer);
    final rect = topLeft & box.size;
    final visible = rect.intersect(Offset.zero & layer.size);
    if (rect.isEmpty || visible.isEmpty || visible.height < math.min(24, rect.height)) {
      return null;
    }
    return rect;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GuideTourState?>(guideTourProvider, (previous, next) {
      if (next == null) {
        _token++;
        _selfNavigating = false;
        _preparing = false;
        _userNavigated = false;
        _pulse.stop();
        _tracker.stop();
        setState(() {
          _target = null;
          _missing = false;
        });
      } else if (previous == null ||
          previous.index != next.index ||
          !identical(previous.steps, next.steps)) {
        if (!_tracker.isActive) {
          _tracker.start();
        }
        unawaited(_prepare(next));
      }
    });
    final tour = ref.watch(guideTourProvider);

    return Stack(
      key: _layerKey,
      children: [
        widget.child,
        if (tour != null)
          Positioned.fill(
            child: _TourOverlay(
              tour: tour,
              target: _target,
              missing: _missing,
              ready: !_preparing,
              pulse: _pulse,
            ),
          ),
      ],
    );
  }
}

class _TourOverlay extends ConsumerWidget {
  const _TourOverlay({
    required this.tour,
    required this.target,
    required this.missing,
    required this.ready,
    required this.pulse,
  });

  final GuideTourState tour;
  final Rect? target;
  final bool missing;

  /// Passaggio pronto: il riquadro è visibile.
  final bool ready;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final decor = context.decor;
    final padding = MediaQuery.paddingOf(context);
    final ring = decor.ambient ? decor.heroBorder : colors.primary;
    final hole = target?.inflate(6);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return _PassThroughHole(
      // Nei passaggi da toccare l'elemento evidenziato risponde ai tocchi.
      hole: tour.step.interactive ? hole : null,
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: Stack(
          children: [
            // Il resto dell'interfaccia è attenuato e non risponde ai tocchi
            // durante la guida (l'elemento evidenziato solo nei passaggi da
            // toccare).
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('guide-scrim'),
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (context, _) => CustomPaint(
                    painter: _ScrimPainter(
                      hole: hole,
                      dim: Colors.black.withValues(alpha: decor.ambient ? 0.62 : 0.5),
                      ring: ring,
                      glow: decor.ambient,
                      pulse: pulse.value,
                    ),
                  ),
                ),
              ),
            ),
            if (hole != null)
              Positioned.fromRect(
                rect: hole,
                child: const IgnorePointer(
                  child: SizedBox(key: ValueKey('guide-highlight')),
                ),
              ),
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: _CardLayout(target: hole, padding: padding),
                child: IgnorePointer(
                  ignoring: !ready,
                  child: AnimatedOpacity(
                    opacity: ready ? 1 : 0,
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
                    child: _GuideCard(tour: tour, missing: missing),
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

/// Lascia passare i tocchi dentro [hole] all'app sotto la guida.
class _PassThroughHole extends SingleChildRenderObjectWidget {
  const _PassThroughHole({required this.hole, required super.child});

  final Rect? hole;

  @override
  _RenderPassThroughHole createRenderObject(BuildContext context) => _RenderPassThroughHole(hole);

  @override
  void updateRenderObject(BuildContext context, _RenderPassThroughHole renderObject) {
    renderObject.hole = hole;
  }
}

class _RenderPassThroughHole extends RenderProxyBox {
  _RenderPassThroughHole(this.hole);

  Rect? hole;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hole?.contains(position) ?? false) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}

/// Attenuazione con un "foro" arrotondato sull'elemento e un anello luminoso
/// che pulsa brevemente.
class _ScrimPainter extends CustomPainter {
  _ScrimPainter({
    required this.hole,
    required this.dim,
    required this.ring,
    required this.glow,
    required this.pulse,
  });

  final Rect? hole;
  final Color dim;
  final Color ring;
  final bool glow;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final hole = this.hole;
    if (hole == null) {
      canvas.drawPath(screen, Paint()..color = dim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(16));
    canvas.drawPath(
      Path.combine(PathOperation.difference, screen, Path()..addRRect(rrect)),
      Paint()..color = dim,
    );
    if (glow) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = ring.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = glow ? 2.5 : 3.5,
    );
    // Onda che si allarga e svanisce attorno all'elemento.
    if (pulse > 0 && pulse < 1) {
      final grow = 10 * pulse;
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole.inflate(grow), Radius.circular(16 + grow)),
        Paint()
          ..color = ring.withValues(alpha: 0.6 * (1 - pulse))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.dim != dim || old.ring != ring || old.pulse != pulse;
}

/// Posiziona il riquadro sotto l'elemento, altrimenti sopra, altrimenti al
/// centro; sempre dentro le aree sicure e senza coprire l'elemento quando
/// c'è spazio.
class _CardLayout extends SingleChildLayoutDelegate {
  _CardLayout({required this.target, required this.padding});

  final Rect? target;
  final EdgeInsets padding;

  static const margin = 12.0;
  static const gap = 12.0;
  static const maxWidth = 440.0;

  /// Altezza minima utile del riquadro (intestazione, testo breve, pulsanti).
  static const minCardHeight = 150.0;

  /// Spazio libero sopra e sotto l'elemento, dentro le aree sicure.
  (double, double) _free(Size size) {
    final target = this.target!;
    final above = target.top - gap - (padding.top + margin);
    final below = size.height - padding.bottom - margin - (target.bottom + gap);
    return (above, below);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.min(constraints.maxWidth - 2 * margin, maxWidth);
    var height = constraints.maxHeight - padding.vertical - 2 * margin;
    if (target != null) {
      // Se il riquadro intero non sta né sopra né sotto, lo si limita allo
      // spazio libero più ampio (il testo scorre) per non coprire l'elemento.
      final (above, below) = _free(constraints.biggest);
      final larger = math.max(above, below);
      if (larger >= minCardHeight) {
        height = math.min(height, larger);
      }
    }
    return BoxConstraints(maxWidth: math.max(0, width), maxHeight: math.max(0, height));
  }

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (size.width - child.width) / 2;
    final top = padding.top + margin;
    final bottom = size.height - padding.bottom - margin;
    final centered = top + (bottom - top - child.height) / 2;
    final target = this.target;
    if (target == null) {
      return Offset(x, centered);
    }
    final (above, below) = _free(size);
    if (child.height <= below && (below >= above || child.height > above)) {
      return Offset(x, target.bottom + gap);
    }
    if (child.height <= above) {
      return Offset(x, target.top - gap - child.height);
    }
    // Nessuno spazio sufficiente: dalla parte opposta all'elemento.
    final y = target.center.dy > size.height / 2 ? top : bottom - child.height;
    return Offset(x, math.max(top, y));
  }

  @override
  bool shouldRelayout(_CardLayout old) => old.target != target || old.padding != padding;
}

/// Il riquadro di Intonia: mascotte, testo del passaggio e comandi.
class _GuideCard extends ConsumerWidget {
  const _GuideCard({required this.tour, required this.missing});

  final GuideTourState tour;
  final bool missing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final decor = context.decor;
    final l10n = context.l10n;
    final step = tour.step;
    final controller = ref.read(guideTourProvider.notifier);

    return Material(
      key: const ValueKey('guide-sheet'),
      color: colors.surface,
      elevation: decor.ambient ? 10 : 3,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: decor.ambient ? decor.heroBorder.withValues(alpha: 0.6) : colors.outlineVariant,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 12),
        // Intestazione e pulsanti sempre visibili; se lo spazio è poco scorre
        // solo la spiegazione.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  l10n.guideProgress(tour.index + 1, tour.steps.length),
                  style: theme.textTheme.labelMedium,
                ),
                const Spacer(),
                if (!tour.isLast)
                  TextButton(
                    key: const ValueKey('guide-skip'),
                    onPressed: controller.close,
                    child: Text(l10n.guideSkip),
                  ),
                // Senza tooltip: la guida sta sopra il Navigator, dove non c'è
                // un Overlay; l'etichetta resta per i lettori di schermo.
                Semantics(
                  label: l10n.commonClose,
                  button: true,
                  excludeSemantics: true,
                  child: IconButton(
                    key: const ValueKey('guide-close'),
                    icon: const Icon(Icons.close),
                    onPressed: controller.close,
                  ),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IntoniaMascot(
                        mood: tour.isFirst ? MascotMood.greeting : MascotMood.idle,
                        size: 60,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(step.icon, size: 20, color: colors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    step.title,
                                    key: const ValueKey('guide-title'),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(step.text,
                                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
                            if (missing) ...[
                              const SizedBox(height: 6),
                              Text(
                                l10n.guideTargetUnavailable,
                                key: const ValueKey('guide-no-target'),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  if (!tour.isFirst) ...[
                    // Nei passaggi da toccare Indietro si stringe e lascia
                    // posto al suggerimento.
                    Flexible(
                      fit: step.interactive ? FlexFit.loose : FlexFit.tight,
                      child: OutlinedButton(
                        key: const ValueKey('guide-back'),
                        onPressed: controller.back,
                        child: Text(l10n.commonBack),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: step.interactive
                        // Nessun Avanti: si prosegue toccando l'elemento.
                        ? Row(
                            key: const ValueKey('guide-tap-hint'),
                            children: [
                              Icon(Icons.touch_app_rounded, color: colors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  l10n.guideTapHint,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : FilledButton(
                            key: const ValueKey('guide-next'),
                            onPressed: controller.next,
                            child: Text(tour.isLast ? l10n.guideDone : l10n.guideNext),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
