import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';

class PaywallScreen extends StatefulWidget {
  final VoidCallback onNext;
  const PaywallScreen({super.key, required this.onNext});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _yearlySelected = true;
  bool _showContent = false;
  bool _showFeatures = false;

  static const _freeFeatures = [
    (Icons.volunteer_activism, 'Daily Gratitude'),
    (Icons.add_circle_outline, '2 Custom Habits'),
    (Icons.calendar_today, 'Weekly View'),
    (Icons.menu_book, 'Anchor Verses'),
  ];

  static const _proFeatures = [
    (Icons.all_inclusive_rounded, 'Unlimited Habits'),
    (Icons.format_quote_rounded, 'Custom Purpose Statements'),
    (Icons.bar_chart_rounded, 'Detailed Stats & Insights'),
    (Icons.notifications_rounded, 'Smart Reminders'),
    (Icons.shield_rounded, 'SOS Temptation Support'),
    (Icons.auto_awesome, '52-Week Year in Tribute'),
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showContent = true);
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showFeatures = true);
    });
  }

  Future<void> _purchase(StoreProvider store) async {
    final pkg = _yearlySelected ? store.annualPackage : store.monthlyPackage;
    if (pkg != null) {
      await store.purchase(pkg);
      if (store.isPremium && mounted) widget.onNext();
    } else {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(children: [
            AnimatedOpacity(
              opacity: _showContent ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Column(children: [
                const Text(
                  'Go deeper with\nTribute Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: TributeColor.warmWhite, height: 1.3),
                ),
                const SizedBox(height: 10),
                Text(
                  'Everything you need to build lasting habits rooted in faith.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            AnimatedOpacity(
              opacity: _showFeatures ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedSlide(
                offset: _showFeatures ? Offset.zero : const Offset(0, 0.15),
                duration: const Duration(milliseconds: 500),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _featureColumn(label: 'FREE', isGold: false, features: _freeFeatures)),
                  const SizedBox(width: 12),
                  Expanded(child: _featureColumn(label: 'PRO', isGold: true, features: _proFeatures)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedOpacity(
              opacity: _showFeatures ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: _planSelector(store),
            ),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: store.isPurchasing ? null : () => _purchase(store),
              icon: store.isPurchasing
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: TributeColor.charcoal))
                  : const Icon(Icons.workspace_premium_rounded, size: 18),
              label: Text(_yearlySelected ? 'Start Free Trial' : 'Subscribe',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: TributeColor.golden,
                foregroundColor: TributeColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
              onPressed: store.isLoading ? null : () => store.restore(),
              child: Text('Restore',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: widget.onNext,
              child: Text('Continue with Free',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
            ),
          ]),
        ]),
      ),
    ]);
  }

  Widget _featureColumn({
    required String label,
    required bool isGold,
    required List<(IconData, String)> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGold ? TributeColor.golden.withValues(alpha: 0.06) : TributeColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGold ? TributeColor.golden.withValues(alpha: 0.2) : TributeColor.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                color: isGold ? TributeColor.golden : Colors.white.withValues(alpha: 0.5),
              )),
          if (isGold) ...[
            const SizedBox(width: 6),
            const Icon(Icons.workspace_premium_rounded, size: 10, color: TributeColor.golden),
          ],
        ]),
        const SizedBox(height: 14),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            SizedBox(
              width: 18,
              child: Icon(f.$1, size: 13,
                  color: isGold ? TributeColor.golden : TributeColor.softGold.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(f.$2,
                  style: TextStyle(
                    fontSize: 12,
                    color: isGold ? TributeColor.warmWhite : Colors.white.withValues(alpha: 0.5),
                  )),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _planSelector(StoreProvider store) {
    return Row(children: [
      if (store.monthlyPackage != null) ...[
        Expanded(child: _planOption(
          title: 'Monthly',
          price: '\$${store.monthlyPackage!.storeProduct.price.toStringAsFixed(2)}',
          detail: 'per month',
          isSelected: !_yearlySelected,
          badge: null,
          onTap: () => setState(() => _yearlySelected = false),
        )),
        const SizedBox(width: 12),
      ],
      if (store.annualPackage != null)
        Expanded(child: _planOption(
          title: 'Yearly',
          price: '\$${store.annualPackage!.storeProduct.price.toStringAsFixed(2)}',
          detail: '\$${(store.annualPackage!.storeProduct.price / 365).toStringAsFixed(2)}/day',
          trialText: '7-day free trial',
          isSelected: _yearlySelected,
          badge: store.monthlySavingsText,
          onTap: () => setState(() => _yearlySelected = true),
        )),
    ]);
  }

  Widget _planOption({
    required String title,
    required String price,
    required String detail,
    String? trialText,
    required bool isSelected,
    required String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? TributeColor.golden.withValues(alpha: 0.08) : TributeColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? TributeColor.golden.withValues(alpha: 0.4) : TributeColor.cardBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: TributeColor.golden, borderRadius: BorderRadius.circular(20)),
              child: Text(badge,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: TributeColor.charcoal)),
            )
          else
            const SizedBox(height: 17),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5,
                color: isSelected ? TributeColor.golden : Colors.white.withValues(alpha: 0.5),
              )),
          const SizedBox(height: 4),
          Text(price,
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: isSelected ? TributeColor.warmWhite : Colors.white.withValues(alpha: 0.5),
              )),
          const SizedBox(height: 2),
          Text(detail,
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
          if (trialText != null) ...[
            const SizedBox(height: 4),
            Text(trialText,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? TributeColor.sage : Colors.white.withValues(alpha: 0.3))),
          ],
        ]),
      ),
    );
  }
}
