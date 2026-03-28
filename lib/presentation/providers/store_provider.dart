import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product IDs — must match App Store Connect / Google Play Console exactly.
class TributeProducts {
  static const monthly = 'tribute_premium_monthly';
  static const annual = 'tribute_premium_annual';
  static const lifetime = 'tribute_premium_lifetime';
  static const all = {monthly, annual, lifetime};
}

class StoreProvider extends ChangeNotifier with WidgetsBindingObserver {
  final FirebaseFirestore _db;
  final InAppPurchase _iap;

  StoreProvider({
    FirebaseFirestore? db,
    InAppPurchase? iap,
  })  : _db = db ?? FirebaseFirestore.instance,
        _iap = iap ?? InAppPurchase.instance;

  Map<String, ProductDetails> _products = {};
  bool isPremium = false;
  bool isLoading = false;
  bool isPurchasing = false;
  String? error;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  // ── Getters ───────────────────────────────────────────────────────────────

  ProductDetails? get monthlyProduct => _products[TributeProducts.monthly];
  ProductDetails? get annualProduct => _products[TributeProducts.annual];
  ProductDetails? get lifetimeProduct => _products[TributeProducts.lifetime];

  String? get monthlySavingsText {
    final monthly = monthlyProduct;
    final annual = annualProduct;
    if (monthly == null || annual == null) return null;
    final monthlyTotal = monthly.rawPrice * 12;
    final annualPrice = annual.rawPrice;
    if (monthlyTotal <= annualPrice) return null;
    final savings = ((monthlyTotal - annualPrice) / monthlyTotal * 100).round();
    return 'Save $savings%';
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Call once after the provider is created (and the user may be authenticated).
  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    isLoading = true;
    notifyListeners();

    final available = await _iap.isAvailable();
    if (!available) {
      isLoading = false;
      notifyListeners();
      return;
    }

    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) {
        error = e.toString();
        notifyListeners();
      },
    );

    await Future.wait([
      _loadProducts(),
      _syncPremiumFromFirestore(),
    ]);

    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseSub?.cancel();
    super.dispose();
  }

  /// Re-sync premium status from Firestore whenever the app returns to the
  /// foreground — catches subscription lapses that occurred while it was closed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPremiumFromFirestore().then((_) => notifyListeners());
    }
  }

  // ── Products ──────────────────────────────────────────────────────────────

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(TributeProducts.all);
      _products = {for (final p in response.productDetails) p.id: p};
    } catch (e) {
      error = e.toString();
    }
  }

  // ── Premium status ────────────────────────────────────────────────────────

  /// Reads premium status from Firestore (source of truth after server validation).
  Future<void> _syncPremiumFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      isPremium = false;
      return;
    }
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('subscription')
          .doc('status')
          .get();

      if (!snap.exists || snap.data() == null) {
        isPremium = false;
        return;
      }
      final data = snap.data()!;
      final status = data['status'] as String?;
      if (status != 'active') {
        isPremium = false;
        return;
      }
      final expiresAt = data['expiresAt'];
      if (expiresAt == null) {
        isPremium = true; // lifetime
        return;
      }
      final expiry = expiresAt is Timestamp ? expiresAt.toDate() : null;
      isPremium = expiry != null && expiry.isAfter(DateTime.now());
    } catch (_) {
      // Network error — leave isPremium unchanged (optimistic for existing users).
    }
  }

  // ── Purchase flow ─────────────────────────────────────────────────────────

  Future<void> purchase(ProductDetails product) async {
    isPurchasing = true;
    error = null;
    notifyListeners();
    try {
      final param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
      // Actual delivery happens in _onPurchaseUpdates.
    } catch (e) {
      error = e.toString();
      isPurchasing = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _iap.restorePurchases();
      // Delivery/verification happens in _onPurchaseUpdates.
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  // ── Purchase stream handler ───────────────────────────────────────────────

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Nothing to do — UI already shows spinner.
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Complete the transaction on the store side first.
          try {
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            await _validateWithServer(purchase);
          } finally {
            isPurchasing = false;
          }
          notifyListeners();

        case PurchaseStatus.error:
          final msg = purchase.error?.message ?? 'Purchase failed';
          // Ignore user-cancelled (code 2 on iOS, userCancelled on Android).
          if (!_isCancelledError(purchase.error)) {
            error = msg;
          }
          isPurchasing = false;
          notifyListeners();

        case PurchaseStatus.canceled:
          isPurchasing = false;
          notifyListeners();
      }
    }
  }

  bool _isCancelledError(IAPError? err) {
    if (err == null) return false;
    if (Platform.isIOS && err.code == 'storekit_duplicate_product_object') return false;
    // iOS cancel code is 2 (SKErrorPaymentCancelled)
    return err.message.toLowerCase().contains('cancel') ||
        err.code == 'BillingResponse.userCanceled' ||
        err.code == '2';
  }

  // ── Server validation ─────────────────────────────────────────────────────

  /// Calls the `validateReceipt` Firebase callable Function to verify the
  /// purchase server-side and write subscription status to Firestore.
  Future<void> _validateWithServer(PurchaseDetails purchase) async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      final payload = <String, dynamic>{
        'platform': Platform.isIOS ? 'ios' : 'android',
        'productId': purchase.productID,
      };

      if (Platform.isIOS) {
        // localVerificationData is the base64-encoded App Store receipt.
        payload['receiptData'] = purchase.verificationData.localVerificationData;
      } else {
        // serverVerificationData is the Google Play purchase token.
        payload['purchaseToken'] = purchase.verificationData.serverVerificationData;
      }

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('validateReceipt');
      final result = await callable.call<Map<String, dynamic>>(payload);
      isPremium = result.data['isPremium'] as bool? ?? false;
    } catch (e) {
      error = 'Receipt validation failed: ${e.toString()}';
    }
  }
}
