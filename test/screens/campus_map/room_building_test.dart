// 시간표 강의실 글자에서 캠퍼스 건물을 찾는 규칙과, 시간대별 강의실 고르기를 검증한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/campus_map/models/room_building.dart';
import 'package:daejin_app/services/class_schedule_parser.dart';
import 'package:daejin_app/services/course_catalog_service.dart';

void main() {
  group('buildingForRoom', () {
    test('건물 목록 이름 + 호수면 그 건물을 찾는다(공백 유무 무관)', () {
      expect(buildingForRoom('인문학관 302')?.name, '인문학관');
      expect(buildingForRoom('사회과학관202')?.name, '사회과학관');
      expect(buildingForRoom('공대가동 101')?.name, '공대 가동');
    });

    test('줄임말은 별칭 표로 바꿔 찾는다', () {
      expect(buildingForRoom('인문관302호')?.name, '인문학관');
      expect(buildingForRoom('사회관 105')?.name, '사회과학관');
    });

    test('모르는 건물이거나 비어 있으면 null', () {
      expect(buildingForRoom('공학관201'), isNull);
      expect(buildingForRoom(''), isNull);
      expect(buildingForRoom('302'), isNull);
    });
  });

  group('roomForSlot', () {
    TodayClass classAt(String raw, String room, int index) {
      final course = CourseCatalogItem(
        seq: 1,
        courseCode: 'X',
        section: '01',
        courseName: '과목',
        courseType: '전선',
        credit: 3,
        targetGrade: '',
        professor: '',
        rawSchedule: raw,
        room: room,
        isClosed: false,
        capacity: 0,
        waitlistCount: 0,
        enrollmentRatio: '',
      );
      return (course: course, slot: parseRawSchedule(raw)[index]);
    }

    test('강의실이 하나면 그대로', () {
      expect(roomForSlot(classAt('월09:00-10:15', '인문학관301', 0)), '인문학관301');
    });

    test('/로 나뉘면 같은 순서의 시간대 강의실을 고른다', () {
      const raw = '월09:00-10:15,수09:00-10:15';
      const room = '인문학관301/사회과학관202';
      expect(roomForSlot(classAt(raw, room, 0)), '인문학관301');
      expect(roomForSlot(classAt(raw, room, 1)), '사회과학관202');
    });
  });
}
