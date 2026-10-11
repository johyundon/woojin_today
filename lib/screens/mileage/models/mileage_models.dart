/// 전체 TOP5 순위 한 줄 — 순위 + 점수.
class MileageRankEntry {
  const MileageRankEntry({required this.rank, required this.score});

  final int rank;
  final int score;
}

/// 장학 대상자 공지 한 건.
class MileageNotice {
  const MileageNotice({
    required this.title,
    required this.author,
    required this.date,
    required this.viewCount,
  });

  final String title;
  final String author;
  final String date;
  final int viewCount;
}
