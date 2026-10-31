import '../../screens/cafeteria/models/cafeteria_menu.dart';
import '../../screens/cafeteria/services/cafeteria_menu_mock_data.dart';
import '../cafeteria_menu_service.dart';

/// 학교 서버를 부르지 않고 [CafeteriaMenuMockData]의 목데이터를 돌려주는 서비스.
/// 화면 테스트에서 쓴다.
class FakeCafeteriaMenuService implements CafeteriaMenuServiceBase {
  @override
  Future<DailyCafeteriaMenu> fetchMenu(DateTime date) async =>
      CafeteriaMenuMockData.menuFor(date) ?? const DailyCafeteriaMenu();
}
