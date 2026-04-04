import 'dart:async';

import 'package:flutter/material.dart';

import '../../shifts/presentation/services/payslip_projection_service.dart';

class PayslipPage extends StatefulWidget {
  const PayslipPage({
    super.key,
    this.projection,
    this.projectionResult,
    this.selectedMonth,
    this.month,
    this.precision,
    this.precisionStatus,
    this.onOpenCalibration,
    this.onAddBasketPayment,
    this.activeDepartmentLabel,
    this.onToggleDepartment,
  });

  final PayslipProjectionResult? projection;
  final PayslipProjectionResult? projectionResult;

  final DateTime? selectedMonth;
  final DateTime? month;

  final PrecisionStatus? precision;
  final PrecisionStatus? precisionStatus;

  final VoidCallback? onOpenCalibration;
  final String? activeDepartmentLabel;
  final VoidCallback? onToggleDepartment;

  /// Firma prevista:
  /// onAddBasketPayment(DateTime paymentMonth, double hoursPaid, String note)
  final FutureOr<void> Function(
    DateTime paymentMonth,
    double hoursPaid,
    String note,
  )? onAddBasketPayment;

  @override
  State<PayslipPage> createState() => _PayslipPageState();
}

class _PayslipPageState extends State<PayslipPage> {
  bool _detailsExpanded = false;
  bool _infoExpanded = false;
  bool _advancedAccessoriesExpanded = false;

  PayslipProjectionResult? get _projection =>
      widget.projection ?? widget.projectionResult;

  PrecisionStatus? get _precision =>
      widget.precision ?? widget.precisionStatus;

  DateTime get _pageMonth =>
      widget.selectedMonth ?? widget.month ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final projection = _projection;
    final precision = _precision;

    if (projection == null) {
      return _DutyPayScaffold(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF22C55E),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.upload_file,
                        color: Color(0xFF22C55E),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Carica i cedolini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Per avere una stima precisa devi caricare almeno 2 cedolini.\n\nTocca l’icona in alto a destra per iniziare.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: widget.onOpenCalibration,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Carica cedolini'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            _PageTitle(
              title: 'Cedolino',
              subtitle: 'Stima chiara, semplice e affidabile del tuo mese.',
            ),
            const SizedBox(height: 18),
            _EmptyStateCard(
              title: 'Nessuna stima disponibile',
              subtitle:
                  'Carica i cedolini per calibrare l’app e ottenere una proiezione realistica del netto.',
              primaryActionLabel: 'Carica i 3 cedolini',
              onPrimaryAction: widget.onOpenCalibration,
            ),
          ],
        ),
      );
    }

    final monthLabel = _monthYearLabel(_pageMonth);
    final activeDepartmentLabel = widget.activeDepartmentLabel;
    final estimatedNet = _readEstimatedNet(projection);
    final baseNet = _readBaseNet(projection);
    final netAccessories = _readNetAccessories(projection);
    final extraNetBuilt = _readExtraNetBuilt(projection);
    final extraGross = _readExtraGross(projection);
    final extraTaxes = _readExtraTaxes(projection);
    final recurringDeductions = _readRecurringDeductions(projection);
    final difference = _readDifference(projection);

    final basketHours = _readBasketResidualHours(projection);
    final basketGross = _readBasketResidualGross(projection);
    final basketRecoveredHours = _readBasketRecoveredHours(projection);
    final basketRecoveredGross = _readBasketRecoveredGross(projection);
    final basketPaidThisMonthHours =
        _readManualBasketPaidHoursForMonth(projection);
    final basketPaidThisMonthGross =
        _readManualBasketPaidGrossForMonth(projection);
    final basketOvertimeResidualGross =
        _readBasketOvertimeResidualGross(projection);
    final basketAllowanceResidualGross =
        _readBasketAllowanceResidualGross(projection);

    final accessoriesReferenceMonth =
        _readAccessoriesReferenceMonth(projection) ?? _pageMonth;
    final usingHistoricalAverage = _readUsingHistoricalAverage(projection);
    final v2MonthlyAllowancesGross = projection.v2MonthlyAllowancesGross;
    final v2BasketAllowancesGross = projection.v2BasketAllowancesGross;
    final historicalReferenceText = usingHistoricalAverage
        ? 'Media storica utilizzata perché nel mese di riferimento ci sono pochi turni.'
        : 'Valori basati sul mese di riferimento delle accessorie.';

    final referenceShiftCount = projection.referenceMonthShiftCount;
    final accessoriesGrossLiquidated = projection.accessoriesGrossLiquidated;
    final accessoriesGrossUsed = projection.accessoriesGrossUsedForEstimate;

    return _DutyPayScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
        children: [
          _PageTitle(
            title: 'Cedolino',
            subtitle: 'Tutto quello che ti serve, senza confusione.',
          ),
          const SizedBox(height: 18),
          if (activeDepartmentLabel != null &&
              activeDepartmentLabel.trim().isNotEmpty) ...[
            GestureDetector(
              onTap: widget.onToggleDepartment,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF18212C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF253140),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      color: Color(0xFF67B7FF),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Reparto attivo:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activeDepartmentLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          _CalibrationExplainerCard(
            onOpenCalibration: widget.onOpenCalibration,
            isCalibrated: true,
          ),
          const SizedBox(height: 16),
          const _CedolinoDisclaimerCard(),
          const SizedBox(height: 16),
          _HeroNetCard(
            monthLabel: monthLabel,
            netValue: estimatedNet,
            precision: precision,
          ),
          const SizedBox(height: 16),
          _PrimarySummaryCard(
            title: 'Quanto stai costruendo',
            subtitle:
                'La base resta stabile, gli extra crescono con i turni inseriti.',
            rows: [
              _SummaryRowData(
                label: 'Base netta stimata',
                value: _currency(baseNet),
              ),
              _SummaryRowData(
                label: 'Extra netti costruiti',
                value: _currency(extraNetBuilt),
                tone: _RowTone.positive,
              ),
              _SummaryRowData(
                label: 'Trattenute ricorrenti',
                value: '- ${_currency(recurringDeductions)}',
                tone: _RowTone.negative,
              ),
            ],
            footerLabel: 'Totale progressivo',
            footerValue:
                _currency(baseNet + extraNetBuilt - recurringDeductions),
          ),
          const SizedBox(height: 16),
          _BasketCard(
            residualHours: basketHours,
            residualGross: basketGross,
            recoveredHours: basketRecoveredHours,
            recoveredGross: basketRecoveredGross,
            paidThisMonthHours: basketPaidThisMonthHours,
            paidThisMonthGross: basketPaidThisMonthGross,
            overtimeResidualGross: basketOvertimeResidualGross,
            allowanceResidualGross: basketAllowanceResidualGross,
            isAllowanceMode: basketHours == 0 && basketGross > 0,
            onAddPayment: widget.onAddBasketPayment == null || basketHours <= 0
                ? null
                : () => _openBasketDialog(
                      residualHours: basketHours,
                      month: _pageMonth,
                    ),
          ),
          const SizedBox(height: 16),
          _PremiumCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Da dove arriva questa stima',
                  subtitle:
                      'Numeri ordinati e leggibili, senza tecnicismi inutili.',
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        _detailsExpanded = !_detailsExpanded;
                      });
                    },
                    icon: Icon(
                      _detailsExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _DutyPayColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _BreakdownLine(
                  label: 'Base netta',
                  value: _currency(baseNet),
                ),
                const SizedBox(height: 10),
                _BreakdownLine(
                  label: 'Accessorie nette stimate',
                  value: _currency(netAccessories),
                  valueColor: _DutyPayColors.info,
                ),
                const SizedBox(height: 10),
                _BreakdownLine(
                  label: 'Trattenute ricorrenti',
                  value: '- ${_currency(recurringDeductions)}',
                  valueColor: _DutyPayColors.danger,
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: _DutyPayColors.divider),
                const SizedBox(height: 14),
                _BreakdownLine(
                  label: 'Totale finale stimato',
                  value: _currency(estimatedNet),
                  isLarge: true,
                  valueColor: Colors.white,
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        const Divider(
                          height: 1,
                          color: _DutyPayColors.divider,
                        ),
                        const SizedBox(height: 16),
                        _BreakdownLine(
                          label: 'Extra lordi inseriti',
                          value: _currency(extraGross),
                        ),
                        const SizedBox(height: 10),
                        _BreakdownLine(
                          label: 'Tasse stimate sugli extra',
                          value: '- ${_currency(extraTaxes)}',
                          valueColor: _DutyPayColors.warning,
                        ),
                        const SizedBox(height: 10),
                        _BreakdownLine(
                          label: 'Extra netti',
                          value: _currency(extraNetBuilt),
                          valueColor: _DutyPayColors.positive,
                        ),
                        const SizedBox(height: 10),
                        _BreakdownLine(
                          label: 'Differenza rispetto al cedolino stimato',
                          value: _signedCurrency(difference),
                          valueColor: difference >= 0
                              ? _DutyPayColors.positive
                              : _DutyPayColors.danger,
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _detailsExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PremiumCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Accessorie e ritardo di pagamento',
                  subtitle:
                      'Ti mostriamo il mese giusto su cui stai realmente maturando.',
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        _infoExpanded = !_infoExpanded;
                      });
                    },
                    icon: Icon(
                      _infoExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _DutyPayColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _InfoPill(
                  icon: Icons.schedule_rounded,
                  label: 'Mese accessorie considerato',
                  value: _monthYearLabel(accessoriesReferenceMonth),
                ),
                const SizedBox(height: 10),
                _InfoPill(
                  icon: Icons.analytics_outlined,
                  label: 'Metodo usato',
                  value: usingHistoricalAverage
                      ? 'Media storica'
                      : 'Mese di riferimento',
                ),
                const SizedBox(height: 10),
                _InfoPill(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Accessorie nette stimate',
                  value: _currency(netAccessories),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () {
                    setState(() {
                      _advancedAccessoriesExpanded =
                          !_advancedAccessoriesExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: _DutyPayColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _DutyPayColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: _DutyPayColors.info,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Dettagli avanzati',
                            style: TextStyle(
                              color: _DutyPayColors.textPrimary,
                              fontSize: 13.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          _advancedAccessoriesExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: _DutyPayColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        _InfoPill(
                          icon: Icons.calendar_view_month_rounded,
                          label: 'Turni nel mese di riferimento',
                          value: '$referenceShiftCount',
                        ),
                        const SizedBox(height: 10),
                        _InfoPill(
                          icon: Icons.payments_outlined,
                          label: 'Accessorie lorde liquidate',
                          value: _currency(accessoriesGrossLiquidated),
                        ),
                        const SizedBox(height: 10),
                        _InfoPill(
                          icon: Icons.calculate_outlined,
                          label: 'Accessorie lorde usate',
                          value: _currency(accessoriesGrossUsed),
                        ),
                        const SizedBox(height: 10),
                        _InfoPill(
                          icon: Icons.add_chart_rounded,
                          label: 'Indennità V2 mese',
                          value: _currency(v2MonthlyAllowancesGross),
                        ),
                        const SizedBox(height: 10),
                        _InfoPill(
                          icon: Icons.inventory_2_outlined,
                          label: 'Indennità V2 basket',
                          value: _currency(v2BasketAllowancesGross),
                        ),
                        const SizedBox(height: 10),
                        _InfoPill(
                          icon: Icons.layers_outlined,
                          label: 'Accessorie NON straordinario',
                          value: _currency(projection.nonOvertimeGross),
                        ),
                        const SizedBox(height: 10),
                        _InfoPill(
                          icon: Icons.flash_on_outlined,
                          label: 'Straordinari lordi',
                          value: _currency(
                            projection.overtimeGrossFromReferenceMonth,
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _advancedAccessoriesExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      historicalReferenceText,
                      style: const TextStyle(
                        color: _DutyPayColors.textSecondary,
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  crossFadeState: _infoExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (precision != null)
            _PrecisionCard(
              precision: precision,
            ),
          const SizedBox(height: 18),
          _MinimalActionRow(
            onOpenCalibration: widget.onOpenCalibration,
          ),
        ],
      ),
    );
  }

  Future<void> _openBasketDialog({
    required double residualHours,
    required DateTime month,
  }) async {
    final hoursController = TextEditingController();
    final noteController = TextEditingController();

    String? errorText;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final raw = hoursController.text.trim().replaceAll(',', '.');
              final parsed = double.tryParse(raw);

              if (parsed == null || parsed <= 0) {
                setDialogState(() {
                  errorText = 'Inserisci un numero di ore valido.';
                });
                return;
              }

              if (parsed > residualHours) {
                setDialogState(() {
                  errorText =
                      'Non puoi registrare più di ${_formatHours(residualHours)} disponibili.';
                });
                return;
              }

              final callback = widget.onAddBasketPayment;
              if (callback == null) return;

              setDialogState(() {
                saving = true;
                errorText = null;
              });

              try {
                await callback(
                  month,
                  parsed,
                  noteController.text.trim(),
                );

                if (mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Pagamento basket registrato correttamente.'),
                    ),
                  );
                }
              } catch (e) {
                setDialogState(() {
                  saving = false;
                  errorText = 'Impossibile salvare il pagamento.';
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _DutyPayColors.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _DutyPayColors.cardBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registra pagamento basket',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ore disponibili da scaricare: ${_formatHours(residualHours)}',
                      style: const TextStyle(
                        color: _DutyPayColors.textSecondary,
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DialogTextField(
                      controller: hoursController,
                      label: 'Ore pagate',
                      hintText: 'Es. 12 oppure 7.5',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DialogTextField(
                      controller: noteController,
                      label: 'Nota (facoltativa)',
                      hintText: 'Es. pagamento tranche straordinari',
                      maxLines: 2,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _DutyPayColors.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _DutyPayColors.danger.withOpacity(0.28),
                          ),
                        ),
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            color: _DutyPayColors.danger,
                            fontSize: 13.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _GhostButton(
                            label: 'Annulla',
                            onPressed: saving
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PrimaryButton(
                            label: saving ? 'Salvataggio...' : 'Conferma',
                            icon: Icons.check_rounded,
                            onPressed: saving ? null : submit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _readEstimatedNet(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.estimatedPayslipTotal,
        () => p.totalFinalNetEstimate,
        () => p.estimatedNetTotal,
        () => p.finalNetEstimate,
        () => p.netTotalEstimate,
      ],
      fallback: 0,
    );
  }

  double _readBaseNet(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.fixedBaseNetEstimated,
        () => p.baseNetSalaryEstimate,
        () => p.baseNetEstimate,
        () => p.estimatedBaseNet,
        () => p.baseNet,
      ],
      fallback: 0,
    );
  }

  double _readNetAccessories(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.accessoriesNetEstimated,
        () => p.accessoryNetEstimate,
        () => p.netAccessoryEstimate,
        () => p.accessoriesNetEstimate,
        () => p.referenceMonthAccessoryNet,
      ],
      fallback: 0,
    );
  }

  double _readExtraNetBuilt(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.accessoriesNetEstimated,
        () => p.extraNetBuilt,
        () => p.netExtrasBuilt,
        () => p.shiftExtraNet,
        () => p.extraNetEstimate,
      ],
      fallback: (_readExtraGross(projection) - _readExtraTaxes(projection))
          .clamp(0, double.infinity),
    );
  }

  double _readExtraGross(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.accessoriesGrossUsedForEstimate,
        () => p.accessoriesGrossLiquidated,
        () => p.extraGrossBuilt,
        () => p.shiftExtraGross,
        () => p.totalAccessoriesGross,
        () => p.accessoryGrossEstimate,
      ],
      fallback: 0,
    );
  }

  double _readExtraTaxes(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.taxes,
        () => p.extraTaxesEstimate,
        () => p.estimatedExtraTaxes,
        () => p.accessoryTaxEstimate,
        () => p.extraTaxAmount,
      ],
      fallback: 0,
    );
  }

  double _readRecurringDeductions(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.recurringDeductionsApplied,
        () => p.recurringDeductionsTotal,
        () => p.recurringDeductionAmount,
      ],
      fallback: 0,
    );
  }

  double _readDifference(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.differenceFromEstimatedPayslip,
        () => p.estimatedDifference,
        () => p.deltaVsEstimatedPayslip,
      ],
      fallback: 0,
    );
  }

  double _readBasketResidualHours(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.currentBasketResidualHours,
        () => p.overtimeInBasketHours,
      ],
      fallback: 0,
    );
  }

  double _readBasketResidualGross(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.currentBasketResidualGrossEstimate,
        () => p.overtimeInBasketGross,
      ],
      fallback: 0,
    );
  }

  double _readBasketOvertimeResidualGross(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.basketOvertimeResidualGrossEstimate,
        () => p.overtimeInBasketGross,
      ],
      fallback: 0,
    );
  }

  double _readBasketAllowanceResidualGross(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.basketAllowanceResidualGross,
      ],
      fallback: 0,
    );
  }

  double _readBasketRecoveredHours(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.basketRecoveredHours,
      ],
      fallback: 0,
    );
  }

  double _readBasketRecoveredGross(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.basketRecoveredGross,
      ],
      fallback: 0,
    );
  }

  double _readManualBasketPaidHoursForMonth(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.manualBasketPaidHoursForMonth,
      ],
      fallback: 0,
    );
  }

  double _readManualBasketPaidGrossForMonth(PayslipProjectionResult projection) {
    final dynamic p = projection;
    return _readFirstDouble(
      [
        () => p.manualBasketPaidGrossForMonth,
      ],
      fallback: 0,
    );
  }

  DateTime? _readAccessoriesReferenceMonth(PayslipProjectionResult projection) {
    final dynamic p = projection;
    try {
      final value = p.accessoriesReferenceMonth;
      if (value is DateTime) return value;
    } catch (_) {}
    try {
      final value = p.referenceAccessoryMonth;
      if (value is DateTime) return value;
    } catch (_) {}
    try {
      final value = p.referenceMonth;
      if (value is DateTime) return value;
    } catch (_) {}
    return null;
  }

  bool _readUsingHistoricalAverage(PayslipProjectionResult projection) {
    final dynamic p = projection;
    try {
      final value = p.usedHistoricalAverage;
      if (value is bool) return value;
    } catch (_) {}
    try {
      final value = p.usingHistoricalAverage;
      if (value is bool) return value;
    } catch (_) {}
    return false;
  }

  double _readFirstDouble(
    List<double Function()> readers, {
    required double fallback,
  }) {
    for (final reader in readers) {
      try {
        final value = reader();
        return value;
      } catch (_) {}
    }
    return fallback;
  }

  static String _monthYearLabel(DateTime date) {
    const months = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String _currency(double value) {
    final isNegative = value < 0;
    final abs = value.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final integer = parts[0];
    final decimal = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < integer.length; i++) {
      final reverseIndex = integer.length - i;
      buffer.write(integer[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    final formatted = '${buffer.toString()},$decimal €';
    return isNegative ? '- $formatted' : formatted;
  }

  static String _signedCurrency(double value) {
    if (value > 0) return '+ ${_currency(value)}';
    if (value < 0) return '- ${_currency(value.abs())}';
    return _currency(0);
  }

  static String _formatHours(double value) {
    return '${value.toStringAsFixed(1)}h';
  }
}

class _DutyPayScaffold extends StatelessWidget {
  const _DutyPayScaffold({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _DutyPayColors.background,
            _DutyPayColors.backgroundSoft,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: child,
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: _DutyPayColors.textSecondary,
              fontSize: 14.2,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroNetCard extends StatelessWidget {
  const _HeroNetCard({
    required this.monthLabel,
    required this.netValue,
    required this.precision,
  });

  final String monthLabel;
  final double netValue;
  final PrecisionStatus? precision;

  @override
  Widget build(BuildContext context) {
    final precisionData = _precisionVisuals(precision);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A2030),
            Color(0xFF111723),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF2B364C),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: _DutyPayColors.info,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                    color: _DutyPayColors.textSecondary,
                    fontSize: 13.4,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
              if (precision != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: precisionData.background,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: precisionData.border,
                    ),
                  ),
                  child: Text(
                    '${precisionData.label} · ${precision!.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: precisionData.text,
                      fontSize: 11.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _PayslipPageState._currency(netValue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stima cedolino',
            style: TextStyle(
              color: _DutyPayColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _DutyPayColors.textSecondary,
                  size: 16,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Numero principale in evidenza, dettagli ordinati sotto.',
                    style: TextStyle(
                      color: _DutyPayColors.textSecondary,
                      fontSize: 12.8,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _PrecisionVisualData _precisionVisuals(PrecisionStatus? precision) {
    if (precision == null) {
      return const _PrecisionVisualData(
        label: 'N/D',
        background: Color(0x141FA4FF),
        border: Color(0x331FA4FF),
        text: Color(0xFF8FC8FF),
      );
    }

    switch (precision.level) {
      case PrecisionLevel.high:
        return const _PrecisionVisualData(
          label: 'Alta',
          background: Color(0x1622C55E),
          border: Color(0x3322C55E),
          text: Color(0xFF7AE6A1),
        );
      case PrecisionLevel.medium:
        return const _PrecisionVisualData(
          label: 'Media',
          background: Color(0x16F59E0B),
          border: Color(0x33F59E0B),
          text: Color(0xFFFFC857),
        );
      case PrecisionLevel.low:
        return const _PrecisionVisualData(
          label: 'Bassa',
          background: Color(0x16EF4444),
          border: Color(0x33EF4444),
          text: Color(0xFFFF8A8A),
        );
    }
  }
}

class _PrimarySummaryCard extends StatelessWidget {
  const _PrimarySummaryCard({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.footerLabel,
    required this.footerValue,
  });

  final String title;
  final String subtitle;
  final List<_SummaryRowData> rows;
  final String footerLabel;
  final String footerValue;

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 14),
          ...rows.expand(
            (row) => [
              _SummaryRow(row: row),
              const SizedBox(height: 10),
            ],
          ),
          const SizedBox(height: 2),
          const Divider(height: 1, color: _DutyPayColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  footerLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                footerValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BasketCard extends StatelessWidget {
  const _BasketCard({
    required this.residualHours,
    required this.residualGross,
    required this.recoveredHours,
    required this.recoveredGross,
    required this.paidThisMonthHours,
    required this.paidThisMonthGross,
    required this.overtimeResidualGross,
    required this.allowanceResidualGross,
    required this.isAllowanceMode,
    required this.onAddPayment,
  });

  final double residualHours;
  final double residualGross;
  final double recoveredHours;
  final double recoveredGross;
  final double paidThisMonthHours;
  final double paidThisMonthGross;
  final double overtimeResidualGross;
  final double allowanceResidualGross;
  final bool isAllowanceMode;
  final VoidCallback? onAddPayment;

  @override
  Widget build(BuildContext context) {
    final bool hasResidualHours = residualHours > 0;
    final bool hasAllowanceOnly =
        residualHours <= 0 && allowanceResidualGross > 0;
    final bool hasAnyResidual = residualGross > 0 || residualHours > 0;

    final String title = hasAllowanceOnly
        ? 'Basket indennità'
        : 'Basket straordinario';

    final String subtitle = hasAllowanceOnly
        ? 'Qui vedi importi maturati da indennità reparto inviati nel basket.'
        : 'Una delle funzioni più utili per il Reparto Mobile.';

    final String actionLabel = hasResidualHours
        ? 'Registra pagamento basket'
        : hasAllowanceOnly
            ? 'Importi da indennità presenti'
            : 'Nessuna disponibilità';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasAnyResidual
              ? const [
                  Color(0xFF1B1A14),
                  Color(0xFF12110E),
                ]
              : const [
                  Color(0xFF15181E),
                  Color(0xFF101318),
                ],
        ),
        border: Border.all(
          color: hasAnyResidual
              ? const Color(0xFF4A3B15)
              : const Color(0xFF273142),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasAnyResidual
                      ? const Color(0x1AF59E0B)
                      : const Color(0x143B82F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasAllowanceOnly
                      ? Icons.account_balance_wallet_outlined
                      : Icons.inventory_2_outlined,
                  color: hasAnyResidual
                      ? _DutyPayColors.warning
                      : _DutyPayColors.info,
                ),
              ),
              const SizedBox(width: 12),
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _DutyPayColors.textSecondary,
                        fontSize: 13.2,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: 'Residuo ore',
                  value: _PayslipPageState._formatHours(residualHours),
                  tone: hasResidualHours
                      ? _MetricTone.warning
                      : _MetricTone.neutral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBlock(
                  label: 'Residuo lordo',
                  value: _PayslipPageState._currency(residualGross),
                  tone: hasAnyResidual
                      ? _MetricTone.warning
                      : _MetricTone.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: 'Ore recuperate',
                  value: _PayslipPageState._formatHours(recoveredHours),
                  tone: _MetricTone.positive,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBlock(
                  label: 'Lordo recuperato',
                  value: _PayslipPageState._currency(recoveredGross),
                  tone: _MetricTone.positive,
                ),
              ),
            ],
          ),
          if (!isAllowanceMode) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricBlock(
                    label: 'Pagato questo mese',
                    value: _PayslipPageState._formatHours(paidThisMonthHours),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricBlock(
                    label: 'Valore questo mese',
                    value: _PayslipPageState._currency(paidThisMonthGross),
                  ),
                ),
              ],
            ),
          ],
          if (allowanceResidualGross > 0) ...[
            const SizedBox(height: 12),
            _MetricBlock(
              label: 'Quota indennità nel basket',
              value: _PayslipPageState._currency(allowanceResidualGross),
              tone: _MetricTone.warning,
            ),
          ],
          const SizedBox(height: 18),
          _PrimaryButton(
            label: actionLabel,
            icon: hasResidualHours
                ? Icons.add_task_rounded
                : hasAllowanceOnly
                    ? Icons.info_outline_rounded
                    : Icons.lock_outline_rounded,
            onPressed: hasResidualHours ? onAddPayment : null,
          ),
        ],
      ),
    );
  }
}

class _PrecisionCard extends StatelessWidget {
  const _PrecisionCard({
    required this.precision,
  });

  final PrecisionStatus precision;

  @override
  Widget build(BuildContext context) {
    late final Color accent;
    late final Color soft;
    late final String label;
    late final String description;

    switch (precision.level) {
      case PrecisionLevel.high:
        accent = _DutyPayColors.positive;
        soft = _DutyPayColors.positive.withOpacity(0.12);
        label = 'Precisione alta';
        description =
            'Hai caricato abbastanza dati da rendere la stima molto affidabile.';
        break;
      case PrecisionLevel.medium:
        accent = _DutyPayColors.warning;
        soft = _DutyPayColors.warning.withOpacity(0.12);
        label = 'Precisione media';
        description =
            'La stima è buona, ma può migliorare aggiungendo più dati e cedolini.';
        break;
      case PrecisionLevel.low:
        accent = _DutyPayColors.danger;
        soft = _DutyPayColors.danger.withOpacity(0.12);
        label = 'Precisione bassa';
        description =
            'La stima è ancora utile, ma serve più storico per essere davvero solida.';
        break;
    }

    return _PremiumCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '${precision.percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: _DutyPayColors.textSecondary,
                    fontSize: 13.4,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
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

class _MinimalActionRow extends StatelessWidget {
  const _MinimalActionRow({
    required this.onOpenCalibration,
  });

  final VoidCallback? onOpenCalibration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GhostButton(
            label: 'Ricalibra con i cedolini',
            icon: Icons.upload_file_rounded,
            onPressed: onOpenCalibration,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _DutyPayColors.textSecondary,
                  fontSize: 13.2,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.row,
  });

  final _SummaryRowData row;

  @override
  Widget build(BuildContext context) {
    Color valueColor = Colors.white;
    if (row.tone == _RowTone.positive) valueColor = _DutyPayColors.positive;
    if (row.tone == _RowTone.negative) valueColor = _DutyPayColors.danger;
    if (row.tone == _RowTone.warning) valueColor = _DutyPayColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: _DutyPayColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _DutyPayColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: const TextStyle(
                color: _DutyPayColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            row.value,
            style: TextStyle(
              color: valueColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLarge = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isLarge ? Colors.white : _DutyPayColors.textSecondary,
              fontSize: isLarge ? 15.2 : 14,
              fontWeight: isLarge ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: isLarge ? 20 : 15,
            fontWeight: isLarge ? FontWeight.w900 : FontWeight.w800,
            letterSpacing: isLarge ? -0.4 : 0,
          ),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    this.tone = _MetricTone.neutral,
  });

  final String label;
  final String value;
  final _MetricTone tone;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color border;
    late final Color valueColor;

    switch (tone) {
      case _MetricTone.warning:
        background = _DutyPayColors.warning.withOpacity(0.10);
        border = _DutyPayColors.warning.withOpacity(0.18);
        valueColor = _DutyPayColors.warning;
        break;
      case _MetricTone.positive:
        background = _DutyPayColors.positive.withOpacity(0.10);
        border = _DutyPayColors.positive.withOpacity(0.18);
        valueColor = _DutyPayColors.positive;
        break;
      case _MetricTone.neutral:
        background = _DutyPayColors.surface;
        border = _DutyPayColors.cardBorder;
        valueColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _DutyPayColors.textSecondary,
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: _DutyPayColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DutyPayColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: _DutyPayColors.info,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _DutyPayColors.textPrimary,
                fontSize: 13.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DutyPayColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _DutyPayColors.cardBorder,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              enabled ? _DutyPayColors.primary : _DutyPayColors.surface,
          foregroundColor:
              enabled ? Colors.black : _DutyPayColors.textSecondary,
          disabledBackgroundColor: _DutyPayColors.surface,
          disabledForegroundColor: _DutyPayColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              enabled ? Colors.white : _DutyPayColors.textSecondary,
          side: BorderSide(
            color: enabled ? _DutyPayColors.cardBorder : _DutyPayColors.divider,
          ),
          backgroundColor: _DutyPayColors.surface.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(
          color: _DutyPayColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: _DutyPayColors.textHint,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _DutyPayColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: _DutyPayColors.cardBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: _DutyPayColors.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
  });

  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _DutyPayColors.info.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: _DutyPayColors.info,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _DutyPayColors.textSecondary,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          _PrimaryButton(
            label: primaryActionLabel,
            icon: Icons.upload_file_rounded,
            onPressed: onPrimaryAction,
          ),
        ],
      ),
    );
  }
}

class _CalibrationExplainerCard extends StatelessWidget {
  const _CalibrationExplainerCard({
    required this.onOpenCalibration,
    required this.isCalibrated,
  });

  final VoidCallback? onOpenCalibration;
  final bool isCalibrated;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF103126),
            Color(0xFF121922),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF22C55E),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x1A22C55E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCalibrated
                      ? 'Calibrazione cedolini disponibile'
                      : 'Prima calibra i cedolini',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isCalibrated
                ? 'Puoi ricaricare i cedolini in qualsiasi momento per aggiornare i valori reali di straordinario, notturno, festivo e indennità operative.'
                : 'Per rendere affidabile questa pagina devi caricare almeno 2 o 3 cedolini recenti. DutyPay leggerà i valori reali e li userà per stimare il tuo mese in modo molto più preciso.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.6,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PrimaryButton(
                  label: isCalibrated
                      ? 'Apri / aggiorna calibrazione'
                      : 'Carica i cedolini',
                  icon: Icons.upload_file_rounded,
                  onPressed: onOpenCalibration,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CedolinoDisclaimerCard extends StatelessWidget {
  const _CedolinoDisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _DutyPayColors.info.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: _DutyPayColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Come leggere questa pagina',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Questa schermata mostra una proiezione del cedolino mensile costruita sui turni inseriti e sui cedolini caricati. Le cifre mostrate sono stime operative basate sui dati disponibili e diventano più affidabili dopo la calibrazione. La pagina aiuta a pianificare il mese, ma non sostituisce il cedolino ufficiale NoiPA.',
                  style: TextStyle(
                    color: _DutyPayColors.textSecondary,
                    fontSize: 13.2,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
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

class _DutyPayColors {
  static const background = Color(0xFF0B0F14);
  static const backgroundSoft = Color(0xFF11161E);

  static const card = Color(0xFF121922);
  static const surface = Color(0xFF18212C);

  static const cardBorder = Color(0xFF253140);
  static const divider = Color(0xFF24303E);

  static const textPrimary = Color(0xFFF2F6FA);
  static const textSecondary = Color(0xFF9AA8B7);
  static const textHint = Color(0xFF708092);

  static const primary = Color(0xFF5CE1A8);
  static const positive = Color(0xFF56D88D);
  static const info = Color(0xFF67B7FF);
  static const warning = Color(0xFFFFC14D);
  static const danger = Color(0xFFFF6B6B);
}

class _SummaryRowData {
  const _SummaryRowData({
    required this.label,
    required this.value,
    this.tone = _RowTone.neutral,
  });

  final String label;
  final String value;
  final _RowTone tone;
}

enum _RowTone {
  neutral,
  positive,
  negative,
  warning,
}

enum _MetricTone {
  neutral,
  positive,
  warning,
}

class _PrecisionVisualData {
  const _PrecisionVisualData({
    required this.label,
    required this.background,
    required this.border,
    required this.text,
  });

  final String label;
  final Color background;
  final Color border;
  final Color text;
}