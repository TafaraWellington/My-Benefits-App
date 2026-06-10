import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/watermark_wrapper.dart';
import '../../payment/providers/credit_provider.dart';
import '../../payment/screens/paywall_screen.dart';
import '../../documents/providers/document_provider.dart';
import '../../../core/services/supabase_service.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(creditProvider).isPremium;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            Image.asset(
              'assets/images/sa_coat_of_arms.png',
              height: 36,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance, color: AppColors.accent, size: 32),
            ),
            const SizedBox(width: 12),
            const Text(
              'SA Benefits',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: _buildProfileHeader(context, ref),
          ),
        ],
      ),
      body: const WatermarkWrapper(
        opacity: 0.08,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _HomeContent(),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) {
    final supabase = ref.watch(supabaseServiceProvider);
    final user = supabase.currentUser;
    final creditState = ref.watch(creditProvider);
    final isPremium = creditState.isPremium;
    final tier = creditState.tier;

    if (user == null) {
      return TextButton.icon(
        onPressed: () => context.push('/login'),
        icon: const Icon(Icons.login, color: AppColors.accent),
        label: const Text('Sign In', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
      );
    }

    final initials = (user.email != null && user.email!.isNotEmpty) 
        ? user.email![0].toUpperCase() 
        : 'U';

    Color tierColor = Colors.grey;
    String tierName = 'Free';
    String statusName = 'Standard';

    if (tier == MembershipTier.gold) {
      tierColor = AppColors.accent;
      tierName = 'Gold';
      statusName = 'Premium';
    } else if (tier == MembershipTier.platinum) {
      tierColor = Colors.purpleAccent;
      tierName = 'Platinum';
      statusName = 'Elite';
    }

    return InkWell(
      onTap: () => context.push('/security'),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: tierColor, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(tierName, style: TextStyle(color: tierColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(statusName, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          if (tier != MembershipTier.platinum) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => PaywallScreen(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tierColor.withOpacity(0.2),
                foregroundColor: tierColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );

  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditState = ref.watch(creditProvider);
    final vaultSizeAsync = ref.watch(vaultSizeProvider);
    
    final int limitInMb = creditState.tier == MembershipTier.platinum 
        ? 250 
        : (creditState.tier == MembershipTier.gold ? 100 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ... (Search Bar and Featured Services stay the same, but I'll skip to the Vault section for brevity if possible, 
        // but I must provide the full ReplacementContent as per instructions if I'm replacing the whole block)
        // Actually, I'll replace the whole build method.
        
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search unclaimed benefits\n(e.g., RAF, SASSA)',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.search, color: AppColors.accent),
              ),
              Container(
                height: 50,
                width: 1,
                color: AppColors.accent.withOpacity(0.3),
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.accent),
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Upgrade Banner
        if (creditState.tier != MembershipTier.platinum)
          _buildUpgradeBanner(context, creditState.tier),

        const SizedBox(height: 32),

        // Featured Services
        const Text(
          'Featured Services',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildServiceCard(context, 'SASSA\nStatus', Icons.account_balance_outlined, () => context.push('/sassa')),
              const SizedBox(width: 16),
              _buildServiceCard(context, 'Unclaimed\nPension', Icons.savings_outlined, () => context.push('/search')),
              const SizedBox(width: 16),
              _buildServiceCard(context, 'RAF\nClaims', Icons.person_search_outlined, () => context.push('/raf')),
              const SizedBox(width: 16),
              _buildServiceCard(context, 'NSFAS\nStatus', Icons.school_outlined, () => context.push('/nsfas')),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // My Searches
        const Text(
          'My Searches',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: ref.watch(supabaseServiceProvider).getSearchHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final searches = snapshot.data ?? [];
            if (searches.isEmpty) {
              return const Text('No recent searches found.', style: TextStyle(color: Colors.grey));
            }
            return Column(
              children: searches.map((s) => Column(
                children: [
                  _buildSearchCard(s['query'] ?? 'Unknown Search', s['status'] ?? 'Pending', s['created_at']?.split('T')[0] ?? 'Recent'),
                  const SizedBox(height: 12),
                ],
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 20),

        // Document Vault
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: AppColors.accent.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Document Vault',
                style: TextStyle(color: AppColors.accent, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Securely store important documents',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _buildDocIcon(Icons.badge, 'ID'),
                      const SizedBox(width: 16),
                      _buildDocIcon(Icons.description_outlined, 'Birth Cert'),
                      const SizedBox(width: 16),
                      _buildDocIcon(Icons.receipt_long_outlined, 'Tax Fin'),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => context.push('/documents'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Upload New', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: vaultSizeAsync.when(
                    data: (sizeInBytes) {
                      final double sizeInMb = sizeInBytes / (1024 * 1024);
                      return Text(
                        '${sizeInMb.toStringAsFixed(2)} MB Used | $limitInMb MB Total',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      );
                    },
                    loading: () => const Text('Calculating...', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    error: (_, __) => Text('0 MB Used | $limitInMb MB Total', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }


  Widget _buildServiceCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard(String title, String status, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Gold status | ', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                    Text('$status | $date', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildDocIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.accent, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _buildUpgradeBanner(BuildContext context, MembershipTier currentTier) {
    final bool isGold = currentTier == MembershipTier.gold;
    final String title = isGold ? 'Unlock Platinum Benefits' : 'Upgrade to Gold Membership';
    final String subtitle = isGold ? 'Get 250MB Vault + 5000 Credits' : 'Get 100MB Vault + 1000 Credits';
    final Color color = isGold ? Colors.purpleAccent : AppColors.accent;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => PaywallScreen(),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

