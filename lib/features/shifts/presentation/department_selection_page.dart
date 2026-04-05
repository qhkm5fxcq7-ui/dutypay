import 'package:flutter/material.dart';

import 'models/department.dart';

class DepartmentSelectionPage extends StatelessWidget {
  const DepartmentSelectionPage({
    super.key,
    this.initialDepartment,
    required this.onSelected,
  });

  final Department? initialDepartment;
  final Future<void> Function(Department department) onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleziona reparto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ogni reparto segue regole, indennità e logiche diverse.',
                    style: TextStyle(
                      color: Color(0xFF9AA8B7),
                      fontSize: 14.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _DepartmentCard(
                    title: Department.repartoMobile.label,
                    subtitle:
                        'Straordinario, basket ore e logica Reparto Mobile.',
                    selected: initialDepartment == Department.repartoMobile,
                    onTap: () async {
                      await onSelected(Department.repartoMobile);
                    },
                  ),
                  const SizedBox(height: 14),
                  _DepartmentCard(
                    title: Department.polfer.label,
                    subtitle:
                        'Presenza esterna, scalo ferroviario e logica POLFER.',
                    selected: initialDepartment == Department.polfer,
                    onTap: () async {
                      await onSelected(Department.polfer);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF121922),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? const Color(0xFF5CE1A8)
                : const Color(0xFF253140),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0x1A5CE1A8)
                    : const Color(0x1418212C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: selected
                    ? const Color(0xFF5CE1A8)
                    : const Color(0xFF67B7FF),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9AA8B7),
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF9AA8B7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}