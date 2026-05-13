import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_theme.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _biometricEnabled = true;
  bool _isSupported = false;
  List<String> _availableTypes = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = ref.read(biometricServiceProvider);
    final enabled = await service.isEnabled();
    final supported = await service.isDeviceSupported();
    final types = await service.getAvailableBiometrics();

    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
        _isSupported = supported;
        _availableTypes = types.map((e) => e.toString().split('.').last).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.security, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'App Protection',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Control how your data is protected on this device.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          if (!_isSupported)
            _buildUnsupportedCard()
          else
            _buildBiometricToggle(),

          const SizedBox(height: 40),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildBiometricToggle() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Biometric Lock', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Require Fingerprint or FaceID to access sensitive areas.'),
              value: _biometricEnabled,
              activeColor: AppColors.primary,
              onChanged: (value) async {
                await ref.read(biometricServiceProvider).setEnabled(value);
                setState(() => _biometricEnabled = value);
              },
            ),
            if (_availableTypes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Detected: ${_availableTypes.join(", ")}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Biometric authentication is not supported or not set up on this device.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Privacy Info', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildInfoItem(Icons.lock_clock_outlined, 'We never store your biometric data. Authentication is handled by your device OS.'),
        _buildInfoItem(Icons.cloud_off, 'Your security preferences are stored locally and are not synced to any servers.'),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey))),
        ],
      ),
    );
  }
}
