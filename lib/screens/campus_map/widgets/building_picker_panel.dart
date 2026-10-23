import 'package:flutter/material.dart';

import '../campus_map_colors.dart';
import '../models/campus_building.dart';

/// 출발지/목적지 건물을 고르는 패널 (Figma node 6:100) — 검색바 바로 아래
/// 지도 위에 뜨는 둥근 모서리 카드다. 예전엔 화면 바닥에서 올라오는
/// 바텀시트였는데, 디자인은 지도가 옆/아래로 계속 보이는 "떠 있는 패널"
/// 형태라 바텀시트 대신 [CampusMapScreen]의 Stack 안에 직접 올리는
/// 오버레이로 바꿨다(건물을 고르거나 패널 바깥(지도)을 탭하면 닫힌다).
class BuildingPickerPanel extends StatefulWidget {
  const BuildingPickerPanel({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  State<BuildingPickerPanel> createState() => _BuildingPickerPanelState();
}

class _BuildingPickerPanelState extends State<BuildingPickerPanel> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? campusBuildings
        : campusBuildings.where((b) => b.name.contains(_query)).toList();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.only(bottom: 16),
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: CampusMapColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '건물 선택',
                style: TextStyle(
                  color: CampusMapColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: const BoxDecoration(
                color: CampusMapColors.surfaceElevated,
                borderRadius: BorderRadius.all(Radius.circular(26)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(
                  color: CampusMapColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  icon: const Padding(
                    padding: EdgeInsets.only(left: 14),
                    child: Icon(
                      Icons.search,
                      color: CampusMapColors.textSecondary,
                    ),
                  ),
                  hintText: '건물 이름 검색',
                  hintStyle: const TextStyle(
                    color: CampusMapColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 10,
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '검색 결과가 없어요',
                      style: TextStyle(
                        color: CampusMapColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final building = filtered[index];
                      return _BuildingRow(
                        name: building.name,
                        onTap: () => widget.onSelected(building.name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BuildingRow extends StatelessWidget {
  const _BuildingRow({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          name,
          style: const TextStyle(
            color: CampusMapColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
