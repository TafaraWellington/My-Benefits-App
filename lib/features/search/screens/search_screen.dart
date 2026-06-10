import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../payment/screens/paywall_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../models/fsca_models.dart';
import '../providers/search_provider.dart';
import '../../payment/providers/credit_provider.dart';
import '../../../core/services/supabase_service.dart';
import 'claim_assistant_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  int _currentStep = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _cellController = TextEditingController();
  final _emailController = TextEditingController();
  bool _consent = false;

  // Step 2 Controllers
  final _targetIdController = TextEditingController();
  final _targetSurnameController = TextEditingController();
  DateTime? _selectedDob;

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(fscaSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unclaimed Benefits Search'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${ref.watch(creditProvider).credits} Credits',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: searchState.when(
        data: (searchData) {
          if (searchData.results.isNotEmpty && searchData.enquirer != null && searchData.target != null) {
            return _buildResultsList(searchData.results, searchData.enquirer!, searchData.target!);
          }

          return _buildStepper();
        },
        loading: () => Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 6, color: AppColors.accent),
                    const SizedBox(height: 24),
                    Text('Querying FSCA Database...', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Checking 1,200+ financial institutions', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text('Something went wrong', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(fscaSearchProvider),
                child: const Text('RETRY SEARCH'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Stepper(
      type: StepperType.horizontal,
      currentStep: _currentStep,
      onStepContinue: () {
        if (_currentStep == 0) {
          if (_formKey1.currentState!.validate() && _consent) {
            setState(() => _currentStep++);
          } else if (!_consent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please provide consent to proceed.')),
            );
          }
        } else {
          if (_formKey2.currentState!.validate() && _selectedDob != null) {
            _submitSearch();
          }
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      steps: [
        Step(
          title: const Text('Enquirer'),
          isActive: _currentStep >= 0,
          content: Form(
            key: _formKey1,
            child: Column(
              children: [
                _buildTextField(_nameController, 'Names', Icons.person),
                _buildTextField(_surnameController, 'Surname', Icons.person_outline),
                _buildTextField(_cellController, 'Cell Number', Icons.phone, keyboardType: TextInputType.phone),
                _buildTextField(_emailController, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
                CheckboxListTile(
                  title: const Text('I consent to FSCA processing my data'),
                  value: _consent,
                  onChanged: (val) => setState(() => _consent = val!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Did you know?',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Over R88 billion to R90 billion in unclaimed financial assets exists in South Africa, largely comprising retirement benefits.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Who is entitled to these funds?',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      _buildBulletPoint('Former Employees', 'Individuals who contributed to a retirement fund but did not claim their benefits (withdrawal, retirement, or retrenchment) when leaving a company.'),
                      _buildBulletPoint('Beneficiaries', 'Dependents or nominees of a deceased member who was not paid their full benefit.'),
                      _buildBulletPoint('Non-member Spouses', 'People entitled to a portion of a benefit, often following a divorce.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Target'),
          isActive: _currentStep >= 1,
          content: Form(
            key: _formKey2,
            child: Column(
              children: [
                _buildTextField(_targetIdController, 'RSA ID Number', Icons.badge),
                _buildTextField(_targetSurnameController, 'Target Surname', Icons.person),
                ListTile(
                  title: Text(_selectedDob == null 
                      ? 'Select Date of Birth' 
                      : 'DOB: ${_selectedDob!.toLocal()}'.split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime(1980),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _selectedDob = date);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(Icons.circle, size: 8, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: keyboardType,
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildResultsList(List<BenefitResult> results, EnquirerDetails enquirer, TargetDetails target) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 8),
              Text('${results.length} Potential Matches Found', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () => ref.read(fscaSearchProvider.notifier).reset(),
                child: const Text('NEW SEARCH'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(result.fundName, style: Theme.of(context).textTheme.titleLarge),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(result.status, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildResultRow('Administrator', result.administrator),
                        const SizedBox(height: 12),
                        _buildResultRow('Contact Details', result.contactDetails),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('START CLAIM PROCESS'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClaimAssistantScreen(
                                    result: result,
                                    enquirer: enquirer,
                                    target: target,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  void _submitSearch() {
    final creditState = ref.read(creditProvider);
    final creditNotifier = ref.read(creditProvider.notifier);
    
    // Free users are only allowed to check NSFAS and RAF.
    // FSCA Search (this screen) requires a paid membership.
    if (creditState.tier == MembershipTier.free) {
      showDialog(
        context: context,
        builder: (context) => PaywallScreen(),
      );
      return;
    }

    if (creditState.credits <= 0) {
      showDialog(
        context: context,
        builder: (context) => PaywallScreen(),
      );
      return;
    }


    final enquirer = EnquirerDetails(
      names: _nameController.text,
      surname: _surnameController.text,
      cellNumber: _cellController.text,
      email: _emailController.text,
      consentGiven: _consent,
    );
    final target = TargetDetails(
      idNumber: _targetIdController.text,
      dateOfBirth: _selectedDob!,
      surname: _targetSurnameController.text,
    );

    ref.read(fscaSearchProvider.notifier).performSearch(
      enquirer: enquirer,
      target: target,
    );

    // Deduct one credit
    creditNotifier.useCredit();
    
    // Save to Supabase
    ref.read(supabaseServiceProvider).saveSearch(
      'FSCA Search: ${target.idNumber} (${target.surname})',
      'Pending',
    );
  }
}
