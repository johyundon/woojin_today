/// 졸업 요건 영역 하나(전공필수/전공선택/교양필수/교양선택/일반선택 등) —
/// 그 영역에서 필요한 학점과 지금까지 이수한 학점.
class GraduationCreditCategory {
  const GraduationCreditCategory({
    required this.label,
    required this.required,
    required this.earned,
  });

  final String label;
  final int required;
  final int earned;

  /// 이 영역에서 더 들어야 하는 학점(이미 채웠으면 0, 초과 이수는 0으로
  /// 표시 — 음수로 보여줄 이유가 없다).
  int get remaining => (required - earned).clamp(0, required);
}
