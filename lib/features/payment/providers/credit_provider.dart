import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/supabase_service.dart';

final creditProvider = NotifierProvider<CreditNotifier, CreditState>(() {
  return CreditNotifier();
});

enum MembershipTier { free, gold, platinum }

class CreditState {
  final int credits;
  final MembershipTier tier;

  CreditState({required this.credits, required this.tier});

  bool get isPremium => tier != MembershipTier.free;

  CreditState copyWith({int? credits, MembershipTier? tier}) {
    return CreditState(
      credits: credits ?? this.credits,
      tier: tier ?? this.tier,
    );
  }
}

class CreditNotifier extends Notifier<CreditState> {
  @override
  CreditState build() {
    _loadState();
    return CreditState(credits: 0, tier: MembershipTier.free);
  }

  Future<void> _loadState() async {
    // 1. Try loading from Supabase first if user is logged in
    final supabase = ref.read(supabaseServiceProvider);
    if (supabase.currentUser != null) {
      await syncWithServer();
      return;
    }

    // 2. Fallback to local SharedPreferences for guests
    final prefs = await SharedPreferences.getInstance();
    final tierIndex = prefs.getInt('membership_tier') ?? 0;
    state = CreditState(
      credits: prefs.getInt('search_credits') ?? 0,
      tier: MembershipTier.values[tierIndex],
    );
  }

  Future<void> syncWithServer() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final profile = await supabase.getProfile();
      if (profile != null) {
        final credits = profile['credits'] as int? ?? 0;
        final tierStr = profile['membership_tier'] as String? ?? 'free';
        
        MembershipTier tier = MembershipTier.free;
        if (tierStr == 'gold') {
          tier = MembershipTier.gold;
        } else if (tierStr == 'platinum') {
          tier = MembershipTier.platinum;
        }

        state = CreditState(credits: credits, tier: tier);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('search_credits', credits);
        await prefs.setInt('membership_tier', tier.index);
        await prefs.setBool('is_premium', tier != MembershipTier.free);
      }
    } catch (e) {
      // Silent fallback to local if network fails
    }
  }

  Future<void> useCredit() async {
    if (state.credits > 0) {
      state = state.copyWith(credits: state.credits - 1);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('search_credits', state.credits);

      // Decrement in Supabase if logged in
      final supabase = ref.read(supabaseServiceProvider);
      if (supabase.currentUser != null) {
        try {
          await supabase.saveMetadata({
            'user_id': supabase.currentUser!.id,
            'credits': state.credits,
          });
        } catch (_) {}
      }
    }
  }

  Future<void> addCredits(int amount) async {
    state = state.copyWith(credits: state.credits + amount);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('search_credits', state.credits);
  }

  Future<void> setTier(MembershipTier tier) async {
    state = state.copyWith(tier: tier);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('membership_tier', tier.index);
    await prefs.setBool('is_premium', tier != MembershipTier.free);
  }

  @Deprecated('Use setTier instead')
  Future<void> setPremium(bool value) async {
    await setTier(value ? MembershipTier.gold : MembershipTier.free);
  }
}


