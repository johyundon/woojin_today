import 'package:flutter/material.dart';

import '../../../services/class_schedule_parser.dart';
import '../../../theme/app_colors.dart';

/// 홈 화면의 "다음 수업" 흰색 큰 카드 ("우진이의 하루" v4 리디자인).
/// [next]가 null이면 시간표를 아직 못 불러왔거나(= ![timetableLoaded]) 오늘
/// 남은 수업이 없는 경우라, 대신 "오늘 수업 없음" 안내 + [upcoming](다음
/// 수업일의 첫 수업)을 보여준다.
class NextClassCard extends StatelessWidget {
  const NextClassCard({
    super.key,
    required this.next,
    required this.nowMinutes,
    required this.timetableLoaded,
    required this.hasClassesToday,
    required this.upcoming,
    required this.upcomingDayLabel,
    required this.onDirectionsTap,
    required this.onTimetableTap,
  });

  final TodayClass? next;

  /// 00:00부터 지금까지의 분. "N분 남음" 계산에 쓴다.
  final int nowMinutes;

  /// 시간표 조회가 끝났는지. 끝나기 전에는 [next]/[hasClassesToday]/
  /// [upcoming]이 아직 신뢰할 수 없는 기본값이라 로딩 상태만 보여준다.
  final bool timetableLoaded;

  /// 오늘 요일에 애초에 수업이 하나라도 있었는지(이미 다 끝났더라도 true).
  /// [next]가 null일 때 "공강"과 "오늘 수업 다 끝남"을 구분하는 데 쓴다.
  final bool hasClassesToday;

  /// 다음 수업일의 첫 수업. [next]가 null일 때만 쓰고, 일주일 내내 수업이
  /// 없으면 null(이 경우 안내 블록을 보여주지 않는다).
  final UpcomingClass? upcoming;

  /// [upcoming]이 있는 날을 가리키는 라벨("내일" 또는 "금요일" 등).
  final String upcomingDayLabel;

  final VoidCallback onDirectionsTap;

  /// [upcoming] 블록의 "시간표 →" 버튼을 눌렀을 때.
  final VoidCallback onTimetableTap;

  static String _hhmm(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  static String _remainingLabel(int minutes) {
    if (minutes < 60) return '$minutes분 남음';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h시간 남음' : '$h시간 $m분 남음';
  }

  static const _cardRadius = 28.0;

  @override
  Widget build(BuildContext context) {
    final item = next;
    final showEmptyDecoration = timetableLoaded && item == null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF030A7F).withValues(alpha: 0.22),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      // 티켓 노치(카드 밖으로 삐져나와야 하는 반원)는 clip 없이 그리고,
      // "공강" 장식 원(카드 모서리에 잘려야 하는 원)만 따로 카드 전체
      // 영역에 맞춰 clip한다 — 두 요소의 clip 요구사항이 서로 반대라
      // 레이어를 분리했다.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showEmptyDecoration)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_cardRadius),
                child: const Stack(
                  children: [
                    Positioned(
                      top: -56,
                      right: -56,
                      child: _EmptyDecorationCircle(),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: !timetableLoaded
                ? _buildLoading()
                : item != null
                ? _buildContent(item)
                : _buildEmpty(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        SizedBox(width: 12),
        Text(
          '수업 정보를 불러오는 중이에요',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final headline = hasClassesToday ? '오늘 수업\n다 끝났어!' : '오늘은\n공강이야!';
    final subtitle = hasClassesToday ? '오늘 하루도 수고했어!' : '학식 먹고 캠퍼스 한 바퀴 어때?';
    final badge = hasClassesToday ? '완료' : '공강';
    final item = upcoming;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.cobalt.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available,
                color: AppColors.cobalt,
                size: 17,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '오늘 수업',
              style: TextStyle(
                color: Color(0xFF5A5852),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          headline,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 30,
            height: 1.18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF9A978F),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (item != null) ...[
          const SizedBox(height: 16),
          const _TicketDivider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cobalt.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.wb_sunny,
                  color: AppColors.cobalt,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$upcomingDayLabel 첫 수업',
                      style: const TextStyle(
                        color: Color(0xFF9A978F),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_hhmm(item.slot.startMinutes)} ${item.course.courseName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onTimetableTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cobalt,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cobalt.withValues(alpha: 0.4),
                        offset: const Offset(0, 6),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Text(
                    '시간표 →',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildContent(TodayClass item) {
    final ongoing = nowMinutes >= item.slot.startMinutes;
    final badge = ongoing
        ? '수업 중'
        : _remainingLabel(item.slot.startMinutes - nowMinutes);
    final professor = item.course.professor.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.cobalt.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule,
                color: AppColors.cobalt,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '다음 수업',
              style: TextStyle(
                color: Color(0xFF5A5852),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: AppColors.lime, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    badge,
                    style: const TextStyle(
                      color: AppColors.lime,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _hhmm(item.slot.startMinutes),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 46,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '– ${_hhmm(item.slot.endMinutes)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9A978F),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.course.courseName,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        const _TicketDivider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cobalt.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.cobalt,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.course.room.isEmpty ? '강의실 정보 없음' : item.course.room,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (professor.isNotEmpty)
                    Text(
                      '$professor 교수님',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9A978F),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDirectionsTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cobalt,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cobalt.withValues(alpha: 0.4),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Text(
                  '길찾기 →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// "공강"/"완료" 배지 뒤에 깔리는 라임색 장식 원. 카드 모서리에 걸쳐서
/// [NextClassCard.build]의 [ClipRRect]가 카드 둥근 모서리 모양 그대로
/// 잘라낸다.
class _EmptyDecorationCircle extends StatelessWidget {
  const _EmptyDecorationCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: const BoxDecoration(
        color: AppColors.lime,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 티켓처럼 보이는 점선 구분선. 카드 양쪽 가장자리에 파란 반원이 파여 있다
/// (배경색 [AppColors.cobalt] 원을 카드 가장자리에 걸쳐 놓는 방식).
class _TicketDivider extends StatelessWidget {
  const _TicketDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final count = (constraints.maxWidth / 8).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  count,
                  (_) => Container(
                    width: 4,
                    height: 1.5,
                    color: const Color(0xFFD9D6CF),
                  ),
                ),
              );
            },
          ),
          const _TicketNotches(),
        ],
      ),
    );
  }
}

/// 카드 양쪽 가장자리에 파란 반원이 파인 티켓 절취선 느낌을 내는 노치 한 쌍.
/// 카드 안쪽 어디서든(구분선 위, 내용이 한 줄뿐인 빈 상태 위) 같은 자리에
/// 겹쳐 쓸 수 있도록 별도 위젯으로 뺐다.
class _TicketNotches extends StatelessWidget {
  const _TicketNotches();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final left in [true, false])
          Positioned(
            left: left ? -30 : null,
            right: left ? null : -30,
            top: 0,
            bottom: 0,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.cobalt,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
