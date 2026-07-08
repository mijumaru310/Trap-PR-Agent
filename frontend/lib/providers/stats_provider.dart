import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

// Currently hardcoding owner for testing as requested
const defaultOwner = 'mijumaru310';
const defaultRepo = 'Trap-PR-Agent';

final statsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getUserStats(defaultOwner);
});
