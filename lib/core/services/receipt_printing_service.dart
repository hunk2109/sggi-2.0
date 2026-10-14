import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/pos/models/product_model.dart';
import '../../features/settings/models/gym_settings_model.dart';

class ReceiptPrintingService {
  static final _currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);
  static final _dateFormat = DateFormat('dd/MM/yyyy hh:mm a');
  static final _dateOnlyFormat = DateFormat('dd/MM/yyyy');

  /// Resuelve el formato de página según la configuración seleccionada
  static PdfPageFormat _resolvePaperFormat(String paperSize) {
    switch (paperSize.toLowerCase().trim()) {
      case '58mm':
        return const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 2.5 * PdfPageFormat.mm);
      case '70mm':
      case '72mm':
        return const PdfPageFormat(70 * PdfPageFormat.mm, double.infinity, marginAll: 3.5 * PdfPageFormat.mm);
      case 'a4':
        return PdfPageFormat.a4.copyWith(
          marginTop: 15 * PdfPageFormat.mm,
          marginBottom: 15 * PdfPageFormat.mm,
          marginLeft: 15 * PdfPageFormat.mm,
          marginRight: 15 * PdfPageFormat.mm,
        );
      case '80mm':
      default:
        return const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm);
    }
  }

  /// Imprimir Ticket / Factura de Venta POS con el diálogo de impresión de Windows
  static Future<bool> printSaleReceipt({
    required List<CartItemModel> items,
    required double total,
    required double subtotal,
    required double discount,
    required String paymentMethod,
    required double amountReceived,
    required double change,
    required String customerName,
    String? saleId,
    GymSettingsModel? gymSettings,
  }) async {
    final doc = pw.Document();

    final gymName = gymSettings?.gymName ?? 'GIMNASIO';
    final rnc = gymSettings?.rnc;
    final address = gymSettings?.address;
    final phone = gymSettings?.phone;
    final email = gymSettings?.email;
    final paperSize = (gymSettings?.ticketPaperSize ?? '80mm').toLowerCase().trim();
    final pageFormat = _resolvePaperFormat(paperSize);

    final ticketNumber = saleId != null && saleId.isNotEmpty
        ? (saleId.length > 8 ? saleId.substring(0, 8).toUpperCase() : saleId.toUpperCase())
        : DateFormat('yyMMddHHmm').format(DateTime.now());

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    if (paperSize == 'a4') {
      // ========= FORMATO A4 (PÁGINA COMPLETA) =========
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Cabecera A4
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(gymName.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blueGrey800)),
                        if (rnc != null && rnc.isNotEmpty) pw.Text('RNC: $rnc', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        if (address != null && address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        if (phone != null && phone.isNotEmpty) pw.Text('Tel: $phone', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        if (email != null && email.isNotEmpty) pw.Text('Email: $email', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('COMPROBANTE DE VENTA', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blueGrey900)),
                          pw.SizedBox(height: 4),
                          pw.Text('No. #$ticketNumber', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blue700)),
                          pw.Text('Fecha: ${_dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.Text('Cajero: Caja Activa', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Datos del Cliente A4
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey200),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('Cliente: ', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.Text(customerName, style: const pw.TextStyle(fontSize: 10)),
                      pw.Spacer(),
                      pw.Text('Método de Pago: ', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.Text(_translatePaymentMethod(paymentMethod), style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // Tabla de Artículos A4
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(5),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildTableHeaderCell('DESCRIPCIÓN', fontBold, pw.TextAlign.left),
                        _buildTableHeaderCell('CANT', fontBold, pw.TextAlign.center),
                        _buildTableHeaderCell('PRECIO UNITARIO', fontBold, pw.TextAlign.right),
                        _buildTableHeaderCell('TOTAL', fontBold, pw.TextAlign.right),
                      ],
                    ),
                    ...items.map((item) {
                      return pw.TableRow(
                        children: [
                          _buildTableCell(item.product.name, pw.TextAlign.left),
                          _buildTableCell('${item.quantity}', pw.TextAlign.center),
                          _buildTableCell(_currencyFormat.format(item.unitPrice), pw.TextAlign.right),
                          _buildTableCell(_currencyFormat.format(item.subtotal), pw.TextAlign.right, fontBold),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Resumen de Totales A4
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 250,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        children: [
                          _buildA4SummaryRow('Subtotal:', _currencyFormat.format(subtotal)),
                          if (discount > 0)
                            _buildA4SummaryRow('Descuento:', '- ${_currencyFormat.format(discount)}', fontBold),
                          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('TOTAL NETO:', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blueGrey900)),
                              pw.Text(_currencyFormat.format(total), style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue700)),
                            ],
                          ),
                          if (paymentMethod.toLowerCase() == 'cash' && amountReceived > 0) ...[
                            pw.SizedBox(height: 4),
                            _buildA4SummaryRow('Efectivo Recibido:', _currencyFormat.format(amountReceived)),
                            _buildA4SummaryRow('Cambio / Devuelta:', _currencyFormat.format(change), fontBold),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Firmas y Pie A4
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSignatureLine('Entregado por (Cajero)', fontBold),
                    _buildSignatureLine('Recibido Conforme (Cliente)', fontBold),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    '¡Gracias por su compra! Conserve este comprobante para cualquier reclamación.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'SGGI 2.0 - Gestión Deportiva Integral',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      // ========= FORMATO TÉRMICO (80mm, 70mm, 58mm) =========
      final is58 = paperSize == '58mm';
      final is70 = paperSize == '70mm' || paperSize == '72mm';

      final gymTitleSize = is58 ? 9.5 : (is70 ? 10.5 : 11.5);
      final subtitleSize = is58 ? 6.5 : (is70 ? 7.0 : 7.5);
      final docTitleSize = is58 ? 8.0 : (is70 ? 8.5 : 9.5);
      final bodySize = is58 ? 6.5 : (is70 ? 7.0 : 7.5);
      final totalLabelSize = is58 ? 8.5 : (is70 ? 9.5 : 10.5);
      final totalValueSize = is58 ? 9.5 : (is70 ? 10.5 : 11.5);
      final footerSize = is58 ? 6.0 : (is70 ? 6.5 : 7.0);

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ENCABEZADO
                pw.Center(
                  child: pw.Text(
                    gymName.toUpperCase(),
                    style: pw.TextStyle(font: fontBold, fontSize: gymTitleSize),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                if (rnc != null && rnc.isNotEmpty)
                  pw.Center(child: pw.Text('RNC: $rnc', style: pw.TextStyle(fontSize: subtitleSize))),
                if (address != null && address.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      address,
                      style: pw.TextStyle(fontSize: subtitleSize),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                if (phone != null && phone.isNotEmpty)
                  pw.Center(child: pw.Text('Tel: $phone', style: pw.TextStyle(fontSize: subtitleSize))),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 2),

                // DATOS DEL TICKET
                pw.Center(
                  child: pw.Text(
                    'COMPROBANTE DE VENTA',
                    style: pw.TextStyle(font: fontBold, fontSize: docTitleSize),
                  ),
                ),
                pw.SizedBox(height: 3),
                _buildRowText('Ticket No:', '#$ticketNumber', bodySize, fontBold),
                _buildRowText('Fecha:', _dateFormat.format(DateTime.now()), bodySize),
                _buildRowText('Cliente:', customerName, bodySize),
                _buildRowText('Cajero:', 'Caja Activa', bodySize),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 2),

                // ENCABEZADO DE TABLA DE PRODUCTOS
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text('DESCRIPCIÓN', style: pw.TextStyle(font: fontBold, fontSize: bodySize)),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text('CANT', style: pw.TextStyle(font: fontBold, fontSize: bodySize), textAlign: pw.TextAlign.center),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('PRECIO', style: pw.TextStyle(font: fontBold, fontSize: bodySize), textAlign: pw.TextAlign.right),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('TOTAL', style: pw.TextStyle(font: fontBold, fontSize: bodySize), textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 2),

                // LISTA DE ARTÍCULOS
                ...items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(item.product.name, style: pw.TextStyle(fontSize: bodySize)),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text('${item.quantity}', style: pw.TextStyle(fontSize: bodySize), textAlign: pw.TextAlign.center),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(_currencyFormat.format(item.unitPrice), style: pw.TextStyle(fontSize: bodySize), textAlign: pw.TextAlign.right),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(_currencyFormat.format(item.subtotal), style: pw.TextStyle(font: fontBold, fontSize: bodySize), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 2),

                // TOTALES
                _buildRowText('Subtotal:', _currencyFormat.format(subtotal), bodySize),
                if (discount > 0)
                  _buildRowText('Descuento:', '- ${_currencyFormat.format(discount)}', bodySize, fontBold),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL A PAGAR:', style: pw.TextStyle(font: fontBold, fontSize: totalLabelSize)),
                    pw.Text(_currencyFormat.format(total), style: pw.TextStyle(font: fontBold, fontSize: totalValueSize)),
                  ],
                ),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 2),

                // PAGO
                _buildRowText('Método de Pago:', _translatePaymentMethod(paymentMethod), bodySize),
                if (paymentMethod.toLowerCase() == 'cash' && amountReceived > 0) ...[
                  _buildRowText('Efectivo Recibido:', _currencyFormat.format(amountReceived), bodySize),
                  _buildRowText('Cambio:', _currencyFormat.format(change), bodySize, fontBold),
                ],

                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 4),

                // PIE DE PÁGINA
                pw.Center(
                  child: pw.Text(
                    '¡GRACIAS POR SU COMPRA!',
                    style: pw.TextStyle(font: fontBold, fontSize: footerSize + 1),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    'Conserve este comprobante para cualquier reclamación.',
                    style: pw.TextStyle(fontSize: footerSize),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    'SGGI 2.0 - Gestión Deportiva',
                    style: pw.TextStyle(fontSize: footerSize - 0.5, color: PdfColors.grey700),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Abrir diálogo de impresión nativo de Windows
    return await Printing.layoutPdf(
      name: 'Ticket_Venta_$ticketNumber',
      format: pageFormat,
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  /// Imprimir Recibo Formal de Pago de Membresía con el diálogo de impresión de Windows
  static Future<bool> printMembershipReceipt({
    required String memberName,
    required String displayCode,
    required String planName,
    required double amountPaid,
    required String paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    String? receiptNumber,
    String? promotionCode,
    num? discountPercentage,
    double? originalPlanPrice,
    GymSettingsModel? gymSettings,
    String? cashierName,
  }) async {
    final doc = pw.Document();

    final gymName = gymSettings?.gymName ?? 'GIMNASIO';
    final rnc = gymSettings?.rnc;
    final address = gymSettings?.address;
    final phone = gymSettings?.phone;
    final email = gymSettings?.email;
    final paperSize = (gymSettings?.ticketPaperSize ?? '80mm').toLowerCase().trim();
    final pageFormat = _resolvePaperFormat(paperSize);

    final receiptCode = receiptNumber != null && receiptNumber.isNotEmpty
        ? (receiptNumber.length > 10 ? receiptNumber.substring(0, 10).toUpperCase() : receiptNumber.toUpperCase())
        : DateFormat('yyMMddHHmm').format(DateTime.now());

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    if (paperSize == 'a4') {
      // ========= FORMATO A4 (PÁGINA COMPLETA MEMBRESÍA) =========
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Cabecera Institucional
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(gymName.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blueGrey800)),
                        if (rnc != null && rnc.isNotEmpty) pw.Text('RNC: $rnc', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        if (address != null && address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        if (phone != null && phone.isNotEmpty) pw.Text('Tel: $phone', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        if (email != null && email.isNotEmpty) pw.Text('Email: $email', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.green300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        color: PdfColors.green50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('RECIBO DE PAGO DE MEMBRESÍA', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.green900)),
                          pw.SizedBox(height: 4),
                          pw.Text('No. #$receiptCode', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.green800)),
                          pw.Text('Fecha: ${_dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.Text('Atendido por: ${cashierName ?? 'Recepción'}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Cuadro Datos del Socio
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('DATOS DEL SOCIO', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
                            pw.SizedBox(height: 4),
                            pw.Text(memberName, style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blueGrey900)),
                            pw.Text('Código de Socio: $displayCode', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.green700,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
                        ),
                        child: pw.Text('PAGO COMPLETADO', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white)),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Tabla Detalle del Plan y Fechas
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(4),
                    1: const pw.FlexColumnWidth(2.5),
                    2: const pw.FlexColumnWidth(2.5),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildTableHeaderCell('PLAN / CONCEPTO', fontBold, pw.TextAlign.left),
                        _buildTableHeaderCell('VÁLIDO DESDE', fontBold, pw.TextAlign.center),
                        _buildTableHeaderCell('HASTA / VENCE', fontBold, pw.TextAlign.center),
                        _buildTableHeaderCell('MONTO COBRADO', fontBold, pw.TextAlign.right),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(planName, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                              if (promotionCode != null && promotionCode.isNotEmpty)
                                pw.Text('Promoción: $promotionCode (${discountPercentage ?? 0}% OFF)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.green700)),
                              if (originalPlanPrice != null && originalPlanPrice > amountPaid)
                                pw.Text('Precio regular: ${_currencyFormat.format(originalPlanPrice)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            ],
                          ),
                        ),
                        _buildTableCell(startDate != null ? _dateOnlyFormat.format(startDate) : '-', pw.TextAlign.center),
                        _buildTableCell(endDate != null ? _dateOnlyFormat.format(endDate) : '-', pw.TextAlign.center, fontBold),
                        _buildTableCell(_currencyFormat.format(amountPaid), pw.TextAlign.right, fontBold),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Resumen de Cobro A4
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 250,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        children: [
                          _buildA4SummaryRow('Método de Pago:', _translatePaymentMethod(paymentMethod)),
                          if (originalPlanPrice != null && originalPlanPrice > amountPaid)
                            _buildA4SummaryRow('Precio Regular:', _currencyFormat.format(originalPlanPrice)),
                          if (promotionCode != null && promotionCode.isNotEmpty)
                            _buildA4SummaryRow('Descuento Cupón:', '- ${_currencyFormat.format(originalPlanPrice! - amountPaid)}', fontBold),
                          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('TOTAL PAGADO:', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.green900)),
                              pw.Text(_currencyFormat.format(amountPaid), style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.green800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Firmas A4
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSignatureLine('Recepción / Cobrador', fontBold),
                    _buildSignatureLine('Firma del Socio', fontBold),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'El acceso a las instalaciones y clases del gimnasio está sujeto a la vigencia y condiciones del plan contratado.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'SGGI 2.0 - Gestión Deportiva Integral',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      // ========= FORMATO TÉRMICO (80mm, 70mm, 58mm) =========
      final is58 = paperSize == '58mm';
      final is70 = paperSize == '70mm' || paperSize == '72mm';

      final gymTitleSize = is58 ? 9.5 : (is70 ? 10.5 : 11.5);
      final subtitleSize = is58 ? 6.5 : (is70 ? 7.0 : 7.5);
      final docTitleSize = is58 ? 8.0 : (is70 ? 8.5 : 9.5);
      final bodySize = is58 ? 6.5 : (is70 ? 7.0 : 7.5);
      final sectionTitleSize = is58 ? 7.0 : (is70 ? 7.5 : 8.0);
      final totalLabelSize = is58 ? 8.5 : (is70 ? 9.5 : 10.5);
      final totalValueSize = is58 ? 9.5 : (is70 ? 10.5 : 11.5);
      final footerSize = is58 ? 6.0 : (is70 ? 6.5 : 7.0);

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ENCABEZADO GIMNASIO
                pw.Center(
                  child: pw.Text(
                    gymName.toUpperCase(),
                    style: pw.TextStyle(font: fontBold, fontSize: gymTitleSize),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                if (rnc != null && rnc.isNotEmpty)
                  pw.Center(child: pw.Text('RNC: $rnc', style: pw.TextStyle(fontSize: subtitleSize))),
                if (address != null && address.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      address,
                      style: pw.TextStyle(fontSize: subtitleSize),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                if (phone != null && phone.isNotEmpty)
                  pw.Center(child: pw.Text('Tel: $phone', style: pw.TextStyle(fontSize: subtitleSize))),
                if (email != null && email.isNotEmpty)
                  pw.Center(child: pw.Text('Email: $email', style: pw.TextStyle(fontSize: subtitleSize))),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 2),

                // TÍTULO DEL DOCUMENTO
                pw.Center(
                  child: pw.Text(
                    'RECIBO DE PAGO DE MEMBRESÍA',
                    style: pw.TextStyle(font: fontBold, fontSize: docTitleSize),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'COMPROBANTE OFICIAL DE INGRESO',
                    style: pw.TextStyle(fontSize: subtitleSize - 0.5, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 3),
                _buildRowText('Recibo No:', '#$receiptCode', bodySize, fontBold),
                _buildRowText('Fecha Emisión:', _dateFormat.format(DateTime.now()), bodySize),
                _buildRowText('Cajero/Recepción:', cashierName ?? 'Recepción', bodySize),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 2),

                // DATOS DEL SOCIO
                pw.Text('DATOS DEL SOCIO:', style: pw.TextStyle(font: fontBold, fontSize: sectionTitleSize)),
                pw.SizedBox(height: 1),
                _buildRowText('Nombre:', memberName, bodySize, fontBold),
                _buildRowText('Código / ID:', displayCode, bodySize),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 2),

                // DETALLES DE LA MEMBRESÍA
                pw.Text('DETALLE DEL PLAN / CUOTA:', style: pw.TextStyle(font: fontBold, fontSize: sectionTitleSize)),
                pw.SizedBox(height: 1),
                _buildRowText('Plan Asignado:', planName, bodySize, fontBold),
                if (startDate != null)
                  _buildRowText('Fecha de Inicio:', _dateOnlyFormat.format(startDate), bodySize),
                if (endDate != null)
                  _buildRowText('Vencimiento:', _dateOnlyFormat.format(endDate), bodySize, fontBold),

                if (originalPlanPrice != null && originalPlanPrice > amountPaid) ...[
                  _buildRowText('Precio regular:', _currencyFormat.format(originalPlanPrice), bodySize),
                ],
                if (promotionCode != null && promotionCode.isNotEmpty) ...[
                  _buildRowText(
                    'Cupón Aplicado:',
                    '$promotionCode (${discountPercentage ?? 0}% OFF)',
                    bodySize,
                    fontBold,
                  ),
                ],

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 2),

                // TOTAL COBRADO
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL PAGADO:', style: pw.TextStyle(font: fontBold, fontSize: totalLabelSize)),
                    pw.Text(_currencyFormat.format(amountPaid), style: pw.TextStyle(font: fontBold, fontSize: totalValueSize)),
                  ],
                ),
                pw.SizedBox(height: 2),
                _buildRowText('Método de Pago:', _translatePaymentMethod(paymentMethod), bodySize),
                _buildRowText('Estado del Pago:', 'COMPLETADO / COBRADO', bodySize, fontBold),

                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 4),

                // POLÍTICAS & PIE
                pw.Center(
                  child: pw.Text(
                    '¡GRACIAS POR ENTRENAR CON NOSOTROS!',
                    style: pw.TextStyle(font: fontBold, fontSize: footerSize + 1),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    'El acceso al gimnasio está sujeto a la vigencia del plan.',
                    style: pw.TextStyle(fontSize: footerSize),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    'SGGI 2.0 - Gestión Deportiva Integral',
                    style: pw.TextStyle(fontSize: footerSize - 0.5, color: PdfColors.grey700),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Abrir diálogo de impresión nativo de Windows
    return await Printing.layoutPdf(
      name: 'Recibo_Membresia_$receiptCode',
      format: pageFormat,
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  static pw.Widget _buildRowText(String label, String value, double fontSize, [pw.Font? boldFont]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, color: PdfColors.grey800)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              font: boldFont,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, pw.Font boldFont, pw.TextAlign align) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.blueGrey900),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, pw.TextAlign align, [pw.Font? boldFont]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: boldFont, fontSize: 9),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildA4SummaryRow(String label, String value, [pw.Font? boldFont]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureLine(String label, pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Container(width: 160, height: 1, color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.grey700)),
      ],
    );
  }

  static String _translatePaymentMethod(String m) {
    switch (m.toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      case 'credit_balance':
        return 'Saldo a Favor';
      case 'pending':
        return 'Pendiente';
      default:
        return m;
    }
  }
}
