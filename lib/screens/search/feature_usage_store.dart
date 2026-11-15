import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 기능을 몇 번 열었는지 휴대폰에 저장한다. 모아보기 "자주 찾는 메뉴"가 많이
/// 연 순서로 카드를 고르는 데 쓴다. 기능 이름(label)별 횟수를 JSON 하나로 둔다.
class FeatureUsageStore {
  const FeatureUsageStore();

  static const String _key = 'feature_usage_counts';

  /// 기록이 바뀔 때마다 1씩 오른다. 모아보기 카드가 듣고 다시 읽는다.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  /// 저장소를 못 읽거나 값이 깨졌으면 빈 기록으로 본다(기본 카드가 나온다).
  Future<Map<String, int>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> record(String label) async {
    final counts = await load();
    counts[label] = (counts[label] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(counts));
    changes.value++;
  }
}

/// [candidates] 중 [counts]가 큰 순서로 [take]개를 고른다. 횟수가 같으면
/// [candidates]에 먼저 있는 것이 앞이라, 기록이 없으면 앞의 [take]개가 그대로 나온다.
List<T> pickFrequent<T>(
  List<T> candidates,
  String Function(T) labelOf,
  Map<String, int> counts, {
  int take = 3,
}) {
  final indexed = candidates.indexed.toList()
    ..sort((a, b) {
      final byCount = (counts[labelOf(b.$2)] ?? 0).compareTo(
        counts[labelOf(a.$2)] ?? 0,
      );
      return byCount != 0 ? byCount : a.$1.compareTo(b.$1);
    });
  return [for (final (_, c) in indexed.take(take)) c];
}
