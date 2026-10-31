import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../../../services/advisor_consultation_service.dart';
import 'advisor_load_states.dart';

const Color _mutedText = Color(0xFF7C7B88);

/// "상세보기" 바텀시트(v4 리디자인) — 화면 아래에서 올라오며, 제목 +
/// 라벨-값 쌍(신청일시/상태/신청 내용/답변일시/답변 내용) 세로 나열 +
/// 하단 "확인" 버튼. 내용은 시트를 열 때 [loadDetail]로 불러온다.
Future<void> showAdvisorConsultationDetailSheet(
  BuildContext context, {
  required Future<ConsultationDetailInfo> Function() loadDetail,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _AdvisorConsultationDetailSheet(loadDetail: loadDetail),
  );
}

class _AdvisorConsultationDetailSheet extends StatefulWidget {
  const _AdvisorConsultationDetailSheet({required this.loadDetail});

  final Future<ConsultationDetailInfo> Function() loadDetail;

  @override
  State<_AdvisorConsultationDetailSheet> createState() =>
      _AdvisorConsultationDetailSheetState();
}

class _AdvisorConsultationDetailSheetState
    extends State<_AdvisorConsultationDetailSheet> {
  late Future<ConsultationDetailInfo> _future = widget.loadDetail();

  void _retry() => setState(() => _future = widget.loadDetail());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E3EC),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '상세보기',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          FutureBuilder<ConsultationDetailInfo>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const AdvisorLoadingBox();
              }
              final detail = snapshot.data;
              if (detail == null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: AdvisorErrorBox(
                    message: advisorErrorMessage(snapshot.error ?? ''),
                    onRetry: _retry,
                  ),
                );
              }
              // 신청·답변 내용이 길어도 시트가 화면을 넘지 않게 한다.
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow('신청일시', detail.appliedAt),
                      _buildRow('상태', detail.status),
                      _buildRow('신청 내용', detail.content),
                      _buildRow('답변일시', detail.answeredAt ?? '-'),
                      _buildRow('답변 내용', detail.answerContent ?? '-'),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Pressable.effect(
              pressedScale: 0.97,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _mutedText, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
