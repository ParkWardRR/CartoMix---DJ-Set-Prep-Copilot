import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../platform/native_bridge.dart';

class UpdateState {
  final bool isChecking;
  final DateTime? lastCheckedAt;
  final String statusMessage;

  const UpdateState({
    required this.isChecking,
    required this.lastCheckedAt,
    required this.statusMessage,
  });

  factory UpdateState.initial() => const UpdateState(
        isChecking: false,
        lastCheckedAt: null,
        statusMessage: 'Automatic Sparkle checks enabled',
      );

  UpdateState copyWith({
    bool? isChecking,
    DateTime? lastCheckedAt,
    String? statusMessage,
  }) {
    return UpdateState(
      isChecking: isChecking ?? this.isChecking,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  String formattedLastCheck() {
    if (lastCheckedAt == null) return 'Not checked yet';
    return 'Last checked ${DateFormat('MMM d, HH:mm').format(lastCheckedAt!)}';
  }
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  UpdateNotifier() : super(UpdateState.initial());

  final _bridge = NativeBridge.instance;

  Future<void> refreshLastCheck() async {
    final last = await _bridge.lastUpdateCheck();
    state = state.copyWith(lastCheckedAt: last);
  }

  Future<void> checkForUpdates() async {
    state = state.copyWith(
      isChecking: true,
      lastCheckedAt: DateTime.now(),
      statusMessage: 'Checking for updates…',
    );
    try {
      await _bridge.checkForUpdates();
      state = state.copyWith(
        isChecking: false,
        statusMessage: 'Sparkle will show a window if an update is available.',
      );
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        statusMessage: 'Update check failed: $e',
      );
    }
  }
}

final updateProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier()..refreshLastCheck();
});
