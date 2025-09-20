import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IapService {
  static final IapService _instance = IapService._internal();

  factory IapService() => _instance;

  IapService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool available = false;
  List<ProductDetails> products = [];

  /// 앱 시작 시 1회만 호출
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

            case PurchaseStatus.error:
            case PurchaseStatus.canceled:
              break;

            case PurchaseStatus.pending:
              break;
          }
        } finally {
          // ✅ DB 오류가 나도 결제 플로우는 반드시 종료
          await _finish(p);
        }
      }
    });

    // 앱 재시작 시 미결제/복원 이벤트 정리
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  Future<void> loadProducts() async {
    if (!available) {
      available = await _iap.isAvailable();
      if (!available) return;
    }
    if (products.isNotEmpty) return;

    const ids = {'pro_monthly'}; // 콘솔 productId
    final resp = await _iap.queryProductDetails(ids);
    products = resp.productDetails;
  }

  // 원하는 basePlanId('monthly-base' | 'monthly-basic') 또는 offerId로 타겟팅
  dynamic _findOffer(ProductDetails p, {String? basePlanId, String? offerId}) {
    final any = p as dynamic;
    final offers =
        any.subscriptionOfferDetails ??
            any.billingClientProductDetails?.subscriptionOfferDetails;

    if (offers == null || (offers is List && offers.isEmpty)) return null;

    for (final o in offers as List) {
      final bp = (o as dynamic).basePlanId ?? (o as Map?)?['basePlanId'];
      final oid = (o as dynamic).offerId ?? (o as Map?)?['offerId'];
      final okBase = basePlanId == null || basePlanId == bp;
      final okOffer = offerId == null || offerId == oid;
      if (okBase && okOffer) return o;
    }
    // 못 찾으면 첫 오퍼로 폴백
    return (offers).first;
  }

  Future<void> buyByBasePlan(String basePlanId) async {
    if (products.isEmpty) await loadProducts();
    final p = products.firstWhere((e) => e.id == 'pro_monthly');

    if (Platform.isAndroid) {
      final offer = _findOffer(p, basePlanId: basePlanId);
      if (offer == null) throw Exception('오퍼 없음 ($basePlanId)');

      final token = (offer as dynamic).offerToken ?? (offer as Map?)?['offerToken'];
      if (token == null || token.isEmpty) throw Exception('offerToken 없음');

      final param = GooglePlayPurchaseParam(productDetails: p, offerToken: token);
      await _iap.buyNonConsumable(purchaseParam: param);
    } else {
      // iOS는 product만으로 구매 (추후 구현)
      final param = PurchaseParam(productDetails: p);
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  String? getPriceTextByBasePlan(String basePlanId) {
    final match = products.where((e) => e.id == 'pro_monthly').toList();
    if (match.isEmpty) return null;
    final p = match.first;

    if (Platform.isAndroid) {
      final offer = _findOffer(p, basePlanId: basePlanId);
      if (offer != null) {
        final phases = ((offer as dynamic).pricingPhases?.pricingPhaseList
            ?? (offer as Map?)?['pricingPhases']?['pricingPhaseList']) as List?;
        if (phases != null && phases.isNotEmpty) {
          final first = phases.first as dynamic;
          if (phases.length > 1) {
            final last = phases.last as dynamic;
            final fp = first.formattedPrice ?? first['formattedPrice'];
            final fb = first.billingPeriod ?? first['billingPeriod'];
            final lp = last.formattedPrice ?? last['formattedPrice'];
            final lb = last.billingPeriod ?? last['billingPeriod'];
            return '$fp ($fb 무료) → $lp/$lb';
          } else {
            final fp = first.formattedPrice ?? first['formattedPrice'];
            final fb = first.billingPeriod ?? first['billingPeriod'];
            return '$fp/$fb';
          }
        }
      }
    }
    return p.price; // iOS 또는 파싱 실패 시 폴백
  }

  Future<void> buy(String productId) async {
    final p = products.firstWhere((e) => e.id == productId);

    if (Platform.isAndroid) {
      // ✅ dynamic 폴백: 어떤 형태든 오퍼를 꺼내본다
      final any = p as dynamic;
      final offers =
          any.subscriptionOfferDetails ??
              any.billingClientProductDetails?.subscriptionOfferDetails;

      if (offers == null || (offers is List && offers.isEmpty)) {
        throw Exception('오퍼 없음 (Base plan/국가/자격조건 확인)');
      }

      // offers.first 가 Map일 수도, 객체일 수도 있으니 둘 다 대응
      String? offerToken;
      final first = (offers as List).first;
      if (first is Map) {
        offerToken = first['offerToken'] as String?;
      } else {
        // 객체 형태라면 getter 접근 시도
        offerToken = (first as dynamic).offerToken as String?;
      }

      if (offerToken == null || offerToken.isEmpty) {
        throw Exception('offerToken 없음');
      }

      final param = GooglePlayPurchaseParam(
        productDetails: p,
        offerToken: offerToken,
      );
      await _iap.buyNonConsumable(purchaseParam: param);
    } else {
      final param = PurchaseParam(productDetails: p);
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  Future<void> restore() async => _iap.restorePurchases();

  Future<void> dispose() async => _subscription?.cancel();

  Future<void> _finish(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) {
      await _iap.completePurchase(p);
    }
  }

  /// 가격 표시 (무료체험 포함 Phase 파싱)
  String? getPriceText(String productId) {
    final match = products.where((e) => e.id == productId).toList();
    if (match.isEmpty) return null;
    final p = match.first;

    if (Platform.isAndroid) {
      final any = p as dynamic;
      final offers =
          any.subscriptionOfferDetails ??
              any.billingClientProductDetails?.subscriptionOfferDetails;

      if (offers != null && (offers is List) && offers.isNotEmpty) {
        final firstOffer = offers.first;

        // phases를 객체/맵 두 경우 모두 커버
        List<dynamic>? phases;
        if (firstOffer is Map) {
          phases = (firstOffer['pricingPhases']?['pricingPhaseList'] as List?)?.cast<dynamic>();
        } else {
          phases = (firstOffer as dynamic).pricingPhases?.pricingPhaseList as List<dynamic>?;
        }

        if (phases != null && phases.isNotEmpty) {
          final first = phases.first as dynamic;
          if (phases.length > 1) {
            final last = phases.last as dynamic;
            return '${first.formattedPrice ?? first['formattedPrice']} '
                '(${first.billingPeriod ?? first['billingPeriod']} 무료) → '
                '${last.formattedPrice ?? last['formattedPrice']}/'
                '${last.billingPeriod ?? last['billingPeriod']}';
          } else {
            return '${first.formattedPrice ?? first['formattedPrice']}/'
                '${first.billingPeriod ?? first['billingPeriod']}';
          }
        }
      }
    }
    return p.price;
  }


  Future<void> _recordPurchaseToDb(PurchaseDetails p) async {
    final supa = Supabase.instance.client;
    final userId = supa.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now().toUtc();
    final productId = p.productID; // ex) 'pro_monthly'
    final purchaseTokenAndroid = p.verificationData.serverVerificationData; // AND
    final receiptIos = p.verificationData.localVerificationData;            // iOS
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

    final data = <String, dynamic>{
      'user_id': userId,
      'plan_id': planId,                 // (필수로 쓰는 구조면 꼭 채워야 함)
      'store': Platform.isAndroid ? 'google' : 'apple',
      'product_id': productId,
      'transaction_id': p.purchaseID,    // 없으면 null로 들어감
      'purchase_token': Platform.isAndroid ? purchaseTokenAndroid : receiptIos,
      'status': 'pending',
      'is_sandbox': null,
      'start_date': now.toIso8601String(),
      'end_date': null,        // 임시: 검증 붙이면 실제 만료일로 업데이트
      'last_verified_at': now.toIso8601String(),
    };

    await supa.from('subscriptions').upsert(
      data,
      onConflict: 'purchase_token'
    );
  }
}