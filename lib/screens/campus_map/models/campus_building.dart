/// 캠퍼스 건물 하나(이름 + 실측 위경도 좌표).
class CampusBuilding {
  const CampusBuilding({
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String name;
  final double lat;
  final double lng;
}

/// 대진대학교 건물 좌표 목록(실측). 사용자가 직접 뽑은 좌표를 그대로 옮긴
/// 것으로, 카카오 POI 좌표 자동매칭은 기숙사 단지처럼 건물이 다닥다닥 붙은
/// 곳에서 엉뚱하게 매칭돼 이 고정 목록을 대신 쓴다.
const List<CampusBuilding> campusBuildings = [
  CampusBuilding(name: '공대 가동', lat: 37.8746729, lng: 127.1552665),
  CampusBuilding(name: '공대 나동', lat: 37.8743116, lng: 127.1558078),
  CampusBuilding(name: '공대 다동', lat: 37.8740471, lng: 127.1562083),
  CampusBuilding(name: '중앙도서관', lat: 37.8734401, lng: 127.1549459),
  CampusBuilding(name: '공차 대진대점', lat: 37.8728079, lng: 127.1555989),
  CampusBuilding(name: '인문학관', lat: 37.8719186, lng: 127.156494),
  CampusBuilding(name: '사회과학관', lat: 37.8712763, lng: 127.1573409),
  CampusBuilding(name: '대진교육관', lat: 37.8704067, lng: 127.1586073),
  CampusBuilding(name: '본관', lat: 37.8694732, lng: 127.1583877),
  CampusBuilding(name: '여자기숙사 CU', lat: 37.8690011, lng: 127.1570324),
  CampusBuilding(name: '체육관', lat: 37.8676956, lng: 127.156499),
  CampusBuilding(name: '대운동장', lat: 37.8670929, lng: 127.1582954),
  CampusBuilding(name: '정문(짭정문)', lat: 37.8548105, lng: 127.1667142),
  CampusBuilding(name: '중문(찐정문)', lat: 37.8663044, lng: 127.1572825),
  CampusBuilding(name: '대학원', lat: 37.8703342, lng: 127.1567767),
  CampusBuilding(name: '예술관', lat: 37.8751114, lng: 127.1599429),
  CampusBuilding(name: '미술학관', lat: 37.8768554, lng: 127.156749),
  CampusBuilding(name: '음악학관', lat: 37.8765911, lng: 127.1572562),
  CampusBuilding(name: '생활과학관', lat: 37.876389, lng: 127.1581097),
  CampusBuilding(name: '산학협력단', lat: 37.87607, lng: 127.1577),
  CampusBuilding(name: '산학협동실습관', lat: 37.873783, lng: 127.1544202),
  CampusBuilding(name: '테니스장', lat: 37.8760835, lng: 127.1592763),
  CampusBuilding(name: '남자기숙사 CU', lat: 37.8736723, lng: 127.1578912),
  CampusBuilding(name: '남자기숙사', lat: 37.8741115, lng: 127.158082),
  CampusBuilding(name: '여자기숙사', lat: 37.8693343, lng: 127.1563879),
  CampusBuilding(name: '구내안경원', lat: 37.8707978, lng: 127.1560598),
  CampusBuilding(name: '파워플랜드', lat: 37.870723, lng: 127.158832),
  CampusBuilding(name: '박물관', lat: 37.8727891, lng: 127.1573516),
  CampusBuilding(name: '국민은행 대진대점', lat: 37.8712962, lng: 127.155031),
  CampusBuilding(name: '정보전산원', lat: 37.8729853, lng: 127.1556515),
  CampusBuilding(name: '학생회관', lat: 37.8711868, lng: 127.1551837),
  CampusBuilding(name: '학생회관 CU', lat: 37.8711868, lng: 127.1551837),
  CampusBuilding(name: '학생회관 그라찌에', lat: 37.8711868, lng: 127.1551837),
  CampusBuilding(name: '중앙도서관 그라찌에', lat: 37.8735394, lng: 127.1550485),
  CampusBuilding(name: '학생회관 서점', lat: 37.8711868, lng: 127.1551837),
  CampusBuilding(name: '학생회관 안경점', lat: 37.8711868, lng: 127.1551837),
  CampusBuilding(name: '학생회관 에그2000', lat: 37.8712557, lng: 127.1548833),
  CampusBuilding(name: '학생회관(교내순환)', lat: 37.871697, lng: 127.154979),
  CampusBuilding(name: '정문(교내순환)', lat: 37.8548592, lng: 127.1665908),
  CampusBuilding(name: '우진이 동상', lat: 37.8731455, lng: 127.1567752),
  CampusBuilding(name: '행복베이커리', lat: 37.8741026, lng: 127.1589489),
  CampusBuilding(name: '행복기숙사', lat: 37.8742842, lng: 127.1587686),
  CampusBuilding(name: '평생교육원', lat: 37.870621, lng: 127.1560393),
  CampusBuilding(name: '국제학관', lat: 37.8707321, lng: 127.1561071),
  CampusBuilding(name: '교수회관', lat: 37.8699074, lng: 127.1575756),
];
