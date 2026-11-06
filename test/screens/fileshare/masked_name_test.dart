import 'package:daejin_app/screens/fileshare/masked_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('첫 글자와 마지막 글자만 남기고 가운데를 가린다', () {
    expect(maskName('조현돈'), '조*돈');
    expect(maskName('남궁민수'), '남**수');
  });

  test('두 글자면 뒤를, 한 글자면 그대로', () {
    expect(maskName('김민'), '김*');
    expect(maskName('김'), '김');
  });

  test('공백은 무시하고, 비어 있으면 null', () {
    expect(maskName(' 조 현돈 '), '조*돈');
    expect(maskName(''), isNull);
    expect(maskName('   '), isNull);
    expect(maskName(null), isNull);
  });

  group('maskedPeerLabel', () {
    test('가린 이름 뒤에 학번 끝 4자리를 붙인다', () {
      expect(
        maskedPeerLabel(name: '조현돈', studentId: '20201234'),
        '조*돈 · 1234',
      );
    });

    test('학번이 없거나 너무 짧으면 이름만', () {
      expect(maskedPeerLabel(name: '조현돈'), '조*돈');
      expect(maskedPeerLabel(name: '조현돈', studentId: '12'), '조*돈');
    });

    test('이름이 없으면 null(학번만 내보내지 않는다)', () {
      expect(maskedPeerLabel(studentId: '20201234'), isNull);
    });
  });
}
