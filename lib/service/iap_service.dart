import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IapService {
  static final IapService _instance = IapService._internal();
  factory IapService() => _instance;
  IapService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool available = false;
  List<ProductDetails> products = [];

  /// 앱 시작 시 1회만 호출 (Splash 등에서)
  Future<void> startListener() async {
    available = await _iap.isAvailable();
    if (!available) return;

    _subscription ??= _iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        try {
          switch (p.status) {
            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
              await _recordPurchaseToDb(p);
              break;
            case PurchaseStatus.pending:
            case PurchaseStatus.canceled:
            case PurchaseStatus.error:
              break;
          }
        } finally {
          // 결제 플로우는 반드시 종료
          await _finish(p);
        }
      }
    }, onError: (_) {});

    // 앱 재시작 시 미완료 이벤트 정리
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  /// 콘솔에 등록된 상품 정보 조회
  Future<void> loadProducts() async {
    if (!available) {
      available = await _iap.isAvailable();
      if (!available) return;
    }
    if (products.isNotEmpty) return;

    // ✅ 필요한 productId들을 모두 나열하세요.
    //   무료체험/무체험을 동시에 노출하려면 서로 다른 productId로 등록 후 여기에 둘 다 넣으면 됩니다.
    const ids = {
      'pro_monthly',          // 예: 기본(또는 무료체험) 플랜
      // 'pro_monthly_basic',  // 예: 무체험 플랜 (별도 productId로 우회)
    };

    final resp = await _iap.queryProductDetails(ids);
    products = resp.productDetails;
  }

  /// 단일 상품 구매 (플러그인 내부가 플랫폼별로 알아서 처리)
  Future<void> buy(String productId) async {
    if (products.isEmpty) await loadProducts();

    final idx = products.indexWhere((e) => e.id == productId);
    if (idx == -1) {
      throw Exception('상품($productId) 없음');
    }
    final p = products[idx];

    // ⚠️ in_app_purchase_android 전용 타입/offerToken 사용 안 함
    //    PurchaseParam 만 넘기면, Android에선 내부가 GooglePlayProductDetails.offerToken(첫 오퍼)을 자동 사용
    final param = PurchaseParam(productDetails: p);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async => _iap.restorePurchases();
  Future<void> dispose() async => _subscription?.cancel();

  Future<void> _finish(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) {
      await _iap.completePurchase(p);
    }
  }

  // ---------- 가격 표시 ----------
  /// 현 구조에서는 상세 phase(무료체험/정가) 파싱 없이, 스토어가 주는 표시 문자열 사용
  String? getPriceText(String productId) {
    final idx = products.indexWhere((e) => e.id == productId);
    if (idx == -1) return null;
    return products[idx].price; // 예: ₩3,900
  }

  // IapService에 유틸 추가(선택사항)
  String displayPriceOrTrial(String productId, {String? regularPriceText}) {
    final idx = products.indexWhere((e) => e.id == productId);
    if (idx == -1) return '가격 불러오기 실패';
    final p = products[idx];

    // 무료 phase가 첫번째면 price는 '무료', rawPrice는 0.0
    final isFreePhase = (p.rawPrice == 0) || (p.price.trim() == '무료');

    if (isFreePhase) {
      if (regularPriceText != null && regularPriceText.isNotEmpty) {
        return '3일 무료 체험 후 $regularPriceText';
      }
      return '3일 무료 체험 후 자동 갱신';
    }

    // 평상시(체험 없는 플랜이 기본이거나, 첫 phase가 유료인 경우)
    return p.price; // 예: ₩3,900
  }

  // ---------- 결제 기록(서버 검증 전 임시) ----------
  Future<void> _recordPurchaseToDb(PurchaseDetails p) async {
    final supa = Supabase.instance.client;
    final userId = supa.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now().toUtc();
    final productId = p.productID;
    final purchaseTokenAndroid = p.verificationData.serverVerificationData; // AND
    final receiptIos = p.verificationData.localVerificationData;            // iOS

    // 네 스키마에 맞춰 조정
    final plan = await supa
        .from('subscription_plans')
        .select('id')
        .eq('name', 'pro')
        .maybeSingle();
    final planId = plan?['id'];

    final data = <String, dynamic>{
      'user_id': userId,
      'plan_id': planId,
      'store': Platform.isAndroid ? 'google' : 'apple',
      'product_id': productId,
      'transaction_id': p.purchaseID,
      'purchase_token': Platform.isAndroid ? purchaseTokenAndroid : receiptIos,
      'status': 'pending',
      'is_sandbox': null,
      'start_date': now.toIso8601String(),
      'end_date': null, // 검증 후 실제 만료일로 업데이트
      'last_verified_at': now.toIso8601String(),
    };

    await supa.from('subscriptions').upsert(
      data,
      onConflict: 'purchase_token',
    );
  }
}
