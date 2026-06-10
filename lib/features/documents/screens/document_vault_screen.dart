import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../payment/screens/paywall_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/document_provider.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../payment/providers/credit_provider.dart';

class DocumentVaultScreen extends ConsumerStatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  ConsumerState<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen> {
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final authService = ref.read(biometricServiceProvider);
    final success = await authService.authenticate();
    if (mounted) {
      setState(() {
        _isUnlocked = success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document Vault')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text('Vault is Locked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Authentication required to access documents', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('UNLOCK WITH BIOMETRICS'),
              ),
            ],
          ),
        ),
      );
    }

    final documents = ref.watch(documentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'SA Benefits Vault',
                children: [
                  const Text('All documents are stored locally on your device and synced to the cloud if configured.'),
                ],
              );
            },
          ),
        ],
      ),
      body: documents.isEmpty
          ? _buildEmptyState(context, ref)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                final isImage = doc.path.toLowerCase().endsWith('.jpg') || 
                                doc.path.toLowerCase().endsWith('.png') || 
                                doc.path.toLowerCase().endsWith('.jpeg');
                final isSynced = doc.remoteUrl != null;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showDocumentDetails(context, doc),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isImage 
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(File(doc.path), fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.insert_drive_file, color: AppColors.accent)),
                                  )
                                : const Icon(Icons.description_outlined, color: AppColors.accent, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        doc.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSynced)
                                      const Icon(Icons.cloud_done, size: 16, color: Colors.green)
                                    else
                                      const Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.orange),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        doc.category,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${doc.dateAdded.toString().split(' ')[0]}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showDocumentOptions(context, ref, index),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickFile(context, ref),
        label: const Text('ADD DOCUMENT'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showDocumentDetails(BuildContext context, VaultDocument doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(doc.name, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            Text(doc.category, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: doc.path.toLowerCase().endsWith('.pdf')
                    ? const Center(child: Text('PDF Preview coming soon...'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(doc.path), errorBuilder: (_,__,___) => const Center(child: Icon(Icons.error_outline, size: 48))),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentOptions(BuildContext context, WidgetRef ref, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Document', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ref.read(documentProvider.notifier).removeDocument(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.folder_open, size: 80, color: AppColors.accent.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text('Your Vault is Empty', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Securely store your ID, proof of address, and other claim documents here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _pickFile(context, ref),
            icon: const Icon(Icons.upload_file),
            label: const Text('UPLOAD FIRST DOCUMENT'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
    final creditState = ref.read(creditProvider);
    
    // Free users cannot use the Document Vault (Cloud Sync)
    if (creditState.tier == MembershipTier.free) {
      showDialog(
        context: context,
        builder: (context) => PaywallScreen(),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final file = result.files.first;
      final fileSizeInBytes = file.size;
      
      // Calculate current total size
      int currentTotalSize = 0;
      for (final doc in ref.read(documentProvider)) {
        try {
          final f = File(doc.path);
          if (await f.exists()) {
            currentTotalSize += await f.length();
          }
        } catch (_) {}
      }

      // Define limits
      final int limitInMb = creditState.tier == MembershipTier.platinum ? 250 : 100;
      final int limitInBytes = limitInMb * 1024 * 1024;

      if (currentTotalSize + fileSizeInBytes > limitInBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vault limit reached ($limitInMb MB). Please upgrade or delete old documents.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      
      final category = await _showCategoryPicker(context);
      if (category != null) {
        // 1. Add locally first
        await ref.read(documentProvider.notifier).addDocument(file.name, file.path ?? '', category: category);
        
        // 2. Trigger cloud sync in background
        _triggerCloudSync(ref, file.path ?? '', file.name);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${file.name} saved and syncing to Cloud (${(fileSizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB)')),
          );
        }
      }
    }
  }


  Future<void> _triggerCloudSync(WidgetRef ref, String path, String name) async {
    final supabase = ref.read(supabaseServiceProvider);
    final url = await supabase.uploadDocument(path, name);
    if (url != null) {
      final docs = ref.read(documentProvider);
      final index = docs.indexWhere((d) => d.path == path);
      if (index != -1) {
        final doc = docs[index];
        await ref.read(documentProvider.notifier).updateRemoteUrl(index, url);
        
        // Save metadata to Supabase
        await supabase.saveMetadata({
          'name': doc.name,
          'category': doc.category,
          'remote_url': url,
          'synced_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<String?> _showCategoryPicker(BuildContext context) async {
    final categories = ['ID Document', 'Proof of Address', 'Bank Statement', 'Pay Slip', 'Other'];
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories.map((cat) => ListTile(
            title: Text(cat),
            onTap: () => Navigator.pop(context, cat),
          )).toList(),
        ),
      ),
    );
  }
}
