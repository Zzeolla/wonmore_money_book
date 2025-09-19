import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IapService {
  static final IapService _i = IapService._();
  factory IapService() => _i;
  IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _listenerStarted = false;   // ✅ 리스너 시작 여부만 기억
  bool available = false;
  List<ProductDetails> products = [];
  bool isPro = false;

  // --- 가벼운 스타트업: 앱 시작 시 1회만 호출 ---
  Future<void> startListener({
    required void Function(bool) onEntitlementChanged,
    bool doOneTimeRestore = true, // 앱 시작 직후 1회 복원 호출 (권장)
  }) async {
    if (_listenerStarted) return;
    _listenerStarted = true;

    available = await _iap.isAvailable();
    if (!available) return;

    _sub = _iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        switch (p.status) {
          case PurchaseStatus.pending:
            break;

          case PurchaseStatus.error:
            await _finish(p);
            break;

          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
          // 1) 더미 insert (서버 트리거/검증이 뒤에서 수행)
            await _recordPurchaseToDb(p);

            // 2) UX용 낙관 승인
            isPro = true;
            onEntitlementChanged(true);

            // 3) Billing 승인/정리
            await _finish(p);
            break;

          case PurchaseStatus.canceled:
            await _finish(p);
            break;
        }
      }
    });

    // ✅ 앱 재시작 시 미결제/복원 이벤트를 한 번 흡수해서 정리
    if (doOneTimeRestore) {
      try {
        await _iap.restorePurchases();
      } catch (_) {/* ignore */}
    }
  }

  // --- 무거운 초기화: 페이월 들어갈 때 호출 ---
  Future<void> loadProductsIfNeeded() async {
    if (!available) {
      available = await _iap.isAvailable();
      if (!available) return;
    }
    if (products.isNotEmpty) return;
    final resp = await _iap.queryProductDetails({'pro_monthly'});
    products = resp.productDetails.toList();
  }

  // 가격 표시 등은 페이월에서 호출
  String? getMonthlyPriceText() {
    final p = products.where((e) => e.id == 'pro_monthly').firstOrNull;
    if (p == null) return null;
    if (Platform.isAndroid && p is GooglePlayProductDetails) {
      final offers = _gpOffers(p);
      if (offers != null && offers.isNotEmpty) {
        final firstPhase = offers.first.pricingPhases.pricingPhaseList.first;
        return firstPhase.formattedPrice as String;
      }
      return p.price;
    }
    return p.price;
  }

  Future<void> buyMonthly() async {
    final p = products.where((e) => e.id == 'pro_monthly').firstOrNull;
    if (p == null) throw Exception('상품 정보를 찾을 수 없음: pro_monthly');

    if (Platform.isAndroid && p is GooglePlayProductDetails) {
      final offers = _gpOffers(p);
      if (offers == null || offers.isEmpty) {
        throw Exception(
          '구독 오퍼가 비어 있습니다.\n'
              '- 내부 테스트 링크 설치\n'
              '- 라이선스 테스터 계정 등록\n'
              '- Base plan 활성/국가 가격 확인',
        );
      }
      final offerToken = offers.first.offerToken as String;
      final param = GooglePlayPurchaseParam(productDetails: p, offerToken: offerToken);
      await _iap.buyNonConsumable(purchaseParam: param);
      return;
    }
    final param = PurchaseParam(productDetails: p);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async => _iap.restorePurchases();

  Future<void> dispose() async => _sub?.cancel();

  Future<void> _recordPurchaseToDb(PurchaseDetails p) async {
    final supa = Supabase.instance.client;
    final userId = supa.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now().toUtc();
    final productId = p.productID; // ex) 'pro_monthly'
    final purchaseToken = p.verificationData.serverVerificationData; // Android token / iOS receipt
    final isSandbox = !kReleaseMode; // 내부테스트면 true

    // 1) plan_id 가져오기 (subscription_plans에서 name으로 찾거나, 네가 쓰는 키로 찾기)
    //    - 너희 테이블 컬럼에 product_id가 없으면 name으로 매칭해도 됩니다.
    //    - 'Pro Monthly'(또는 콘솔에 맞춘 이름)로 바꿔줘.
    final plan = await supa
        .from('subscription_plans')
        .select('id')
        .eq('name', 'pro')   // <- 네 DB 이름에 맞게 수정
        .maybeSingle();

    final planId = plan?['id'];

    // 2) 임시 만료일 설정 (서버 검증 붙이기 전까지)
    //    - 월 구독이면 now + 31일로 가정 (테스트용)
    final endDate = now.add(const Duration(days: 31));

    // 3) insert (또는 upsert). 네 스키마에 맞춰 필드 채움
    await supa.from('subscriptions').insert({
      // 'id': 생략하면 gen_random_uuid() 사용
      'user_id': userId,
      'plan_id': planId,                 // (필수로 쓰는 구조면 꼭 채워야 함)
      'store': Platform.isAndroid ? 'google' : 'apple',
      'product_id': productId,
      'transaction_id': p.purchaseID,    // 없으면 null로 들어감
      'purchase_token': purchaseToken,
      'status': 'active',
      'is_sandbox': isSandbox,
      'start_date': now.toIso8601String(),
      'end_date': endDate.toIso8601String(),        // 임시: 검증 붙이면 실제 만료일로 업데이트
      'last_verified_at': now.toIso8601String(),
    });
  }

  // IapService 클래스 안 아무 곳에 추가
  List<dynamic>? _gpOffers(ProductDetails pd) {
    if (pd is GooglePlayProductDetails) {
      final dyn = pd as dynamic;
      try {
        // 신/구 버전 모두 대응
        return (dyn.subscriptionOfferDetails as List?) ??
            (dyn.billingClientProductDetails?.subscriptionOfferDetails as List?);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _finish(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) {
      await _iap.completePurchase(p);
    }
  }

  // 서버 검증은 이후 붙이고, 지금은 MVP로 통과
  Future<bool> _verifyMvp(PurchaseDetails p) async {
    // Android: p.verificationData.serverVerificationData == purchaseToken
    // iOS: base64 receipt
    return true;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
