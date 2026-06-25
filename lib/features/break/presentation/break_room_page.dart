import 'package:flutter/material.dart';

import '../di/break_dependencies.dart';
import '../domain/models/break_participant.dart';
import '../domain/models/break_room.dart';

class BreakRoomPage extends StatefulWidget {
  final BreakRoom room;

  const BreakRoomPage({
    super.key,
    required this.room,
  });

  @override
  State<BreakRoomPage> createState() => _BreakRoomPageState();
}

class _BreakRoomPageState extends State<BreakRoomPage> {
  late final Future<String> _deviceIdFuture;

  @override
  void initState() {
    super.initState();
    _deviceIdFuture = BreakDependencies.instance.getLocalIdentityUseCase
        .execute()
        .then((identity) => identity.deviceId);
  }

  Future<void> _toggleReady({
    required bool currentValue,
  }) async {
    try {
      await BreakDependencies.instance.setReadyUseCase.execute(
        roomId: widget.room.id,
        isReady: !currentValue,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non sono riuscito ad aggiornare lo stato.'),
        ),
      );
    }
  }

  Future<void> _startRound() async {
    try {
      await BreakDependencies.instance.startRoundUseCase.execute(
        widget.room.id,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Non posso avviare: servono almeno due partecipanti pronti.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = BreakDependencies.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Break'),
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _deviceIdFuture,
          builder: (context, identitySnapshot) {
            final currentDeviceId = identitySnapshot.data;

            return StreamBuilder<BreakRoom?>(
              stream: dependencies.watchRoomUseCase.execute(widget.room.id),
              initialData: widget.room,
              builder: (context, roomSnapshot) {
                final currentRoom = roomSnapshot.data ?? widget.room;

                return StreamBuilder<List<BreakParticipant>>(
                  stream: dependencies.watchParticipantsUseCase.execute(
                    widget.room.id,
                  ),
                  builder: (context, participantsSnapshot) {
                    final participants = participantsSnapshot.data ?? [];
                    final currentParticipant = currentDeviceId == null
                        ? null
                        : _findCurrentParticipant(
                            participants: participants,
                            deviceId: currentDeviceId,
                          );

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                      children: [
                        const Text(
                          'Stanza Break',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Condividi il codice con i colleghi e aspetta che entrino.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 14.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _RoomCodeCard(room: currentRoom),
                        const SizedBox(height: 20),
                        _ParticipantsCard(
                          participants: participants,
                          isLoading: !participantsSnapshot.hasData,
                        ),
                        const SizedBox(height: 20),
                        _ReadyActionCard(
                          room: currentRoom,
                          participants: participants,
                          currentDeviceId: currentDeviceId,
                          currentParticipant: currentParticipant,
                          onToggleReady: _toggleReady,
                          onStartRound: _startRound,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  BreakParticipant? _findCurrentParticipant({
    required List<BreakParticipant> participants,
    required String deviceId,
  }) {
    for (final participant in participants) {
      if (participant.deviceId == deviceId) {
        return participant;
      }
    }

    return null;
  }
}

class _RoomCodeCard extends StatelessWidget {
  final BreakRoom room;

  const _RoomCodeCard({
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Codice stanza',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            room.roomCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            room.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Partecipanti: ${room.participantsCount}/${room.maxParticipants}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.54),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantsCard extends StatelessWidget {
  final List<BreakParticipant> participants;
  final bool isLoading;

  const _ParticipantsCard({
    required this.participants,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final readyCount = participants.where((p) => p.isReady).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Partecipanti',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$readyCount/${participants.length} pronti',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.56),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: CircularProgressIndicator(),
              ),
            )
          else if (participants.isEmpty)
            Text(
              'Nessun partecipante ancora visibile.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...participants.map(_ParticipantTile.new),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final BreakParticipant participant;

  const _ParticipantTile(this.participant);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            child: Text(
              _avatarLabel(participant.displayName),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              participant.displayName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(
            participant.isReady
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: participant.isReady
                ? Colors.greenAccent
                : Colors.white.withValues(alpha: 0.44),
          ),
          const SizedBox(width: 6),
          Text(
            participant.isReady ? 'Pronto' : 'In attesa',
            style: TextStyle(
              color: participant.isReady
                  ? Colors.greenAccent
                  : Colors.white.withValues(alpha: 0.54),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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

class _ReadyActionCard extends StatelessWidget {
  final BreakRoom room;
  final List<BreakParticipant> participants;
  final String? currentDeviceId;
  final BreakParticipant? currentParticipant;
  final Future<void> Function({
    required bool currentValue,
  }) onToggleReady;
  final Future<void> Function() onStartRound;

  const _ReadyActionCard({
    required this.room,
    required this.participants,
    required this.currentDeviceId,
    required this.currentParticipant,
    required this.onToggleReady,
    required this.onStartRound,
  });

  @override
  Widget build(BuildContext context) {
    final participant = currentParticipant;
    final isWaiting = room.status == BreakRoomStatus.waiting;
    final isHost = currentDeviceId != null && currentDeviceId == room.createdBy;
    final canStart = isHost && isWaiting && _canStartRound(participants);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stato',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _statusLabel(room, participants),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (room.resultText != null &&
              room.resultText!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
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
                room.resultText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: participant == null || !isWaiting
                  ? null
                  : () => onToggleReady(
                        currentValue: participant.isReady,
                      ),
              icon: Icon(
                participant?.isReady == true
                    ? Icons.undo_rounded
                    : Icons.check_rounded,
              ),
              label: Text(
                participant?.isReady == true
                    ? 'Non sono pronto'
                    : 'Sono pronto',
              ),
            ),
          ),
          if (isHost) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: canStart ? onStartRound : null,
                icon: const Icon(Icons.local_cafe_rounded),
                label: const Text('Avvia sorteggio'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canStartRound(List<BreakParticipant> participants) {
    if (participants.length < 2) {
      return false;
    }

    return participants.every((participant) => participant.isReady);
  }

  String _statusLabel(
    BreakRoom room,
    List<BreakParticipant> participants,
  ) {
    switch (room.status) {
      case BreakRoomStatus.waiting:
        if (participants.length < 2) {
          return 'Servono almeno due partecipanti per avviare il sorteggio.';
        }

        if (!_canStartRound(participants)) {
          return 'La stanza è in attesa. Tutti devono confermare “Sono pronto”.';
        }

        return 'Tutti pronti. L’host può avviare il sorteggio.';
      case BreakRoomStatus.running:
        return 'La sfida è in corso. Il risultato è sincronizzato per tutti.';
      case BreakRoomStatus.completed:
        return 'La sfida è terminata.';
    }
  }
}
