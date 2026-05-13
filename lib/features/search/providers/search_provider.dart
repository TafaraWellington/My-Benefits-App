import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fsca_models.dart';
import '../services/fsca_service.dart';

final fscaServiceProvider = Provider<IFscaService>((ref) => FscaService());

final fscaSearchProvider = NotifierProvider<FscaSearchNotifier, AsyncValue<FscaSearchState>>(() {
  return FscaSearchNotifier();
});

class FscaSearchNotifier extends Notifier<AsyncValue<FscaSearchState>> {
  @override
  AsyncValue<FscaSearchState> build() {
    return AsyncValue.data(FscaSearchState(results: []));
  }

  Future<void> performSearch({
    required EnquirerDetails enquirer,
    required TargetDetails target,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(fscaServiceProvider);
      final results = await service.searchBenefits(enquirer: enquirer, target: target);
      state = AsyncValue.data(FscaSearchState(results: results, enquirer: enquirer, target: target));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = AsyncValue.data(FscaSearchState(results: []));
  }
}

class FscaSearchState {
  final List<BenefitResult> results;
  final EnquirerDetails? enquirer;
  final TargetDetails? target;

  FscaSearchState({
    required this.results,
    this.enquirer,
    this.target,
  });
}
