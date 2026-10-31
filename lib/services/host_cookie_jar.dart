/// 쿠키를 (서버, 이름)으로 나눠 보관한다. 학교 로그인·공지 페이지는 여러 서버
/// (www, nsso, together)를 오가며 같은 이름의 쿠키(JSESSIONID)를 주고받아서, 이름만으로
/// 담으면 서로 덮어쓴다(T-WIN 등수·공지 서비스가 같이 쓴다).
///
/// Domain 속성이 있으면 하위 서버에도 보내고, 없으면 받은 서버에만 보낸다.
/// 경로·만료 시각은 다루지 않고, Max-Age=0이면 지운다.
class HostCookieJar {
  final Map<String, ({String name, String value, String domain, bool hostOnly})>
  _items = {};

  void store(Uri url, List<String> setCookies) {
    for (final cookie in setCookies) {
      final parts = cookie.split(';');
      final eq = parts.first.indexOf('=');
      if (eq <= 0) continue;
      final name = parts.first.substring(0, eq).trim();
      final value = parts.first.substring(eq + 1).trim();
      var domain = url.host.toLowerCase();
      var hostOnly = true;
      var expired = false;
      for (final attr in parts.skip(1)) {
        final a = attr.trim().toLowerCase();
        if (a.startsWith('domain=')) {
          domain = a.substring(7).replaceFirst(RegExp(r'^\.'), '');
          hostOnly = false;
        } else if (a.startsWith('max-age=') && a.substring(8).trim() == '0') {
          expired = true;
        }
      }
      final key = '$domain|$name';
      if (expired) {
        _items.remove(key);
      } else {
        _items[key] = (
          name: name,
          value: value,
          domain: domain,
          hostOnly: hostOnly,
        );
      }
    }
  }

  String headerFor(Uri url) {
    final host = url.host.toLowerCase();
    return _items.values
        .where(
          (c) => c.hostOnly
              ? c.domain == host
              : host == c.domain || host.endsWith('.${c.domain}'),
        )
        .map((c) => '${c.name}=${c.value}')
        .join('; ');
  }
}
