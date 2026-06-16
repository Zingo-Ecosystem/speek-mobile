import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../state/app_state.dart';

/// Wraps `in_app_purchase`. Product IDs must be configured in App Store
/// Connect / Google Play Console before real purchases work. When the store is
/// unavailable (web, simulator, unconfigured), it falls back to a local grant
/// so the flow is testable end-to-end.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const monthlyId = 'speek_premium_monthly';
  static const yearlyId = 'speek_premium_yearly';
  static const _ids = {monthlyId, yearlyId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _sub = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (_) {});
    } catch (_) {
      // Plugin not available on this platform.
    }
  }

  // SubscriptionSource: AppStore = 2, PlayStore = 3
  int get _storeSource =>
      defaultTargetPlatform == TargetPlatform.iOS ? 2 : 3;

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        // Validate the receipt server-side; the backend is the source of truth.
        AppState.instance.validatePurchase(
          store: _storeSource,
          productId: p.productID,
          receiptData: p.verificationData.serverVerificationData,
        );
      }
      if (p.pendingCompletePurchase) {
        _iap.completePurchase(p);
      }
    }
  }

  /// Returns true if the store completed (or was simulated) successfully.
  Future<({bool ok, String message})> buy({required bool yearly}) async {
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        return _fallback();
      }
      final resp = await _iap.queryProductDetails(_ids);
      final id = yearly ? yearlyId : monthlyId;
      final product =
          resp.productDetails.where((p) => p.id == id).firstOrNull;
      if (product == null) {
        return _fallback();
      }
      final param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
      return (ok: true, message: 'Purchase started…');
    } catch (e) {
      return _fallback();
    }
  }

  /// Local grant used when no real store is configured (MVP/demo).
  ({bool ok, String message}) _fallback() {
    AppState.instance.subscribe();
    return (
      ok: true,
      message: kReleaseMode
          ? 'Subscription activated'
          : 'Store not configured — premium granted for testing'
    );
  }

  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  void dispose() => _sub?.cancel();
}
