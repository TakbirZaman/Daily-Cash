import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/l10n/strings.dart';
import '../core/theme/colors.dart';
import '../core/utils/money.dart';
import '../models/transaction_model.dart';

/// Exports one month to Excel or PDF and opens the phone's share sheet.
/// Both return false (never throw) if anything goes wrong.
class ExportService {
  ExportService._();

  static const double _w = 1190; // A4 at 2x
  static const double _h = 1684;
  static const int _rowsPerPage = 24;

  static String _stamp(DateTime month) => DateFormat('yyyy-MM', 'en').format(month);

  static Future<bool> shareExcel({
    required DateTime month,
    required List<TransactionModel> items,
    required double income,
    required double expense,
  }) async {
    try {
      final xl.Excel book = xl.Excel.createExcel();
      book.rename('Sheet1', 'Entries');
      final xl.Sheet sheet = book['Entries'];

      sheet.appendRow(<xl.CellValue>[
        xl.TextCellValue('Date'),
        xl.TextCellValue('Type'),
        xl.TextCellValue('Amount (Tk)'),
        xl.TextCellValue('Note'),
      ]);

      final DateFormat fmt = DateFormat('yyyy-MM-dd HH:mm', 'en');
      for (final TransactionModel t in items.reversed) {
        sheet.appendRow(<xl.CellValue>[
          xl.TextCellValue(fmt.format(t.timestamp)),
          xl.TextCellValue(t.isIncome ? 'Income' : 'Expense'),
          xl.DoubleCellValue(t.amount),
          xl.TextCellValue(t.note ?? ''),
        ]);
      }

      sheet.appendRow(<xl.CellValue>[xl.TextCellValue('')]);
      sheet.appendRow(<xl.CellValue>[
        xl.TextCellValue('Total income'),
        xl.TextCellValue(''),
        xl.DoubleCellValue(income),
      ]);
      sheet.appendRow(<xl.CellValue>[
        xl.TextCellValue('Total expense'),
        xl.TextCellValue(''),
        xl.DoubleCellValue(expense),
      ]);
      sheet.appendRow(<xl.CellValue>[
        xl.TextCellValue('Balance'),
        xl.TextCellValue(''),
        xl.DoubleCellValue(income - expense),
      ]);

      final List<int>? bytes = book.encode();
      if (bytes == null) return false;

      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/daily_cash_${_stamp(month)}.xlsx');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        <XFile>[
          XFile(file.path,
              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
        ],
        subject: 'Daily Cash ${_stamp(month)}',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The pages are drawn with Flutter's own text engine and placed in the PDF as
  /// images, so Bangla text and the ৳ sign always render correctly.
  static Future<bool> sharePdf({
    required DateTime month,
    required List<TransactionModel> items,
    required double income,
    required double expense,
  }) async {
    try {
      final List<TransactionModel> rows = items.reversed.toList();
      final int pageCount = rows.isEmpty ? 1 : (rows.length / _rowsPerPage).ceil();

      final pw.Document doc = pw.Document();
      for (int p = 0; p < pageCount; p++) {
        final List<TransactionModel> chunk =
            rows.skip(p * _rowsPerPage).take(_rowsPerPage).toList();
        final Uint8List png = await _renderPage(
          page: p,
          pageCount: pageCount,
          month: month,
          income: income,
          expense: expense,
          rows: chunk,
        );
        final pw.MemoryImage image = pw.MemoryImage(png);
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context _) => pw.Image(image, fit: pw.BoxFit.fill),
        ));
      }

      final Uint8List bytes = await doc.save();
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/daily_cash_${_stamp(month)}.pdf');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        <XFile>[XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Daily Cash ${_stamp(month)}',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List> _renderPage({
    required int page,
    required int pageCount,
    required DateTime month,
    required double income,
    required double expense,
    required List<TransactionModel> rows,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _w, _h));
    canvas.drawRect(const Rect.fromLTWH(0, 0, _w, _h), Paint()..color = Colors.white);

    void text(
      String s,
      double x,
      double y, {
      double width = 600,
      double size = 26,
      FontWeight weight = FontWeight.w400,
      Color color = const Color(0xFF1B2B27),
      TextAlign align = TextAlign.left,
    }) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(fontFamily: 'Manrope', fontSize: size, fontWeight: weight, color: color),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: align,
        maxLines: 1,
        ellipsis: '…',
      )..layout(minWidth: width, maxWidth: width);
      tp.paint(canvas, Offset(x, y));
    }

    const Color ink = Brand.ink;
    const Color green = Brand.income;
    const Color red = Brand.expense;
    const double left = 80;
    const double contentW = _w - 160;

    double y = 80;
    text(S.t('app_name'), left, y, size: 54, weight: FontWeight.w700, color: ink);
    text(
      S.digits(DateFormat('MMMM y', S.locale).format(month)),
      left,
      y + 70,
      size: 32,
      color: const Color(0xFF5B6B66),
    );

    if (page == 0) {
      y = 230;
      text('${S.t('total_income')}: ${Money.format(income)}', left, y,
          width: 520, size: 28, weight: FontWeight.w700, color: green);
      text('${S.t('total_expense')}: ${Money.format(expense)}', left + 520, y,
          width: 510, size: 28, weight: FontWeight.w700, color: red);
      text('${S.t('month_balance')}: ${Money.format(income - expense)}', left, y + 50,
          width: 900, size: 30, weight: FontWeight.w700, color: ink);
      y = 360;
    } else {
      y = 230;
    }

    // Table header
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, y, contentW, 58),
        const Radius.circular(12),
      ),
      Paint()..color = ink,
    );
    const Color white = Colors.white;
    text(S.t('col_date'), left + 16, y + 14,
        width: 240, size: 24, weight: FontWeight.w700, color: white);
    text(S.t('col_note'), left + 270, y + 14,
        width: 400, size: 24, weight: FontWeight.w700, color: white);
    text(S.t('col_type'), left + 690, y + 14,
        width: 130, size: 24, weight: FontWeight.w700, color: white);
    text(S.t('col_amount'), left + 830, y + 14,
        width: 184, size: 24, weight: FontWeight.w700, color: white, align: TextAlign.right);
    y += 66;

    final DateFormat dateFmt = DateFormat('d MMM, h:mm a', S.locale);
    for (int i = 0; i < rows.length; i++) {
      final TransactionModel t = rows[i];
      if (i.isOdd) {
        canvas.drawRect(
          Rect.fromLTWH(left, y - 4, contentW, 54),
          Paint()..color = const Color(0xFFF2F6F4),
        );
      }
      final Color c = t.isIncome ? green : red;
      text(S.digits(dateFmt.format(t.timestamp)), left + 16, y + 6, width: 250, size: 22);
      text(t.note ?? '-', left + 270, y + 6, width: 400, size: 22);
      text(t.isIncome ? S.t('income') : S.t('expense'), left + 690, y + 6,
          width: 130, size: 22, color: c, weight: FontWeight.w700);
      text(Money.format(t.amount), left + 830, y + 6,
          width: 184, size: 22, color: c, weight: FontWeight.w700, align: TextAlign.right);
      y += 54;
    }

    text('${S.t('page')} ${S.digits('${page + 1}')} / ${S.digits('$pageCount')}', left,
        _h - 80,
        width: contentW,
        size: 20,
        color: const Color(0xFF5B6B66),
        align: TextAlign.center);

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(_w.toInt(), _h.toInt());
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
