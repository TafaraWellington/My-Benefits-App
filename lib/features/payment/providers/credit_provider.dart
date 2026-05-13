import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final creditProvider = NotifierProvider<CreditNotifier, CreditState>(() {
  return CreditNotifier();
});

class CreditState {
  final int credits;
  final bool isPremium;

  CreditState({required this.credits, required this.isPremium});

  CreditState copyWith({int? credits, bool? isPremium}) {
    return CreditState(
      credits: credits ?? this.credits,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

class CreditNotifier extends Notifier<CreditState> {
  @override
  CreditState build() {
    _loadState();
    return CreditState(credits: 0, isPremium: false);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = CreditState(
      credits: prefs.getInt('search_credits') ?? 0,
      isPremium: prefs.getBool('is_premium') ?? false,
    );
  }

  Future<void> useCredit() async {
    if (state.credits > 0) {
      state = state.copyWith(credits: state.credits - 1);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('search_credits', state.credits);
    }
  }

  Future<void> addCredits(int amount) async {
    state = state.copyWith(credits: state.credits + amount);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('search_credits', state.credits);
  }

  Future<void> setPremium(bool value) async {
    state = state.copyWith(isPremium: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', value);
  }
}
