import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'mascot_sticker.dart';

/// 지금 떠 있는 배너. 새 배너를 띄우면 이전 것은 바로 지운다(겹쳐 쌓이지 않게).
OverlayEntry? _current;

/// 화면 맨 위에서 내려왔다가 잠시 뒤 올라가며 사라지는 알림 배너.
///
/// 하단 SnackBar 대신 이걸 쓴다. [icon]을 주면 왼쪽에 코발트 원 안의 아이콘을,
/// 없으면 마스코트를 보여준다. 누르거나 위로 밀면 바로 닫힌다.
void showTopBanner(
  BuildContext context, {
  required String title,
  required String message,
  IconData? icon,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _current?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopBanner(
      title: title,
      message: message,
      icon: icon,
      onDismissed: () {
        if (_current == entry) _current = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

class _TopBanner extends StatefulWidget {
  const _TopBanner({
    required this.title,
    required this.message,
    required this.icon,
    required this.onDismissed,
  });

  final String title;
  final String message;
  final IconData? icon;
  final VoidCallback onDismissed;

  @override
  State<_TopBanner> createState() => _TopBannerState();
}

class _TopBannerState extends State<_TopBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 220),
  );

  // 내려올 때는 살짝 지나쳤다가 제자리로 튕기듯 멈춘다.
  late final Animation<Offset> _offset =
      Tween(begin: const Offset(0, -1.6), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        ),
      );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _controller.forward();
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    await _dismiss();
  }

  Future<void> _dismiss() async {
    if (!mounted || _controller.isDismissed) return;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _controller,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < 0) _dismiss();
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF030A7F).withValues(alpha: 0.25),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (icon != null)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.cobalt,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      )
                    else
                      const MascotSticker(width: 40, angle: 0),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              color: Color(0x99121212),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
