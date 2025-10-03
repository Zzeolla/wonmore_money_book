import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IapService {
  void Function()? onVerified;
  static final IapService _instance = IapService._internal();
  static const String _verifyFnName = 'verify-subscription';
  static final String _edgeSecret = dotenv.env['EDGE_SECRET']!;
  factory IapService() => _instance;
  IapService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool available = false;
  bool _listenerStarted = false;
  List<ProductDetails> products = [];

  /// 앱 시작 시 1회만 호출 (Splash 등에서)
  Future<void> startListener() async {
    if (_listenerStarted) return;
    _listenerStarted = true;

    available = await _iap.isAvailable();
    if (!available) return;

    _subscription ??= _iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        try {
          switch (p.status) {
            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
              await _recordPurchaseToDb(p);
              await verifyNow();
              onVerified?.call();
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

    // 1) Android/iOS별 토큰 추출
    String? purchaseToken;
    try {
      if (Platform.isAndroid) {
        // 보통은 토큰 문자열이 바로 오지만, 일부 버전에선 JSON 문자열일 수 있음
        final raw = p.verificationData.serverVerificationData;
        if (raw.trim().startsWith('{')) {
          final obj = jsonDecode(raw);
          purchaseToken = obj['purchaseToken'] ?? obj['token'] ?? raw;
        } else {
          purchaseToken = raw;
        }
      } else {
        // iOS는 영수증(base64) 전체
        purchaseToken = p.verificationData.localVerificationData;
      }
    } catch (_) {
      purchaseToken = p.verificationData.serverVerificationData;
    }

    // 2) plan_id 조회 (name='pro')
    String? planId;
    try {
      final plan = await supa
          .from('subscription_plans')
          .select('id')
          .eq('name', 'pro')
          .maybeSingle();
      planId = plan?['id'] as String?;
    } catch (e) {
      // 로깅만 하고 null 허용
      // print('plan query error: $e');
    }

    // ✅ 이미 같은 purchase_token 행이 있으면 덮어쓰지 않음
    final existing = await supa
        .from('subscriptions')
        .select('id,status,end_date')
        .eq('purchase_token', purchaseToken!)
        .maybeSingle();

    if (existing != null) {
      // 옵션) 정말 처음 기록해야 할 게 있으면 '안전 업데이트'만 수행:
      // 예: transaction_id가 비어있고 이번에 생겼다면 채우기
      // await supa.from('subscriptions').update({'transaction_id': p.purchaseID})
      //   .eq('purchase_token', purchaseToken)
      //   .is_('transaction_id', null);
      return;
    }

    final data = <String, dynamic>{
      'user_id': userId,
      'plan_id': planId,
      'store': Platform.isAndroid ? 'google_play' : 'apple_app_store',
      'product_id': p.productID,
      'transaction_id': p.purchaseID,
      'purchase_token': purchaseToken,
      'status': 'pending',
      'is_sandbox': kDebugMode,
      'start_date': now.toIso8601String(),
      'end_date': null, // 검증 후 실제 만료일로 업데이트
      'last_verified_date': now.toIso8601String(),
    };

    await supa.from('subscriptions').insert(data);
  }

  Future<void> testInsertDummy() async {
    final supa = Supabase.instance.client;
    final userId = supa.auth.currentUser?.id;

    if (userId == null) {
      print('[TEST] user not logged in!');
      return;
    }

    final now = DateTime.now().toUtc();

    // 2) plan_id 조회 (name='pro')
    String? planId;
    try {
      final plan = await supa
          .from('subscription_plans')
          .select('id')
          .eq('name', 'pro')
          .maybeSingle();
      planId = plan?['id'] as String?;
    } catch (e) {
      // 로깅만 하고 null 허용
      // print('plan query error: $e');
    }

    final data = <String, dynamic>{
      'user_id': userId,
      'plan_id': planId, // 실제 plan_id 조회 안 하고 null로 둠
      'store': 'google_play',
      'product_id': 'pro_monthly',
      'transaction_id': 'TEST_TXN_${DateTime.now().millisecondsSinceEpoch}',
      'purchase_token': 'TEST_TOKEN_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'pending',
      'is_sandbox': kDebugMode,
      'start_date': now.toIso8601String(),
      'end_date': null,
      'last_verified_date': now.toIso8601String(),
    };

    try {
      print('[TEST] insert payload: $data');
      final resp = await supa.from('subscriptions').insert(data);
      print('[TEST] insert resp: $resp');
    } catch (e, st) {
      print('[TEST] insert error: $e\n$st');
    }
  }

  Future<void> verifyNow({String? purchaseToken}) async {
    final supa = Supabase.instance.client;
    final userId = supa.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final resp = await supa.functions.invoke(
        _verifyFnName,
        headers: {
          'x-api-key': _edgeSecret,
          'Content-Type': 'application/json',
        },
        body: {
          'user_id': userId,
          if (purchaseToken != null) 'purchase_token': purchaseToken,
          'is_sandbox': kDebugMode,
          'store': 'google_play',
        },
      );
      // print('[VERIFY] ${resp.data}');
    } catch (e) {
      // print('[VERIFY][ERR] $e');
    }
  }
}
