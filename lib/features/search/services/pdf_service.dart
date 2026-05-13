import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/fsca_models.dart';
import '../../raf/models/raf_inquiry_model.dart';

class PdfService {
  static Future<Uint8List> generateClaimLetter({
    required EnquirerDetails enquirer,
    required TargetDetails target,
    required BenefitResult benefit,
  }) async {
    final pdf = pw.Document();
    
    final watermarkImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/gold_protea_watermark.png')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Positioned(
                bottom: -20,
                right: -20,
                child: pw.Opacity(
                  opacity: 0.1,
                  child: pw.Image(watermarkImage, width: 250),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Text('Formal Claim Inquiry', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
                  pw.SizedBox(height: 20),
                  pw.Text('To: ${benefit.administrator}'),
                  pw.Text('Regarding: ${benefit.fundName}'),
                  pw.SizedBox(height: 30),
                  pw.Text('Dear Sir/Madam,'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'I am writing to formally inquire about potential unclaimed benefits held by the aforementioned fund. '
                    'Below are the details of the individual in question:'
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Subject Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 10),
                        pw.Text('Surname: ${target.surname}'),
                        pw.Text('ID Number: ${target.idNumber}'),
                        pw.Text('Date of Birth: ${target.dateOfBirth.toString().split(' ')[0]}'),
                        if (target.employerName != null && target.employerName!.isNotEmpty)
                          pw.Text('Employer: ${target.employerName}'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Please find my contact details below for any correspondence regarding this matter:'
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Enquirer Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Name: ${enquirer.names} ${enquirer.surname}'),
                  pw.Text('Phone: ${enquirer.cellNumber}'),
                  pw.Text('Email: ${enquirer.email}'),
                  pw.SizedBox(height: 40),
                  pw.Text('Sincerely,'),
                  pw.SizedBox(height: 30),
                  pw.Text('_________________________'),
                  pw.Text('${enquirer.names} ${enquirer.surname}'),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateRafLetter({
    required RafInquiry inquiry,
  }) async {
    final pdf = pw.Document();

    final watermarkImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/gold_protea_watermark.png')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Positioned(
                bottom: 40,
                right: 40,
                child: pw.Opacity(
                  opacity: 0.1,
                  child: pw.Image(watermarkImage, width: 250),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('FORMAL RAF INQUIRY', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                          pw.Text('Claim Status & Information Request', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Reference: RAF-INQ-${DateTime.now().millisecondsSinceEpoch}', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 1.5, color: PdfColors.blueGrey900),
                  pw.SizedBox(height: 20),
                  pw.Text('To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Road Accident Fund (RAF)'),
                  pw.Text('Claim Inquiries Department'),
                  pw.SizedBox(height: 20),
                  pw.Text('Dear Sir/Madam,'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'I am writing to formally request an update and provide supplementary information regarding a claim with the Road Accident Fund. '
                    'Below are the comprehensive details pertaining to the claimant and the incident:'
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Section: Personal Details
                  _buildSectionHeader('1. CLAIMANT INFORMATION'),
                  _buildDetailRow('Full Name', inquiry.fullName),
                  _buildDetailRow('ID Number', inquiry.idNumber),
                  _buildDetailRow('Phone Number', inquiry.phoneNumber),
                  _buildDetailRow('Email', inquiry.email),
                  pw.SizedBox(height: 15),

                  // Section: Accident Details
                  _buildSectionHeader('2. ACCIDENT DETAILS'),
                  _buildDetailRow('Date of Accident', inquiry.accidentDate.toString().split(' ')[0]),
                  _buildDetailRow('Location', inquiry.accidentLocation),
                  if (inquiry.policeStation != null && inquiry.policeStation!.isNotEmpty) 
                    _buildDetailRow('Police Station', inquiry.policeStation!),
                  if (inquiry.caseNumber != null && inquiry.caseNumber!.isNotEmpty) 
                    _buildDetailRow('CAS / Case No.', inquiry.caseNumber!),
                  pw.SizedBox(height: 15),

                  // Section: Medical Details
                  if ((inquiry.hospitalName != null && inquiry.hospitalName!.isNotEmpty) || 
                      (inquiry.injuryDescription != null && inquiry.injuryDescription!.isNotEmpty)) ...[
                    _buildSectionHeader('3. MEDICAL & INJURIES'),
                    if (inquiry.hospitalName != null && inquiry.hospitalName!.isNotEmpty) 
                      _buildDetailRow('Hospital Name', inquiry.hospitalName!),
                    if (inquiry.treatmentDate != null) 
                      _buildDetailRow('Treatment Date', inquiry.treatmentDate!.toString().split(' ')[0]),
                    if (inquiry.injuryDescription != null && inquiry.injuryDescription!.isNotEmpty) 
                      _buildDetailRow('Injury Summary', inquiry.injuryDescription!),
                    pw.SizedBox(height: 15),
                  ],

                  // Section: Employment Details
                  if (inquiry.employerName != null && inquiry.employerName!.isNotEmpty) ...[
                    _buildSectionHeader('4. EMPLOYMENT IMPACT'),
                    _buildDetailRow('Employer', inquiry.employerName!),
                    if (inquiry.daysMissedWork != null && inquiry.daysMissedWork!.isNotEmpty) 
                      _buildDetailRow('Period of Absence', '${inquiry.daysMissedWork} days'),
                    pw.SizedBox(height: 15),
                  ],

                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Please acknowledge receipt of this inquiry and provide an update on the current status of the claim at your earliest convenience.'
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text('Sincerely,'),
                  pw.SizedBox(height: 40),
                  pw.Text('_________________________'),
                  pw.Text(inquiry.fullName),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(5),
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 120, child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }
}
