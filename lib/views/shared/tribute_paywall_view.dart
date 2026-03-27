import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';

class TributePaywallView extends StatefulWidget {
  final String? contextTitle;
  final String? contextMessage;

  const TributePaywallView({super.key, this.contextTitle, this.contextMessage});

  @override
  State<TributePaywallView> createState() => _TributePaywallViewState();
}

class _TributePaywallViewState extends State<TributePaywallView> {
  bool _yearlySelected = true;
  bool _purchaseSuccess = false;

  static const _features = [
    (Icons.all_inclusive_rounded, 'Unlimited habits'),
    (Icons.shield_rounded, 'SOS temptation support'),
    (Icons.bar_chart_rounded, 'Detailed analytics & insights'),
    (Icons.format_quote_rounded, 'Custom purpose statements'),
    (Icons.calendar_month_rounded, '52-week Year in Tribute heatmap'),
    (Icons.notifications_rounded, 'Smart reminders'),
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();

    if (store.isPremium && !_purchaseSuccess) {
      _purchaseSuccess = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) Navigator.pop(context);
        });
      });
    }

    return Scaffold(
      backgroundColor: TributeColor.charcoal,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(children: [
                _headerSection(),
                if (widget.contextTitle != null) ...[
                  const SizedBox(height: 20),
                  _contextSection(),
                ],
                const SizedBox(height: 24),
                _planCards(store),
                const SizedBox(height: 20),
                _featuresSection(),
              ]),
            ),
          ),
          _bottomSection(store),
        ]),
      ),
    );
  }

  Widget _headerSection() {
    return Column(children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            TributeColor.golden.withValues(alpha: 0.2),
            TributeColor.golden.withValues(alpha: 0.04),
          ]),
        ),
        child: const Icon(Icons.workspace_premium_rounded, size: 28, color: TributeColor.golden),
      ),
      const SizedBox(height: 10),
      const Text('Tribute Pro',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: TributeColor.warmWhite)),
      const SizedBox(height: 6),
      Text('Go deeper in your walk with God.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.6))),
    ]);
  }

  Widget _contextSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TributeColor.golden.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TributeColor.golden.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(children: [
        Text(widget.contextTitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TributeColor.golden)),
        if (widget.contextMessage != null) ...[
          const SizedBox(height: 4),
          Text(widget.contextMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
        ],
      ]),
    );
  }

  Widget _planCards(StoreProvider store) {
    final monthly = store.monthlyPackage;
    final annual = store.annualPackage;
    return Row(children: [
      if (monthly != null) ...[
        Expanded(child: _planCard(
          title: 'Monthly',
          price: '\$${monthly.storeProduct.price.toStringAsFixed(2)}',
          subtitle: 'per month',
          selected: !_yearlySelected,
          badge: null,
          onTap: () => setState(() => _yearlySelected = false),
        )),
        const SizedBox(width: 12),
      ],
      if (annual != null)
        Expanded(child: _planCard(
          title: 'Yearly',
          price: '\$${annual.storeProduct.price.toStringAsFixed(2)}',
          subtitle: 'best value',
          selected: _yearlySelected,
          badge: store.monthlySavingsText,
          onTap: () => setState(() => _yearlySelected = true),
        ))
      else if (monthly == null)
        _noPlansFallback(),
    ]);
  }

  Widget _planCard({
    required String title,
    required String price,
    required String subtitle,
    required bool selected,
    required String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        decoration: BoxDecoration(
          color: selected ? TributeColor.golden.withValues(alpha: 0.08) : TributeColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? TributeColor.golden.withValues(alpha: 0.4) : TributeColor.cardBorder,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: TributeColor.golden,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: TributeColor.charcoal)),
            )
          else
            const SizedBox(height: 19),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: selected ? TributeColor.golden : Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(price,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: selected ? TributeColor.warmWhite : Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4))),
        ]),
      ),
    );
  }

  Widget _noPlansFallback() {
    return Expanded(
      child: Center(
        child: Text('Loading plans...',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
      ),
    );
  }

  Widget _featuresSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TributeDecorations.card,
      child: Column(
        children: _features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Icon(f.$1, size: 16, color: TributeColor.golden),
                const SizedBox(width: 12),
                Text(f.$2, style: const TextStyle(fontSize: 14, color: TributeColor.softGold)),
              ]),
            )).toList(),
      ),
    );
  }

  Widget _bottomSection(StoreProvider store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(children: [
        if (_purchaseSuccess)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_rounded, color: TributeColor.sage, size: 18),
            const SizedBox(width: 8),
            const Text('Welcome to Tribute Pro',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: TributeColor.sage)),
          ])
        else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (store.isPurchasing || store.isLoading) ? null : () => _purchase(store),
              style: ElevatedButton.styleFrom(
                backgroundColor: TributeColor.golden,
                foregroundColor: TributeColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: store.isPurchasing
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: TributeColor.charcoal))
                  : const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
              onPressed: store.isLoading ? null : () => store.restore(),
              child: Text('Restore Purchases',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
            ),
            Text('\u00B7', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Not now',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
            ),
          ]),
          if (store.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(store.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: TributeColor.warmCoral)),
            ),
        ],
      ]),
    );
  }

  Future<void> _purchase(StoreProvider store) async {
    final pkg = _yearlySelected ? store.annualPackage : store.monthlyPackage;
    if (pkg != null) await store.purchase(pkg);
  }
}
