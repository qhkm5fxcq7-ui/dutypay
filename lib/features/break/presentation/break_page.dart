import 'package:flutter/material.dart';

import '../di/break_dependencies.dart';
import 'break_room_page.dart';

class BreakPage extends StatefulWidget {
  const BreakPage({super.key});

  @override
  State<BreakPage> createState() => _BreakPageState();
}

class _BreakPageState extends State<BreakPage> {
  final _roomCodeController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _customRoomCodeController = TextEditingController();
  String? _nickname;
  bool _isLoadingIdentity = true;

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _nicknameController.dispose();
    _customRoomCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadIdentity() async {
    final identity =
        await BreakDependencies.instance.getLocalIdentityUseCase.execute();

    if (!mounted) return;

    setState(() {
      _nickname = identity.nickname.trim().isEmpty ? null : identity.nickname;
      _isLoadingIdentity = false;
    });
  }

  Future<String?> _ensureNickname() async {
    if (_nickname != null && _nickname!.trim().isNotEmpty) {
      return _nickname;
    }

    _nicknameController.clear();

    final nickname = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Scegli un nickname'),
          content: TextField(
            controller: _nicknameController,
            autofocus: true,
            maxLength: 18,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nickname',
              hintText: 'Es. Marco RM',
            ),
            onSubmitted: (_) {
              final value = _nicknameController.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
          ),
          actions: [
            FilledButton(
              onPressed: () {
                final value = _nicknameController.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(context).pop(value);
                }
              },
              child: const Text('Continua'),
            ),
          ],
        );
      },
    );

    if (nickname == null || nickname.trim().isEmpty) {
      return null;
    }

    final saved = await BreakDependencies.instance.saveNicknameUseCase.execute(
      nickname,
    );

    if (!mounted) return saved.nickname;

    setState(() {
      _nickname = saved.nickname;
    });

    return saved.nickname;
  }

  Future<void> _editNickname() async {
    _nicknameController.text = _nickname ?? '';

    final nickname = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifica nickname'),
          content: TextField(
            controller: _nicknameController,
            autofocus: true,
            maxLength: 18,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nickname',
              hintText: 'Es. Marco RM',
            ),
            onSubmitted: (_) {
              final value = _nicknameController.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                final value = _nicknameController.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(context).pop(value);
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );

    if (nickname == null || nickname.trim().isEmpty) {
      return;
    }

    final saved = await BreakDependencies.instance.saveNicknameUseCase.execute(
      nickname,
    );

    if (!mounted) return;

    setState(() {
      _nickname = saved.nickname;
    });
  }

  Future<String?> _askCustomRoomCode() async {
    _customRoomCodeController.clear();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Codice stanza'),
          content: TextField(
            controller: _customRoomCodeController,
            autofocus: true,
            maxLength: 12,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Codice personalizzato',
              hintText: 'Es. CAFFE, VOLANTE, NOTTE',
              helperText: 'Lascia vuoto per generarlo automaticamente.',
            ),
            onSubmitted: (_) {
              Navigator.of(context).pop(
                _customRoomCodeController.text.trim().toUpperCase(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Automatico'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  _customRoomCodeController.text.trim().toUpperCase(),
                );
              },
              child: const Text('Crea'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCreateRoom() async {
    final nickname = await _ensureNickname();

    if (nickname == null) return;

    final customRoomCode = await _askCustomRoomCode();

    try {
      final room = await BreakDependencies.instance.createRoomUseCase.execute(
        customRoomCode: customRoomCode,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BreakRoomPage(room: room),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Errore durante la creazione della stanza. Riprova tra poco.',
          ),
        ),
      );
    }
  }

  Future<void> _handleJoinRoom() async {
    final roomCode = _roomCodeController.text.trim().toUpperCase();

    if (roomCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un codice stanza.'),
        ),
      );
      return;
    }

    final nickname = await _ensureNickname();

    if (nickname == null) return;

    try {
      final room = await BreakDependencies.instance.joinRoomUseCase.execute(
        roomCode: roomCode,
        nickname: nickname,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BreakRoomPage(room: room),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stanza non trovata o non più disponibile.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          const Text(
            'Chi offre?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea una stanza con i colleghi e scopri chi offre.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 14.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_nickname != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Nickname: $_nickname',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.54),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _editNickname,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Modifica'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '☕ Chi offre?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Una pausa veloce, una stanza condivisa e un sorteggio leggero per decidere chi offre.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoadingIdentity ? null : _handleCreateRoom,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Crea stanza'),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _roomCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Inserisci codice stanza',
                    hintText: 'Es. BRK-X7K4M',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingIdentity ? null : _handleJoinRoom,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Entra'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
