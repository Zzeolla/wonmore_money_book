// export_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:wonmore_money_book/model/transaction_model.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class ExportResult {
  final String filename;          // 원하는 최종 파일명 (공유/저장 둘 다 이걸 기준으로)
  final String? savedPathOrUri;   // Android: content:// or /path | iOS: /path | 실패 시 null
  final Uint8List bytes;          // 공유/열기용 바이트
  ExportResult({
    required this.filename,
    required this.savedPathOrUri,
    required this.bytes,
  });
}

class ExportService {
  static const _ch = MethodChannel('wonmore/downloads'); // Android 전용 채널
  static final _dateFmt = DateFormat('yyyy.MM.dd HH:mm');
  static final _fileDateFmt = DateFormat('yyyyMMdd_HHmm');

  static CellValue _t(String s) => TextCellValue(s);
  static CellValue _n(num v) => (v is int) ? IntCellValue(v) : DoubleCellValue(v.toDouble());

  /// 엑셀 생성 → (Android: Downloads / iOS: Documents) 저장 시도 → 결과 반환
  static Future<ExportResult> buildExcelAndSaveToDownloads({
    required List<TransactionModel> txs,
    required String titleSuffix,
    Map<String, String>? categoryNameById,
    Map<String, String>? assetNameById,
  }) async {
    // 1) 데이터 → 엑셀
    txs.sort((a, b) => b.date.compareTo(a.date));

    final excel = Excel.createExcel();
    final sheet = excel['원모아 내보내기'];

    final header = <CellValue?>[
      _t('일시'), _t('유형'), _t('금액'), _t('내역'), _t('분류'), _t('자산'), _t('메모'),
    ];
    sheet.appendRow(header);

    for (final t in txs) {
      final categoryText = (t.categoryId != null) ? (categoryNameById?[t.categoryId] ?? t.categoryId!) : '';
      final assetText    = (t.assetId != null)    ? (assetNameById?[t.assetId]    ?? t.assetId!)    : '';
      sheet.appendRow(<CellValue?>[
        _t(_dateFmt.format(t.date)),
        _t(_label(t.type)),
        _n(t.amount),
        _t(t.title ?? ''),
        _t(categoryText),
        _t(assetText),
        _t(t.memo ?? ''),
      ]);
    }

    // 헤더 볼드
    final bold = CellStyle(bold: true);
    for (int c = 0; c < header.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle = bold;
    }

    final bytesList = excel.encode();
    if (bytesList == null) throw Exception('엑셀 인코딩 실패');
    final bytes = Uint8List.fromList(bytesList);

    // 2) 파일명 (공유/저장 통일)
    final safe = titleSuffix.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final filename = '원모아_내보내기_${safe}_${_fileDateFmt.format(DateTime.now())}.xlsx';

    // 3) 플랫폼별 저장 시도
    String? saved;
    if (Platform.isAndroid) {
      try {
        saved = await _ch.invokeMethod<String>('saveToDownloads', {
          'filename': filename,
          'mimeType': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'bytes': bytes,
        });
      } catch (_) {
        saved = null; // 실패해도 bytes 공유 가능
      }
    } else if (Platform.isIOS) {
      try {
        // iOS에선 Documents에 저장만 해두고, 실제 접근은 공유로 처리
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);
        saved = file.path;
      } catch (_) {
        saved = null;
      }
    } else {
      // 기타 플랫폼: Documents에 저장
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);
        saved = file.path;
      } catch (_) {
        saved = null;
      }
    }

    return ExportResult(filename: filename, savedPathOrUri: saved, bytes: bytes);
  }

  /// 공유는 항상 bytes 기반으로, name을 filename으로 고정해서 “파일명 틀어짐” 방지
  static Future<void> shareExport(ExportResult result, {String? shareText, String? shareSubject}) async {
    final tmpDir = await getTemporaryDirectory(); // iOS/Android 공통
    final shareFile = File('${tmpDir.path}/${result.filename}');
    await shareFile.writeAsBytes(result.bytes, flush: true);

    await Share.shareXFiles(
      [XFile(shareFile.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      text: shareText,
      subject: shareSubject,
    );
  }

  static String _label(TransactionType type) {
    switch (type) {
      case TransactionType.expense:  return '지출';
      case TransactionType.income:   return '수입';
      case TransactionType.transfer: return '이체';
    }
  }
}
