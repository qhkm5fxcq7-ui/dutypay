import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/models/break_participant.dart';

class BreakResultAnimation extends StatefulWidget {
  final List<BreakParticipant> participants;
  final String selectedPayerId;
  final String roundSeed;
  final String resultText;

  const BreakResultAnimation({
    super.key,
    required this.participants,
    required this.selectedPayerId,
    required this.roundSeed,
    required this.resultText,
  });

  @override
  State<BreakResultAnimation> createState() => _BreakResultAnimationState();
}

class _BreakResultAnimationState extends State<BreakResultAnimation> {
  late final List<BreakParticipant> _sequence;
  int _activeIndex = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _sequence = _buildSequence();
    _runAnimation();
  }

  Future<void> _runAnimation() async {
    if (_sequence.isEmpty) return;

    final totalSteps = max(18, _sequence.length * 5);
    final selectedIndex = _sequence.indexWhere(
      (participant) => participant.id == widget.selectedPayerId,
    );

    final targetIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final alignedSteps =
        totalSteps + ((targetIndex - totalSteps) % _sequence.length);

    for (var step = 0; step <= alignedSteps; step++) {
      if (!mounted) return;

      setState(() {
        _activeIndex = step % _sequence.length;
      });

      await Future<void>.delayed(_delayForStep(step, alignedSteps));
    }

    if (!mounted) return;

    setState(() {
      _completed = true;
      _activeIndex = targetIndex;
    });
  }

  Duration _delayForStep(int step, int totalSteps) {
    final progress = step / max(1, totalSteps);
    final millis = 70 + (progress * progress * 230).round();

    return Duration(milliseconds: millis);
  }

  List<BreakParticipant> _buildSequence() {
    final items = List<BreakParticipant>.from(widget.participants);

    if (items.isEmpty) {
      return items;
    }

    final random = Random(_seedToInt(widget.roundSeed));

    for (var i = items.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = items[i];
      items[i] = items[j];
      items[j] = temp;
    }

    final selectedIndex = items.indexWhere(
      (participant) => participant.id == widget.selectedPayerId,
    );

    if (selectedIndex < 0) {
      return items;
    }

    final selected = items.removeAt(selectedIndex);
    items.add(selected);

    return items;
  }

  int _seedToInt(String seed) {
    var hash = 0;

    for (final codeUnit in seed.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = hash ^ (hash >> 6);
    }

    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));

    return hash;
  }

  @override
  Widget build(BuildContext context) {
    if (_sequence.isEmpty) {
      return _ResultCard(resultText: widget.resultText);
    }

    final activeParticipant = _sequence[_activeIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Text(
            _completed ? 'Risultato' : 'Sorteggio in corso...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: _AnimatedParticipant(
              key: ValueKey(activeParticipant.id),
              participant: activeParticipant,
              isCompleted: _completed,
            ),
          ),
          if (_completed) ...[
            const SizedBox(height: 16),
            Text(
              widget.resultText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedParticipant extends StatelessWidget {
  final BreakParticipant participant;
  final bool isCompleted;

  const _AnimatedParticipant({
    super.key,
    required this.participant,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      children: [
        CircleAvatar(
          radius: isCompleted ? 42 : 34,
          child: Text(
            _avatarLabel(participant.displayName),
            style: TextStyle(
              fontSize: isCompleted ? 30 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          participant.displayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompleted ? 24 : 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  String _avatarLabel(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed.characters.first.toUpperCase();
  }
}

class _ResultCard extends StatelessWidget {
  final String resultText;

  const _ResultCard({
    required this.resultText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        resultText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
