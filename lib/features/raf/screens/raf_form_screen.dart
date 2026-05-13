import 'package:flutter/material.dart';
import '../../search/services/pdf_service.dart';
import '../../search/screens/pdf_preview_screen.dart';
import '../models/raf_inquiry_model.dart';
import '../../../core/theme/app_theme.dart';

class RafFormScreen extends StatefulWidget {
  const RafFormScreen({super.key});

  @override
  State<RafFormScreen> createState() => _RafFormScreenState();
}

class _RafFormScreenState extends State<RafFormScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Personal Controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Accident Controllers
  final _locationController = TextEditingController();
  final _policeController = TextEditingController();
  final _caseController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _accidentDate;

  // Medical Controllers
  final _hospitalController = TextEditingController();
  final _injuryController = TextEditingController();
  DateTime? _treatmentDate;

  // Employment Controllers
  final _employerController = TextEditingController();
  final _daysController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _policeController.dispose();
    _caseController.dispose();
    _descriptionController.dispose();
    _hospitalController.dispose();
    _injuryController.dispose();
    _employerController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RAF Inquiry Wizard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep += 1);
            } else {
              _generatePdf();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 3 ? 'GENERATE LETTER' : 'NEXT'),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('BACK', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Personal Details'),
              subtitle: const Text('Claimant identification'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  _buildTextField(_nameController, 'Full Name', Icons.person),
                  _buildTextField(_idController, 'ID Number', Icons.badge, maxLength: 13),
                  _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                  _buildTextField(_emailController, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
                ],
              ),
            ),
            Step(
              title: const Text('Accident Information'),
              subtitle: const Text('Where and when it happened'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  _buildDatePicker(
                    context, 
                    'Accident Date', 
                    _accidentDate, 
                    (date) => setState(() => _accidentDate = date)
                  ),
                  _buildTextField(_locationController, 'Accident Location', Icons.location_on),
                  _buildTextField(_policeController, 'Police Station (Optional)', Icons.local_police),
                  _buildTextField(_caseController, 'Case Number (Optional)', Icons.description),
                  _buildTextField(_descriptionController, 'Brief Description', Icons.notes, maxLines: 3),
                ],
              ),
            ),
            Step(
              title: const Text('Medical & Injuries'),
              subtitle: const Text('Hospital and treatment'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  _buildTextField(_hospitalController, 'Hospital Name', Icons.local_hospital),
                  _buildDatePicker(
                    context, 
                    'First Treatment Date', 
                    _treatmentDate, 
                    (date) => setState(() => _treatmentDate = date)
                  ),
                  _buildTextField(_injuryController, 'Description of Injuries', Icons.healing, maxLines: 2),
                ],
              ),
            ),
            Step(
              title: const Text('Employment Impact'),
              subtitle: const Text('Loss of income details'),
              isActive: _currentStep >= 3,
              state: _currentStep == 3 ? StepState.editing : StepState.indexed,
              content: Column(
                children: [
                  _buildTextField(_employerController, 'Employer Name', Icons.work),
                  _buildTextField(_daysController, 'Days Missed from Work', Icons.calendar_today, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  const Text(
                    'Note: This information helps the RAF assess the financial impact of your claim.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(1990),
            lastDate: DateTime.now(),
          );
          if (date != null) onDateSelected(date);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today, size: 20),
            border: const OutlineInputBorder(),
          ),
          child: Text(
            selectedDate == null ? 'Select Date' : selectedDate.toString().split(' ')[0],
            style: TextStyle(color: selectedDate == null ? Colors.grey : Colors.black),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePdf() async {
    // Basic validation for mandatory fields in first steps
    if (_nameController.text.isEmpty || _idController.text.isEmpty || _accidentDate == null || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in at least Personal and Accident details.')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    final inquiry = RafInquiry(
      fullName: _nameController.text,
      idNumber: _idController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text,
      accidentDate: _accidentDate!,
      accidentLocation: _locationController.text,
      policeStation: _policeController.text,
      caseNumber: _caseController.text,
      accidentDescription: _descriptionController.text,
      hospitalName: _hospitalController.text,
      injuryDescription: _injuryController.text,
      treatmentDate: _treatmentDate,
      employerName: _employerController.text,
      daysMissedWork: _daysController.text,
    );

    final pdfData = await PdfService.generateRafLetter(inquiry: inquiry);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(pdfData: pdfData, title: 'RAF Inquiry Preview'),
        ),
      );
    }
  }
}
