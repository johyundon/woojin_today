import 'package:flutter/material.dart';

import '../../../services/class_schedule_parser.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/time_format.dart';
import '../../../widgets/pressable.dart';
import '../../campus_map/models/campus_building.dart';
import '../../campus_map/models/geo_point.dart';
import '../../campus_map/services/campus_route_service.dart';
import '../home_colors.dart';

/// 홈 화면의 "다음 수업" 큰 카드 (v7 디자인 12 수업 있는 날 / 13 공강인 날).
/// [next]가 null이면 시간표를 아직 못 불러왔거나(= ![timetableLoaded]) 오늘
/// 남은 수업이 없는 경우라, 대신 "오늘은 수업 없음" 안내 + [upcoming](다음
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
    this.room = '',
    this.walkOrigin,
    this.walkDestination,
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

  /// "길찾기" 버튼(캠퍼스 지도 열기).
  final VoidCallback onDirectionsTap;

  /// [upcoming] 블록의 "시간표" 버튼을 눌렀을 때.
  final VoidCallback onTimetableTap;

  /// [next]의 이번 시간대 강의실. 비어 있으면 "강의실 정보 없음".
  final String room;

  /// 오늘 바로 앞 수업 건물과 [next] 강의실 건물. 둘 다 있고 서로 다르면
  /// 교수님 이름 대신 "걸어서 N분 · Mm"를 보여준다.
  final CampusBuilding? walkOrigin;
  final CampusBuilding? walkDestination;

  static String _remainingLabel(int minutes) {
    if (minutes < 60) return '$minutes분 남음';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h시간 남음' : '$h시간 $m분 남음';
  }

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final item = next;
    if (!timetableLoaded) return _buildLoading();
    if (item != null) return _buildContent(item);
    return _buildEmpty();
  }

  /// 흰 바탕 + 테두리 카드 틀. 안쪽(파란 칸, 장식 원, 노치)이 둥근 모서리를
  /// 넘지 않도록 잘라낸다.
  Widget _frame({required Color borderColor, required Widget child}) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _buildLoading() {
    return _frame(
      borderColor: AppColors.fillDisabled,
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '수업 정보를 불러오는 중이에요',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final headline = hasClassesToday ? '오늘 수업 다 끝났어!' : '오늘은 수업 없음!';
    final subtitle = hasClassesToday ? '오늘 하루도 수고했어!' : '학식 먹고 캠퍼스 한 바퀴 어때?';
    final badge = hasClassesToday ? '완료' : '공강';
    final item = upcoming;

    return _frame(
      borderColor: AppColors.fillDisabled,
      child: Stack(
        children: [
          Positioned(
            top: -29,
            right: -29,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  item == null ? 18 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.blueSoft,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: AppColors.blue,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '오늘 수업',
                            style: TextStyle(
                              color: HomeV7Colors.label,
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      headline,
                      style: const TextStyle(
                        color: HomeV7Colors.emptyHeadline,
                        fontSize: 27,
                        height: 1.4,
                        letterSpacing: -1.08,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textBody,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              if (item != null) ...[
                const _TicketDivider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.wb_sunny_rounded,
                          color: AppColors.blue,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$upcomingDayLabel 첫 수업',
                              style: const TextStyle(
                                color: AppColors.textBody,
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${formatMinutesAsTime(item.slot.startMinutes)} ${item.course.courseName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HomeV7Colors.cardTitle,
                                fontSize: 15,
                                height: 1.4,
                                letterSpacing: -0.3,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _ActionButton(
                        label: '시간표',
                        onTap: onTimetableTap,
                        radius: 16,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TodayClass item) {
    final ongoing = nowMinutes >= item.slot.startMinutes;
    final badge = ongoing
        ? '수업 중'
        : _remainingLabel(item.slot.startMinutes - nowMinutes);
    final professor = item.course.professor.trim();
    return _frame(
      borderColor: HomeV7Colors.nextCardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        '다음 수업',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: HomeV7Colors.remainBadge,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: AppColors.blueText,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatMinutesAsTime(item.slot.startMinutes),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        height: 1.4,
                        letterSpacing: -1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '~ ${formatMinutesAsTime(item.slot.endMinutes)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeV7Colors.onBlueSub,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.course.courseName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeV7Colors.onBlueTitle,
                    fontSize: 16,
                    height: 1.4,
                    letterSpacing: -0.32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.blueText,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.isEmpty ? '강의실 정보 없음' : room,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeV7Colors.cardTitle,
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _WalkOrProfessorLine(
                        professor: professor,
                        origin: walkOrigin,
                        destination: walkDestination,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ActionButton(
                  label: '길찾기',
                  onTap: onDirectionsTap,
                  radius: 12,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [HomeV7Colors.directionsStart, AppColors.blue],
                  ),
                  shadow: const [
                    BoxShadow(
                      color: HomeV7Colors.directionsShadow,
                      offset: Offset(0, 3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 강의실 아래 한 줄. 앞 수업 건물에서 걷는 시간을 구하면 "걸어서 N분 · Mm",
/// 못 구하면(첫 수업, 같은 건물, 건물을 못 찾음) 교수님 이름을 보여준다.
class _WalkOrProfessorLine extends StatefulWidget {
  const _WalkOrProfessorLine({
    required this.professor,
    required this.origin,
    required this.destination,
  });

  final String professor;
  final CampusBuilding? origin;
  final CampusBuilding? destination;

  @override
  State<_WalkOrProfessorLine> createState() => _WalkOrProfessorLineState();
}

class _WalkOrProfessorLineState extends State<_WalkOrProfessorLine> {
  /// 캠퍼스 길 데이터는 한 번만 읽도록 화면 전체에서 같이 쓴다.
  static final _routeService = CampusRouteService();

  CampusRoute? _route;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_WalkOrProfessorLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin?.name != widget.origin?.name ||
        oldWidget.destination?.name != widget.destination?.name) {
      _route = null;
      _load();
    }
  }

  Future<void> _load() async {
    final origin = widget.origin;
    final destination = widget.destination;
    if (origin == null ||
        destination == null ||
        origin.name == destination.name) {
      return;
    }
    try {
      final route = await _routeService.findRoute(
        origin: GeoPoint(lat: origin.lat, lng: origin.lng),
        destination: GeoPoint(lat: destination.lat, lng: destination.lng),
      );
      if (!mounted ||
          widget.origin?.name != origin.name ||
          widget.destination?.name != destination.name) {
        return;
      }
      setState(() => _route = route);
    } catch (e) {
      debugPrint('[Home] 걷는 거리 계산 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final text = route != null
        ? '걸어서 ${route.walkMinutes}분 · ${route.distanceMeters.round()}m'
        : widget.professor.isNotEmpty
        ? '${widget.professor} 교수님'
        : null;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: HomeV7Colors.cardSub,
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 카드 오른쪽 아래의 파란 버튼("길찾기 →", "시간표 →"). 높이 46.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.radius,
    required this.fontSize,
    required this.fontWeight,
    this.gradient,
    this.shadow,
  });

  final String label;
  final VoidCallback onTap;
  final double radius;
  final double fontSize;
  final FontWeight fontWeight;

  /// null이면 [AppColors.blue] 단색.
  final Gradient? gradient;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: gradient == null ? AppColors.blue : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                height: 1.4,
                fontWeight: fontWeight,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// 티켓처럼 보이는 점선 구분선. 카드 양쪽 가장자리에 바탕색 반원이 파여 있다
/// (화면 바탕색 원을 카드 가장자리에 걸쳐 놓고, 카드 밖으로 나간 반쪽은 카드가
/// 잘라낸다).
class _TicketDivider extends StatelessWidget {
  const _TicketDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = (constraints.maxWidth / 6).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    count,
                    (_) => Container(
                      width: 3,
                      height: 1,
                      color: HomeV7Colors.dashLine,
                    ),
                  ),
                );
              },
            ),
          ),
          for (final left in [true, false])
            Positioned(
              top: -10.5,
              left: left ? -10 : null,
              right: left ? null : -10,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
