import 'dart:typed_data';
import 'dart:ui' show Rect, Offset;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Utility that generates professional sample PDF documents on-the-fly.
class PdfGeneratorHelper {
  /// Generates a realistic sample multi-page business contract PDF.
  static Future<Uint8List> generateSampleDocument({
    String title = 'NON-DISCLOSURE AGREEMENT (NDA)',
    String company = 'Antigravity Technologies Inc.',
  }) async {
    final pdf = pw.Document();

    // Page 1: Agreement
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    company,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                  pw.Text(
                    'CONFIDENTIAL',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red800,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.blueGrey200),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'This Mutual Non-Disclosure Agreement ("Agreement") is entered into by and between the undersigned parties as of today, for the purpose of preventing the unauthorized disclosure of Confidential Information.',
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '1. Definition of Confidential Information',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'For purposes of this Agreement, "Confidential Information" shall include all information or material that has or could have commercial value or other utility in the business in which Disclosing Party is engaged.',
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '2. Obligations of Receiving Party',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Receiving Party shall hold and maintain the Confidential Information in strictest confidence for the sole and exclusive benefit of Disclosing Party. Receiving Party shall not, without prior written approval, use or disclose any Confidential Information to third parties.',
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Document ID: AGY-2026-PDF-001',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.Text('Page 1 of 2',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Page 2: Signatures and Stamp Block
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '3. Term and Termination',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'The non-disclosure provisions of this Agreement shall survive the termination of this Agreement and Receiving Party\'s duty to hold Confidential Information in confidence shall remain in effect for a period of five (5) years.',
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                '4. Execution & Signatures',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'IN WITNESS WHEREOF, the parties hereto have executed this Agreement as of the date first above written. Please sign and stamp below:',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          height: 70,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.grey400,
                              style: pw.BorderStyle.dashed,
                            ),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(6),
                            ),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              '[ Sign Here ]',
                              style: const pw.TextStyle(
                                color: PdfColors.grey500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Authorized Signature: Party A',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.Text('Date: _______________',
                            style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          height: 70,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.grey400,
                              style: pw.BorderStyle.dashed,
                            ),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(6),
                            ),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              '[ Sign Here ]',
                              style: const pw.TextStyle(
                                color: PdfColors.grey500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Authorized Signature: Party B',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.Text('Date: _______________',
                            style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Document ID: AGY-2026-PDF-001',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.Text('Page 2 of 2',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Generates a blank PDF document with the specified [pageCount].
  static Future<Uint8List> generateBlankDocument({
    int pageCount = 1,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final pdf = pw.Document();
    for (int i = 0; i < pageCount; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) => pw.SizedBox.expand(),
        ),
      );
    }
    return await pdf.save();
  }

  /// Generates a realistic sample PDF with interactive AcroForm fields
  /// (Text inputs, Checkbox, Radio buttons, Dropdown combo box).
  static Future<Uint8List> generateSampleFormDocument() async {
    final doc = sf.PdfDocument();
    final page = doc.pages.add();

    final titleFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 15, style: sf.PdfFontStyle.bold);
    final sectionFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 11, style: sf.PdfFontStyle.bold);
    final labelFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 10, style: sf.PdfFontStyle.regular);
    final blackBrush = sf.PdfSolidBrush(sf.PdfColor(30, 30, 30));
    final blueBrush = sf.PdfSolidBrush(sf.PdfColor(25, 118, 210));

    // Header
    page.graphics.drawString(
      'EMPLOYEE ONBOARDING & VERIFICATION FORM',
      titleFont,
      brush: blueBrush,
      bounds: const Rect.fromLTWH(50, 40, 500, 24),
    );

    page.graphics.drawString(
      'Please fill out all interactive form fields below (Input, Checkbox, Radio, Dropdown).',
      labelFont,
      brush: blackBrush,
      bounds: const Rect.fromLTWH(50, 68, 500, 18),
    );

    page.graphics.drawLine(
      sf.PdfPen(sf.PdfColor(200, 200, 200), width: 1.0),
      const Offset(50, 92),
      const Offset(545, 92),
    );

    // Section 1: Personal Details
    page.graphics.drawString('1. Personal Details', sectionFont, brush: blackBrush, bounds: const Rect.fromLTWH(50, 108, 200, 18));

    // Field: Full Name
    page.graphics.drawString('Full Name:', labelFont, brush: blackBrush, bounds: const Rect.fromLTWH(50, 134, 100, 18));
    final nameField = sf.PdfTextBoxField(page, 'fullName', const Rect.fromLTWH(160, 130, 300, 24));
    nameField.text = '';
    doc.form.fields.add(nameField);

    // Field: Email Address
    page.graphics.drawString('Email Address:', labelFont, brush: blackBrush, bounds: const Rect.fromLTWH(50, 168, 100, 18));
    final emailField = sf.PdfTextBoxField(page, 'email', const Rect.fromLTWH(160, 164, 300, 24));
    emailField.text = '';
    doc.form.fields.add(emailField);

    // Section 2: Role & Department (Dropdown)
    page.graphics.drawString('2. Role & Department', sectionFont, brush: blackBrush, bounds: const Rect.fromLTWH(50, 204, 200, 18));

    page.graphics.drawString('Department:', labelFont, brush: blackBrush, bounds: const Rect.fromLTWH(50, 230, 100, 18));
    final deptCombo = sf.PdfComboBoxField(page, 'department', const Rect.fromLTWH(160, 226, 220, 24));
    deptCombo.items.add(sf.PdfListFieldItem('Engineering', 'eng'));
    deptCombo.items.add(sf.PdfListFieldItem('Product & Design', 'design'));
    deptCombo.items.add(sf.PdfListFieldItem('Marketing & Sales', 'marketing'));
    deptCombo.items.add(sf.PdfListFieldItem('Operations & Finance', 'ops'));
    deptCombo.selectedIndex = 0;
    doc.form.fields.add(deptCombo);

    // Section 3: Employment Type (Radio buttons)
    page.graphics.drawString('3. Employment Status', sectionFont, brush: blackBrush, bounds: const Rect.fromLTWH(50, 268, 200, 18));

    final radioField = sf.PdfRadioButtonListField(page, 'employmentType');
    final r1 = sf.PdfRadioButtonListItem('Full-Time', const Rect.fromLTWH(160, 292, 16, 16));
    final r2 = sf.PdfRadioButtonListItem('Part-Time', const Rect.fromLTWH(260, 292, 16, 16));
    final r3 = sf.PdfRadioButtonListItem('Contractor', const Rect.fromLTWH(360, 292, 16, 16));
    radioField.items.add(r1);
    radioField.items.add(r2);
    radioField.items.add(r3);
    radioField.selectedIndex = 0;
    doc.form.fields.add(radioField);

    page.graphics.drawString('Full-Time', labelFont, brush: blackBrush, bounds: const Rect.fromLTWH(182, 293, 70, 16));
    page.graphics.drawString('Part-Time', labelFont, brush: blackBrush, bounds: const Rect.fromLTWH(282, 293, 70, 16));
    page.graphics.drawString('Contractor', labelFont, brush: blackBrush, bounds: const Rect.fromLTWH(382, 293, 80, 16));

    // Section 4: Terms & Agreement (Checkbox)
    page.graphics.drawString('4. Agreements & Confirmation', sectionFont, brush: blackBrush, bounds: const Rect.fromLTWH(50, 330, 200, 18));

    final checkField = sf.PdfCheckBoxField(page, 'agreeTerms', const Rect.fromLTWH(50, 354, 16, 16));
    checkField.isChecked = false;
    doc.form.fields.add(checkField);

    page.graphics.drawString(
      'I hereby confirm that the information provided is accurate and I agree to all terms.',
      labelFont,
      brush: blackBrush,
      bounds: const Rect.fromLTWH(74, 355, 450, 18),
    );

    // Section 5: Additional Notes (Multiline Text Input)
    page.graphics.drawString('Additional Notes / Special Instructions:', labelFont, brush: blackBrush, bounds: const Rect.fromLTWH(50, 390, 300, 18));
    final notesField = sf.PdfTextBoxField(page, 'notes', const Rect.fromLTWH(50, 412, 450, 60));
    notesField.multiline = true;
    notesField.text = '';
    doc.form.fields.add(notesField);

    final bytes = doc.saveSync();
    doc.dispose();
    return Uint8List.fromList(bytes);
  }
}
