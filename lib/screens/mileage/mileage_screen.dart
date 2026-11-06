import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/credential_storage.dart';
import '../../services/mileage_service.dart';
import '../../services/service_factory.dart';
import '../../services/twin_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import '../../widgets/twin_credentials_form.dart';
import 'models/mileage_models.dart';
import 'widgets/mileage_history_card.dart';
import 'widgets/mileage_scholarship_tab.dart';
import 'widgets/mileage_total_card.dart' show MileageTotalCard, formatPoints;

typedef MileageCredentials = ({String userId, String userPwd});

/// "모은 마일리지" 화면(v7 디자인). 총 포인트 카드, 이번 학기 카드, 장학
/// 대상자 카드, 적립 내역을 보여준다.
///
/// 흐름: 학번·비밀번호(자동 로그인 때 저장한 값, 없으면 입력) → T-WIN에 한 번
/// 로그인해 내 점수와 지급 내역을 받는다(하루 캐시). 당겨서 새로고침하면 캐시를
/// 무시하고 새로 받는다. "장학 대상자" 카드를 누르면 학교 홈페이지의 대상자 공지와
/// 명단 확인 화면으로 간다.
///
/// 학교 API에 없는 값(다음 등급·진행 바, "장학 기준 2,000P")은 숨겼다. 목데이터
/// ([MileageMockData] 등)와 그 값을 그리는 코드는 남겨 두었다.
class MileageScreen extends StatefulWidget {
  const MileageScreen({
    this.service,
    this.readCredentials,
    this.now,
    super.key,
  });

  /// 테스트용 주입 지점들.
  final MileageServiceBase? service;
  final Future<MileageCredentials?> Function()? readCredentials;
  final DateTime Function()? now;

  @override
  State<MileageScreen> createState() => _MileageScreenState();
}

class _MileageScreenState extends State<MileageScreen> {
  late final MileageServiceBase _service =
      widget.service ?? ServiceFactory.mileage();

  MileageCredentials? _credentials;

  /// 학번·비밀번호를 폼에서 직접 입력했는지(틀리면 다시 입력받는다).
  bool _typedCredentials = false;

  bool _loading = true;
  bool _needCredentials = false;
  String? _error;
  MileageStatus? _status;

  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final read = widget.readCredentials ?? CredentialStorage().read;
    MileageCredentials? stored;
    try {
      stored = await read();
    } catch (_) {
      stored = null;
    }
    if (!mounted) return;
    if (stored == null) {
      setState(() {
        _loading = false;
        _needCredentials = true;
      });
      return;
    }
    _credentials = stored;
    await _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final credentials = _credentials;
    if (credentials == null) return;
    setState(() {
      _loading = _status == null || !forceRefresh;
      _error = null;
    });
    try {
      final status = await _service.fetchStatus(
        userId: credentials.userId,
        userPwd: credentials.userPwd,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _needCredentials = false;
        _status = status;
      });
    } on TwinException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = null;
        _error = switch (e.failure) {
          TwinFailure.loginFailed => 'T-WIN 로그인에 실패했어요. 학번·비밀번호를 확인해 주세요.',
          TwinFailure.noData => '마일리지 정보를 찾지 못했어요. 잠시 후 다시 시도해 주세요.',
          TwinFailure.network => '네트워크 연결을 확인해 주세요.',
        };
        // 직접 입력한 학번·비밀번호가 틀렸으면 다시 입력받는다.
        if (e.failure == TwinFailure.loginFailed && _typedCredentials) {
          _needCredentials = true;
        }
      });
    }
  }

  Future<void> _submitCredentials() async {
    final id = _idController.text.trim();
    final pw = _pwController.text;
    if (id.isEmpty || pw.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _needCredentials = false;
      _loading = true;
    });
    _typedCredentials = true;
    _credentials = (userId: id, userPwd: pw);
    await _load();
  }

  void _openScholarshipTargets() {
    final studentId = _credentials?.userId;
    if (studentId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            backgroundColor: AppColors.canvas,
            foregroundColor: AppColors.textStrong,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            // 밝은 바탕이라 상태 표시줄 글자를 어둡게 한다.
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            title: const Text(
              '장학 대상자 확인',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: MileageScholarshipTab(
              service: _service,
              studentId: studentId,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 밝은 바탕이라 상태 표시줄 글자를 어둡게 한다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.blue,
            backgroundColor: Colors.white,
            onRefresh: () => _load(forceRefresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pressable.icon(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textStrong,
                            size: 15,
                            semanticLabel: '뒤로',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '비교과 · 활동',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '모은 마일리지',
                        style: TextStyle(
                          color: AppColors.textStrong,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                          letterSpacing: -0.91,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ..._body(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body() {
    if (_loading) {
      return const [
        SizedBox(height: 80),
        Center(child: CircularProgressIndicator(color: AppColors.blue)),
      ];
    }
    if (_needCredentials) {
      return [
        TwinCredentialsForm(
          idController: _idController,
          pwController: _pwController,
          error: _error,
          description: '마일리지는 T-WIN에 따로 로그인해서 가져와요. 입력한 값은 저장하지 않아요.',
          buttonLabel: '마일리지 보기',
          onSubmit: _submitCredentials,
        ),
      ];
    }
    final status = _status;
    if (status == null) {
      return [_Message(text: _error ?? '마일리지 정보를 불러오지 못했어요.', onRetry: _load)];
    }
    final now = (widget.now ?? DateTime.now)();
    return [
      MileageTotalCard(total: status.points),
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _PointCard(
                color: AppColors.blueSoft,
                valueColor: AppColors.blueText,
                label: '이번 학기',
                value: '+${formatPoints(status.semesterPoints(now))}P',
              ),
            ),
            const SizedBox(width: 10),
            // 원래 "장학 기준 2,000P" 카드였다. 기준 점수는 API에 없어 숨기고,
            // 같은 자리에서 대상자 확인으로 들어가게 했다.
            Expanded(
              child: _PointCard(
                color: _scholarshipCardBackground,
                valueColor: _scholarshipCardValue,
                label: '장학 대상자',
                value: '확인 →',
                onTap: _openScholarshipTargets,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      MileageHistoryCard(
        activities: [for (final e in status.history) _toActivity(e)],
      ),
    ];
  }

  static MileageActivity _toActivity(MileageEntry e) {
    final d = e.parsedDate;
    String two(int v) => v.toString().padLeft(2, '0');
    return MileageActivity(
      title: e.title,
      date: d == null
          ? e.date
          : '${d.year}.${two(d.month)}.${two(d.day)} · ${e.category}',
      points: e.points,
      icon: _iconFor(e.category),
    );
  }

  static IconData _iconFor(String category) {
    if (category.contains('봉사')) return Icons.volunteer_activism_rounded;
    if (category.contains('학술') || category.contains('상담')) {
      return Icons.school_rounded;
    }
    if (category.contains('특강') || category.contains('교육')) {
      return Icons.mic_rounded;
    }
    return Icons.stars_rounded;
  }
}

/// "장학 대상자" 카드 바탕 rgb(238, 240, 243)과 값 글자색 rgb(43, 47, 59)
/// (v7 디자인 47 mileage의 "장학 기준" 카드 색).
const _scholarshipCardBackground = Color(0xFFEEF0F3);
const _scholarshipCardValue = Color(0xFF2B2F3B);

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Pressable.effect(
            pressedScale: 0.96,
            child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({
    required this.color,
    required this.valueColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  final Color color;
  final Color valueColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      enabled: onTap != null,
      pressedScale: 0.97,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                  letterSpacing: -0.945,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
