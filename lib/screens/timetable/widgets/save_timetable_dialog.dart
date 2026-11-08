import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// 이미 저장된 이름([existingNames])과 겹치지 않는 가장 작은 "시간표N".
String nextDefaultTimetableName(Iterable<String> existingNames) {
  final taken = existingNames.map((n) => n.trim()).toSet();
  var n = 1;
  while (taken.contains('시간표$n')) {
    n++;
  }
  return '시간표$n';
}

/// [name] 뒤에 붙일 "로/으로". 받침이 있는 숫자(0·3·6: 영·삼·육)로 끝나면
/// "으로", 그 밖(ㄹ 받침인 1·7·8 포함)은 "로". 숫자가 아니면 "(으)로".
String directionParticle(String name) {
  if (name.isEmpty) return '(으)로';
  final last = name[name.length - 1];
  if ('036'.contains(last)) return '으로';
  if ('12456789'.contains(last)) return '로';
  return '(으)로';
}

/// "시간표 저장" 팝업(v7 디자인 27). 이름은 선택이다. 확인을 누르면 입력한
/// 이름을, 비워 두었으면 [defaultName]("시간표3" 등)을 [Navigator.pop]으로
/// 돌려준다(취소/바깥 탭이면 null).
class SaveTimetableDialog extends StatefulWidget {
  const SaveTimetableDialog({super.key, required this.defaultName});

  /// 이름을 비워 두면 쓰는 이름.
  final String defaultName;

  @override
  State<SaveTimetableDialog> createState() => _SaveTimetableDialogState();
}

class _SaveTimetableDialogState extends State<SaveTimetableDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _controller.text.trim();
    Navigator.of(context).pop(name.isEmpty ? widget.defaultName : name);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '시간표 저장',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Text.rich(
              TextSpan(
                text: '이름 ',
                children: [
                  TextSpan(
                    text: '(선택)',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                color: AppColors.textBody,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              cursorColor: AppColors.blue,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: widget.defaultName,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: AppColors.fill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.blue, width: 2),
                ),
              ),
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 8),
            Text(
              "비워 두면 '${widget.defaultName}'"
              '${directionParticle(widget.defaultName)} 저장돼요',
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _button(
                    label: '취소',
                    background: AppColors.fill,
                    textStyle: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _button(
                    label: '확인',
                    background: AppColors.blue,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    onTap: _confirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _button({
    required String label,
    required Color background,
    required TextStyle textStyle,
    required VoidCallback onTap,
  }) {
    return Pressable(
      pressedScale: 0.96,
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: textStyle),
      ),
    );
  }
}
