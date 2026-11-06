/// 파일공유에서 같은 와이파이의 모두에게 보이는 이름을 만든다 — 실명과
/// 학번 전체를 그대로 내보내지 않도록 이름은 첫 글자와 마지막 글자만 남기고
/// 가운데를 `*`로 가리고(두 글자 이름은 뒤 글자를 가림), 동명이인을 구분하도록
/// 학번은 끝 4자리만 붙인다.
///
/// (조현돈, 20201234) → "조*돈 · 1234". 학번이 없으면 이름만, 이름이 없으면 null.
String? maskedPeerLabel({String? name, String? studentId}) {
  final masked = maskName(name);
  if (masked == null) return null;
  final digits = (studentId ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return masked;
  return '$masked · ${digits.substring(digits.length - 4)}';
}

/// 조현돈 → 조*돈, 김민 → 김*, 남궁민수 → 남**수. 비어 있으면 null.
String? maskName(String? name) {
  // 한글 이름은 글자 하나가 문자 하나라 split('')로 충분하다.
  final chars = (name ?? '').replaceAll(RegExp(r'\s+'), '').split('');
  if (chars.isEmpty) return null;
  if (chars.length == 1) return chars.first;
  if (chars.length == 2) return '${chars.first}*';
  return '${chars.first}${'*' * (chars.length - 2)}${chars.last}';
}
