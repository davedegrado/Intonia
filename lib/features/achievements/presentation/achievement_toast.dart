import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/l10n.dart';
import '../application/achievements_providers.dart';
import '../domain/achievements.dart';
import 'achievement_badge.dart';

/// Annuncio dei badge appena sbloccati: una piccola scheda in alto che non
/// blocca nulla (l'esercizio continua sotto) e sparisce da sola; un tocco
/// la chiude. Senza animazioni se il sistema le riduce.
class AchievementToastHost extends ConsumerStatefulWidget {
  const AchievementToastHost({required this.child, super.key});

  final Widget child;

  /// Quanto resta visibile ogni annuncio.
  static const visibleFor = Duration(milliseconds: 3500);

  @override
  ConsumerState<AchievementToastHost> createState() => _AchievementToastHostState();
}

class _AchievementToastHostState extends ConsumerState<AchievementToastHost> {
  Timer? _timer;
  AchievementId? _shown;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule(AchievementId? current) {
    if (current == _shown) {
      return;
    }
    _shown = current;
    _timer?.cancel();
    if (current != null) {
      _timer = Timer(AchievementToastHost.visibleFor, _dismiss);
    }
  }

  void _dismiss() {
    if (mounted) {
      ref.read(achievementToastsProvider.notifier).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tiene attivi salvataggio dei traguardi e coda degli annunci.
    ref.watch(achievementSyncProvider);
    final queue = ref.watch(achievementToastsProvider);
    final current = queue.isEmpty ? null : queue.first;
    _schedule(current);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 12,
          right: 12,
          top: MediaQuery.paddingOf(context).top + 8,
          child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, -0.3), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: current == null
                ? const SizedBox.shrink()
                : _Toast(key: ValueKey(current), id: current, onTap: _dismiss),
          ),
        ),
      ],
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.id, required this.onTap, super.key});

  final AchievementId id;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final decor = context.decor;
    final l10n = context.l10n;
    return Semantics(
      liveRegion: true,
      child: Material(
        key: const ValueKey('achievement-toast'),
        elevation: 6,
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    decor.ambient ? decor.heroBorder.withValues(alpha: 0.6) : colors.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                AchievementBadge(id: id, unlocked: true, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.achievementsToastTitle,
                        style: theme.textTheme.labelMedium?.copyWith(color: colors.primary),
                      ),
                      Text(
                        l10n.achievementName(id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
