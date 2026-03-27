import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class StoreProvider extends ChangeNotifier {
  Offerings? offerings;
  bool isPremium = false;
  bool isLoading = false;
  bool isPurchasing = false;
  String? error;

  bool _configured = false;

  void configure(String apiKey) {
    if (apiKey.isEmpty) return;
    Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
    _init();
  }

  Future<void> _init() async {
    _listenForUpdates();
    await fetchOfferings();
    await checkStatus();
  }

  void _listenForUpdates() {
    if (!_configured) return;
    Purchases.addCustomerInfoUpdateListener((info) {
      isPremium = info.entitlements.all['premium']?.isActive == true;
      notifyListeners();
    });
  }

  Future<void> fetchOfferings() async {
    if (!_configured) return;
    isLoading = true;
    notifyListeners();
    try {
      offerings = await Purchases.getOfferings();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> purchase(Package package) async {
    if (!_configured) return;
    isPurchasing = true;
    error = null;
    notifyListeners();
    try {
      final result = await Purchases.purchasePackage(package);
      isPremium = result.entitlements.all['premium']?.isActive == true;
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError && e != PurchasesErrorCode.paymentPendingError) {
        error = e.toString();
      }
    } catch (e) {
      error = e.toString();
    }
    isPurchasing = false;
    notifyListeners();
  }

  Future<void> restore() async {
    if (!_configured) return;
    isLoading = true;
    notifyListeners();
    try {
      final info = await Purchases.restorePurchases();
      isPremium = info.entitlements.all['premium']?.isActive == true;
      if (!isPremium) error = 'No active subscription found.';
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> checkStatus() async {
    if (!_configured) return;
    try {
      final info = await Purchases.getCustomerInfo();
      isPremium = info.entitlements.all['premium']?.isActive == true;
      notifyListeners();
    } catch (_) {}
  }

  Package? get monthlyPackage => offerings?.current?.availablePackages
      .where((p) => p.identifier == '\$rc_monthly')
      .firstOrNull;

  Package? get annualPackage => offerings?.current?.availablePackages
      .where((p) => p.identifier == '\$rc_annual')
      .firstOrNull;

  String? get monthlySavingsText {
    final monthly = monthlyPackage;
    final annual = annualPackage;
    if (monthly == null || annual == null) return null;
    final monthlyTotal = monthly.storeProduct.price * 12;
    final annualPrice = annual.storeProduct.price;
    if (monthlyTotal <= annualPrice) return null;
    final savings = ((monthlyTotal - annualPrice) / monthlyTotal * 100).round();
    return 'Save $savings%';
  }
}
