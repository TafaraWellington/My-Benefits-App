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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isTracking = false;
  Map<String, dynamic>? _statusResult;

  @override
  void initState() {
    super.initState();
    _loadTrackingStatus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SASSA SRD Status')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.account_balance, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 24),
            Text(
              'Check Your Grant Status',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your details below to see the current status of your Social Relief of Distress (SRD) application.',
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
                      labelText: 'ID Number',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.length != 13 ? 'Enter a valid 13-digit ID' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _checkStatus,
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('CHECK STATUS'),
                    ),
                  ),
                ],
              ),
            ),
            if (_statusResult != null) ...[
              const SizedBox(height: 32),
              _buildStatusCard(),
            ],
          ],
        ),
      ),
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
                const SizedBox(height: 8),
                Text(' CURRENT STATUS', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.success)),
              ],
            ),
            const Divider(),
            _buildInfoRow('Month', _statusResult!['month']),
            _buildInfoRow('Outcome', _statusResult!['outcome']),
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

  void _checkStatus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final sassaService = ref.read(sassaApiServiceProvider);
      final result = await sassaService.checkStatus(
        idNumber: _idController.text,
        phoneNumber: _phoneController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }
}
