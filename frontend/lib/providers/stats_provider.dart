import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import 'settings_provider.dart';

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final settings = ref.watch(settingsProvider);
  
  final data = await apiService.getUserStats();
  
  final pendingCount = data['pending_count'] as int? ?? 0;
  
  if (pendingCount > 0) {
    final timer = Timer(const Duration(seconds: 10), () {
      ref.invalidateSelf();
    });
    
    ref.onDispose(() {
      timer.cancel();
    });
  }
  
  return data;
});
