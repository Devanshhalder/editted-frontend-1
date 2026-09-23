import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/product.dart';

class BusinessReportService {
  static Future<File> createMonthlySalesReport({
    required String artisanName,
    required String businessName,
    required String pehchanId,
    required List<Product> products,
  }) async {
    final document = pw.Document();
    final totalInventory = products.fold<int>(
      0,
      (sum, product) => sum + product.price * product.stock,
    );
    final estimatedSales = products.fold<int>(
      0,
      (sum, product) => sum + product.price * (product.published ? 3 : 1),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'KarigarKart',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Monthly Income & Sales Certificate'),
          pw.SizedBox(height: 20),
          pw.Text('Artisan: $artisanName'),
          pw.Text('Business: $businessName'),
          pw.Text('Pehchan ID: ${pehchanId.isEmpty ? 'Not provided' : pehchanId}'),
          pw.Text('Period: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}'),
          pw.SizedBox(height: 18),
          pw.Table.fromTextArray(
            headers: const ['Product', 'Price', 'Stock', 'Status'],
            data: products
                .map(
                  (product) => [
                    product.title,
                    'Rs ${product.price}',
                    '${product.stock}',
                    product.published ? 'Live' : 'Draft',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text('Estimated monthly sales: Rs $estimatedSales'),
          pw.Text('Current inventory value: Rs $totalInventory'),
          pw.SizedBox(height: 28),
          pw.Text(
            'This document is an app-generated business record based on the local catalog data. It is not a government-issued certificate.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/karigarkart_monthly_sales_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await document.save());
    return file;
  }

  static Future<File> createCatalogPdf({
    required String artisanName,
    required String businessName,
    required String pehchanId,
    required List<Product> products,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          pw.Text(
            businessName,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Artisan: $artisanName'),
          pw.Text('Pehchan ID: ${pehchanId.isEmpty ? 'Not provided' : pehchanId}'),
          pw.SizedBox(height: 18),
          ...products.map(
            (product) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    product.title,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(product.category),
                  pw.Text('Retail: Rs ${product.price}  |  Wholesale: Rs ${(product.price * .85).round()}'),
                  pw.Text('Stock: ${product.stock}  |  ${product.published ? 'Live' : 'Draft'}'),
                  if (product.attributes.isNotEmpty)
                    pw.Text('Attributes: ${product.attributes.join(', ')}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/karigarkart_catalog_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await document.save());
    return file;
  }

  static Future<void> shareFile(File file, {required String title}) async {
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        files: [XFile(file.path)],
      ),
    );
  }
}
