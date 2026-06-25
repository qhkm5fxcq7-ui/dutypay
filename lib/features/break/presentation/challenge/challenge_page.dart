import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/break_participant.dart';
import '../challenge/engine/challenge_state.dart';
import '../challenge/models/challenge_runner.dart';
import '../challenge/widgets/challenge_countdown.dart';
import '../challenge/widgets/challenge_result.dart';
import '../challenge/widgets/challenge_track.dart';

class ChallengePage extends StatefulWidget {
  final List<BreakParticipant> participants;
  final String selectedPayerId;
  final String roundSeed;
  final String resultText;

  const ChallengePage({
    super.key,
    required this.participants,
    required this.selectedPayerId,
    required this.roundSeed,
    required this.resultText,
  });

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  ChallengeState _state = ChallengeState.countdown;
  int _countdownValue = 3;
  late List<ChallengeRunner> _runners;

  @override
  void initState() {
    super.initState();
    _runners = _buildRunners();
    _startSequence();
  }

  Future<void> _startSequence() async {
    for (final value in [3, 2, 1]) {
      if (!mounted) return;

      setState(() {
        _state = ChallengeState.countdown;
        _countdownValue = value;
      });

      await Future<void>.delayed(const Duration(milliseconds: 700));
    }

    if (!mounted) return;

    setState(() {
      _state = ChallengeState.running;
    });

    for (var step = 0; step <= 20; step++) {
      if (!mounted) return;

      final progress = step / 20;

      setState(() {
        _runners = _runners.map((runner) {
          final targetProgress =
              runner.isWinner ? progress : (progress * 0.86).clamp(0.0, 0.92);

          return runner.copyWith(position: targetProgress);
        }).toList();
      });

      await Future<void>.delayed(const Duration(milliseconds: 110));
    }

    if (!mounted) return;

    setState(() {
      _state = ChallengeState.finished;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      _state = ChallengeState.completed;
    });
  }

  List<ChallengeRunner> _buildRunners() {
    return widget.participants.asMap().entries.map((entry) {
      return ChallengeRunner.fromParticipant(
        participant: entry.value,
        lane: entry.key,
        selectedPayerId: widget.selectedPayerId,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Break Challenge'),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_state) {
      case ChallengeState.countdown:
        return ChallengeCountdown(
          key: ValueKey('countdown_$_countdownValue'),
          value: _countdownValue,
        );
      case ChallengeState.running:
        return ChallengeTrack(
          key: const ValueKey('running'),
          runners: _runners,
        );
      case ChallengeState.finished:
        return _ChallengePlaceholder(
          key: const ValueKey('finished'),
          title: 'Traguardo raggiunto',
          subtitle: 'Calcolo risultato...',
        );
      case ChallengeState.completed:
        return ChallengeResult(
          key: const ValueKey('completed'),
          resultText: widget.resultText,
        );
    }
  }
}

class _ChallengePlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ChallengePlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🏁',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
