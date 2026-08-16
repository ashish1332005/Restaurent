
import 'dart:async';
import 'dart:html' as html;

Future<void> printReceiptHtml(String receiptHtml, {String title = 'Receipt'}) async {
  html.document.getElementById('receipt-print-style')?.remove();
  html.document.getElementById('receipt-print-root')?.remove();

  final style = html.StyleElement()
    ..id = 'receipt-print-style'
    ..text = '''
@media print {
  @page { size: 80mm auto; margin: 4mm; }
  body * { visibility: hidden !important; }
  #receipt-print-root, #receipt-print-root * { visibility: visible !important; }
  #receipt-print-root { position: absolute !important; left: 0 !important; top: 0 !important; width: 80mm !important; }
}
#receipt-print-root {
  display: none;
  color: #111827;
  background: #fff;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
}
@media print { #receipt-print-root { display: block; } }
#receipt-print-root * { box-sizing: border-box; }
#receipt-print-root .receipt { width: 72mm; margin: 0 auto; padding: 8px; }
#receipt-print-root .center { text-align: center; }
#receipt-print-root .logo { display: inline-block; width: 46px; height: 46px; object-fit: cover; border-radius: 9px; margin-bottom: 6px; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
#receipt-print-root .brand { font-size: 16px; font-weight: 900; letter-spacing: .5px; }
#receipt-print-root .muted { color: #64748b; font-size: 10px; }
#receipt-print-root .line { border-top: 1px dashed #94a3b8; margin: 10px 0; }
#receipt-print-root .row { display: flex; justify-content: space-between; gap: 8px; font-size: 11px; margin: 4px 0; }
#receipt-print-root .item-name { flex: 1; }
#receipt-print-root .qty { width: 28px; text-align: center; }
#receipt-print-root .amt { width: 54px; text-align: right; }
#receipt-print-root .total { font-size: 15px; font-weight: 900; }
#receipt-print-root .thanks { margin-top: 12px; text-align: center; font-size: 11px; font-style: italic; }
''';

  final root = html.DivElement()
    ..id = 'receipt-print-root'
    ..setInnerHtml(
      receiptHtml,
      treeSanitizer: html.NodeTreeSanitizer.trusted,
    );

  html.document.head?.append(style);
  html.document.body?.append(root);
  html.window.print();
  await Future<void>.delayed(const Duration(milliseconds: 800));
  root.remove();
  style.remove();
}

