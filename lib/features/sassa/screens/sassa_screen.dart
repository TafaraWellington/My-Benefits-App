import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sassa_api_service.dart';

class SassaScreen extends ConsumerStatefulWidget {
  const SassaScreen({super.key});

  @override
  ConsumerState<SassaScreen> createState() => _SassaScreenState();
}

class _SassaScreenState extends ConsumerState<SassaScreen> {
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  final _formKeyOtp = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isTracking = false;
  Map<String, dynamic>? _statusResult;

  @override
  void initState() {
    super.initState();
    _loadTrackingStatus();
  }

  @override
  void dispose() {
    _idController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadTrackingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final trackedId = prefs.getString('tracked_sassa_id');
    final trackedPhone = prefs.getString('tracked_sassa_phone');
    if (mounted && trackedId != null && trackedId.isNotEmpty) {
      setState(() {
        _isTracking = true;
        _idController.text = trackedId;
        if (trackedPhone != null) _phoneController.text = trackedPhone;
      });
    }
  }

  Future<void> _toggleTracking(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      if (_idController.text.length != 13 || _phoneController.text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid ID and Phone to track.')),
          );
        }
        return;
      }
      await prefs.setString('tracked_sassa_id', _idController.text);
      await prefs.setString('tracked_sassa_phone', _phoneController.text);
      if (_statusResult != null && _statusResult!['outcome'] != null) {
        await prefs.setString('last_sassa_status', _statusResult!['outcome']);
      }
      
      await BackgroundService.registerSassaTask();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status tracking enabled. You will be notified of changes.')),
        );
      }
    } else {
      await prefs.remove('tracked_sassa_id');
      await prefs.remove('tracked_sassa_phone');
      await prefs.remove('last_sassa_status');
      await BackgroundService.cancelSassaTask();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status tracking disabled.')),
        );
      }
    }
    setState(() {
      _isTracking = value;
    });
  }

  void _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final sassaService = ref.read(sassaApiServiceProvider);
      await sassaService.sendOtp(
        idNumber: _idController.text,
        phoneNumber: _phoneController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A One-Time PIN (OTP) has been sent to your registered cellphone number.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _verifyOtpAndCheckStatus() async {
    if (!_formKeyOtp.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final sassaService = ref.read(sassaApiServiceProvider);
      final result = await sassaService.verifyOtpAndCheckStatus(
        idNumber: _idController.text,
        phoneNumber: _phoneController.text,
        otp: _otpController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusResult = result;
        });
        
        final prefs = await SharedPreferences.getInstance();
        if (_statusResult != null && _statusResult!['outcome'] != null) {
          await prefs.setString('last_sassa_status', _statusResult!['outcome']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _resetStatusCheck() {
    setState(() {
      _otpSent = false;
      _statusResult = null;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SASSA SRD Status')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildCurrentStateWidget(),
        ),
      ),
    );
  }

  Widget _buildCurrentStateWidget() {
    if (_statusResult != null) {
      return _buildStatusView();
    } else if (_otpSent) {
      return _buildOtpVerificationView();
    } else {
      return _buildInitialInputView();
    }
  }

  Widget _buildInitialInputView() {
    return Column(
      key: const ValueKey('sassa_input_view'),
      children: [
        const Icon(Icons.account_balance, size: 80, color: Colors.blueGrey),
        const SizedBox(height: 24),
        Text(
          'Check Your Grant Status',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your details below to request a secure One-Time PIN (OTP) and check your Social Relief of Distress (SRD) status.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'RSA ID Number',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.length != 13 ? 'Enter a valid 13-digit ID' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Registered Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Cellphone number is required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('SEND ONE-TIME PIN (OTP)'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpVerificationView() {
    final obscuredPhone = _phoneController.text.length > 4
        ? '******${_phoneController.text.substring(_phoneController.text.length - 4)}'
        : _phoneController.text;

    return Column(
      key: const ValueKey('sassa_otp_view'),
      children: [
        const Icon(Icons.security, size: 80, color: AppColors.accent),
        const SizedBox(height: 24),
        Text(
          'Verify Your Cellphone',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 12),
        Text(
          'A simulated 6-digit One-Time PIN (OTP) has been sent via SMS to your registered cellphone number ending in $obscuredPhone.',
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.4),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKeyOtp,
          child: Column(
            children: [
              TextFormField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'Enter 6-digit OTP',
                  hintText: 'e.g. 123456 (or any code except 000000)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                validator: (v) {
                  if (v == null || v.length != 6) {
                    return 'Enter the 6-digit One-Time PIN';
                  }
                  if (int.tryParse(v) == null) {
                    return 'PIN must contain digits only';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtpAndCheckStatus,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('VERIFY & CHECK STATUS'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _isLoading ? null : _sendOtp,
                    icon: const Icon(Icons.replay, size: 16),
                    label: const Text('Resend OTP'),
                  ),
                  TextButton.icon(
                    onPressed: _isLoading ? null : () => setState(() => _otpSent = false),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusView() {
    return Column(
      key: const ValueKey('sassa_status_view'),
      children: [
        _buildStatusCard(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _resetStatusCheck,
            icon: const Icon(Icons.search),
            label: const Text('CHECK ANOTHER STATUS'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'CURRENT STATUS', 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Month', _statusResult!['month'] ?? 'N/A'),
            _buildInfoRow('Outcome', _statusResult!['outcome'] ?? 'N/A'),
            _buildInfoRow('Pay Day', _statusResult!['payDay'] ?? 'TBD'),

            const SizedBox(height: 16),
            Text(
              'Note: Please allow 2-3 working days for payments to reflect after the pay day.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const Divider(height: 32),
            SwitchListTile(
              title: const Text('Track Status Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Get notified if your grant status changes.'),
              value: _isTracking,
              onChanged: _toggleTracking,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
