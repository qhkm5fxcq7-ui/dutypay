import 'package:flutter/material.dart';

class ImportZuppometroPage extends StatefulWidget {
  final Function(double avg, double hours, int months) onSave;

  const ImportZuppometroPage({super.key, required this.onSave});

  @override
  State<ImportZuppometroPage> createState() => _ImportZuppometroPageState();
}

class _ImportZuppometroPageState extends State<ImportZuppometroPage> {
  final _avgController = TextEditingController();
  final _hoursController = TextEditingController();
  final _monthsController = TextEditingController();

  @override
  void dispose() {
    _avgController.dispose();
    _hoursController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  void _save() {
    final avg = double.tryParse(_avgController.text) ?? 0;
    final hours = double.tryParse(_hoursController.text) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;

    widget.onSave(avg, hours, months);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importa dati')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Conosci i tuoi dati dei mesi precedenti?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'IInseriscili per ottenere subito una stima più precisa.',
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _avgController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Extra mensili medi (netto)',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ore straordinario medie',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _monthsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mesi considerati',
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Salva e continua'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}