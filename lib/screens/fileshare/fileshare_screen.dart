import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';
import 'fileshare_colors.dart';
import 'received_file.dart';
import 'widgets/peer_row.dart';
import 'widgets/radar_view.dart';
import 'widgets/received_file_row.dart';

const Color _cardTint = Color(0xFFEEF2FD);

/// "파일공유" 화면(v4 리디자인) — 데스크톱에 공유된 참고 스크린샷 3장(꺼짐/
/// 주변 탐색 중/받은 파일 있음)을 그대로 따라 겉모양만 다시 짰다. 제목과
/// 본문은 [_enabled]/[_receivedFiles] 두 상태값만으로 3가지로 갈린다 —
/// 새 상태값을 따로 만들지 않았다:
/// - 꺼짐: "주변 친구와 자료 주고받기" + 빈 받은 파일 안내
/// - 켜짐 + 받은 파일 0개: "주변에서 찾는 중이에요" + 레이더 + 발견된 사람 목록
/// - 받은 파일 ≥1개: "받은 파일 N개" + 검색창 + 받은 파일 목록(꺼져 있어도 유지)
///
/// *** 중요: "기기가 알아서 블루투스로 찾아줌"은 구현하지 않는다 ***
/// 이 디자인은 안드로이드 시스템의 "근처 공유"(Nearby Share)를 그대로 본뜬
/// 화면이다 — 그 기능 자체(블루투스/Wi-Fi Direct로 임의 기기를 자동 탐색)는
/// OS 네이티브 전용이라 일반 앱이 그대로 재현할 수 없다. 대신 **"사용중"
/// 토글은 같은 와이파이 안에서 서로를 찾는 실제 기능으로 동작한다**
/// (mDNS/DNS-SD, [nsd] 패키지) — 토글을 켜면 내 기기를 광고하는 동시에
/// 같은 와이파이의 다른 사람들을 찾는다. 블루투스가 아니라 **같은
/// 와이파이에 있어야만** 서로 보인다는 점이 실제 "근처 공유"와 다르다.
/// iOS는 이 기능을 처음 쓸 때 "로컬 네트워크에서 기기를 찾으려고 합니다"
/// 권한 팝업이 한 번 뜬다(iOS 정책, 앱에서 막을 수 없음).
///
/// 참고 스크린샷은 발견된 사람마다 이름/학과/학번을 보여주지만, 실제
/// mDNS 광고 이름은 로그인한 학생 이름이 아니라 [_deviceLabel](임의
/// 번호가 붙은 앱 이름)이라 그 정보를 그대로 보여줄 수 없다 — 지어내지
/// 않고 광고된 이름 그대로("우진이의 하루 - 1234" 식)만 보여준다. 같은
/// 이유로 사람별 "보내기" 버튼도 그 사람에게만 보내는 실제 전송이 아니라
/// (특정 상대 타겟 전송은 아직 없음, 아래 "1단계" 설명 참고) 전체
/// "내 파일 보내기"와 같은 동작(파일 선택 → OS 공유 시트)을 그대로 쓴다.
///
/// 1단계(이 커밋)는 "서로 찾기"까지만 — 찾은 상대에게 실제로 파일을
/// 전송하는 건 2단계(다음 작업)에서 추가한다. 그동안은 보내기/받기 둘 다
/// 아래 설명대로 OS 공유 시트/공유 수신으로 별도 동작한다.
///
/// **보내기/받기는 실제로 동작한다**(둘 다 사용자 요청으로 추가):
/// - 보내기: [FilePicker]로 기기에서 파일을 고르면, OS가 원래 제공하는
///   "공유하기" 시트([SharePlus])로 넘긴다 — 그 시트 안에 블루투스 공유/
///   AirDrop/카카오톡 등 실제 전송 수단이 이미 다 있어서, 앱이 직접 기기를
///   찾지 않고도 진짜로 파일을 보낼 수 있다.
/// - 받기: 다른 앱의 "공유하기" 메뉴에서 이 앱(우진이의 하루)을 고르면
///   [ReceiveSharingIntent]가 그 파일을 실제로 받아 아래 목록에 띄운다.
///   받은 파일의 용량은 실제 파일 크기([File.length])를 읽어 보여주고,
///   받은 시각도 받은 순간을 기록해 "방금"/"N분 전"으로 보여준다 — 둘 다
///   지어낸 값이 아니다. 다만 "보낸 사람 이름"은 공유 수신 데이터 자체에
///   없어서 표시하지 않는다. **받기는 안드로이드 전용이다** — iOS는 별도
///   Xcode Share Extension 타겟을 새로 만들어야 받을 수 있는데, 그건 Xcode
///   프로젝트 조작이 필요해서 이 환경에서 만들고 빌드 검증할 방법이 없다
///   (iOS에서는 조용히 안 받아질 뿐 크래시는 안 난다).
///
/// "파일명 검색"은 여전히 가짜 UI다.
class FileShareScreen extends StatefulWidget {
  const FileShareScreen({super.key});

  @override
  State<FileShareScreen> createState() => _FileShareScreenState();
}

class _FileShareScreenState extends State<FileShareScreen> {
  // mDNS 서비스 타입("_라벨._tcp") — 라벨은 영문/숫자/하이픈만, 1~15자여야
  // 한다(nsd 패키지 규칙). 2단계(실제 전송)에서 실제 포트로 등록을 다시
  // 걸기 전까지는 포트 값 자체는 의미 없어 임시 고정값을 쓴다.
  static const _serviceType = '_daejinshare._tcp';
  static const _placeholderPort = 52525;

  bool _enabled = false;
  final _searchController = TextEditingController();

  // TEMP: 화면 미리보기용 임시 데모 스위치(사용자 요청) — 받은 파일이 있으면
  // 레이더 화면보다 우선 보이는 실제 로직(showRadar) 때문에 둘을 동시에
  // true로 두면 레이더를 못 본다. 지금은 "주변 사람" 쪽을 보기로 해서
  // 받은 파일 데모는 꺼뒀다. 나중에 지울 것 — 둘 다 실제 데이터 아님.
  static const bool _kShowReceivedFilesDemo = false;
  static const bool _kShowNearbyPeersDemo = false;

  // TEMP: 실제 공유 수신 없이도 "받은 파일" 상태를 바로 볼 수 있게 넣어둔
  // 임시 데모 데이터. 나중에 지울 것 — 실제로 받은 파일이 아님.
  final List<ReceivedFile> _receivedFiles = _kShowReceivedFilesDemo
      ? [
          ReceivedFile(
            file: SharedMediaFile(
              path: '/tmp/자료구조_3주차.pdf',
              type: SharedMediaType.file,
            ),
            receivedAt: DateTime.now(),
          )..sizeBytes = 2516582,
          ReceivedFile(
            file: SharedMediaFile(
              path: '/tmp/이산수학_요약.docx',
              type: SharedMediaType.file,
            ),
            receivedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          )..sizeBytes = 870400,
        ]
      : [];

  // TEMP: 실제로 같은 와이파이에서 찾아낸 사람이 없어도 "주변 사람" 레이더
  // 화면을 바로 볼 수 있게 넣어둔 임시 데모 데이터. 나중에 지울 것 — 실제로
  // 발견된 사람이 아니다(실제 발견 이름은 mDNS 광고 이름 그대로만 보여줄 수
  // 있다는 점은 클래스 문서 참고).
  static final List<nsd.Service> _demoNearbyPeers = [
    nsd.Service(name: '김지아', type: _serviceType, port: _placeholderPort),
    nsd.Service(name: '이현우', type: _serviceType, port: _placeholderPort),
    nsd.Service(name: '박수민', type: _serviceType, port: _placeholderPort),
  ];

  StreamSubscription<List<SharedMediaFile>>? _mediaStreamSub;

  /// 같은 와이파이에 내 기기를 알릴 이름. 여러 명이 동시에 테스트해도
  /// 구분되게 임의 번호를 붙인다. 세션 동안 고정.
  late final String _deviceLabel = '우진이의 하루 - ${Random().nextInt(9000) + 1000}';

  nsd.Registration? _registration;
  nsd.Discovery? _discovery;

  @override
  void initState() {
    super.initState();
    _loadInitialSharedFiles();
    _mediaStreamSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => _addReceivedFiles(files),
      onError: (Object e) => debugPrint('[FileShare] 공유 스트림 오류: $e'),
    );
    // TEMP: 데모용 받은 파일 목록이 실제로 존재하는 파일을 가리키게
    // 만들어둔다 — 그래야 "다운로드"를 눌러도 실패하지 않는다.
    unawaited(_materializeDemoFiles());
  }

  Future<void> _materializeDemoFiles() async {
    try {
      for (final entry in _receivedFiles) {
        final size = entry.sizeBytes;
        if (size == null) continue;
        await File(entry.file.path).writeAsBytes(List<int>.filled(size, 0));
      }
    } catch (e) {
      debugPrint('[FileShare] 데모 파일 생성 실패: $e');
    }
  }

  /// 앱이 꺼져 있다가 "공유하기"로 실행됐을 때 받은 파일(있다면)을 불러온다.
  Future<void> _loadInitialSharedFiles() async {
    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();
      if (!mounted || files.isEmpty) return;
      _addReceivedFiles(files);
      await ReceiveSharingIntent.instance.reset();
    } catch (e) {
      debugPrint('[FileShare] 초기 공유 파일 조회 실패: $e');
    }
  }

  /// 새로 받은 파일을 받은 시각과 함께 목록 맨 앞에 바로 쌓는다. 실제
  /// 용량은 조회가 느리거나(큰 파일) 실패할 수 있어 목록 표시를 막지
  /// 않도록 뒤이어 따로 채운다([_fillSize]).
  void _addReceivedFiles(List<SharedMediaFile> files) {
    final now = DateTime.now();
    final entries = files
        .map((file) => ReceivedFile(file: file, receivedAt: now))
        .toList();
    if (!mounted) return;
    setState(() => _receivedFiles.insertAll(0, entries));
    for (final entry in entries) {
      unawaited(_fillSize(entry));
    }
  }

  Future<void> _fillSize(ReceivedFile entry) async {
    try {
      final size = await File(entry.file.path).length();
      if (!mounted) return;
      setState(() => entry.sizeBytes = size);
    } catch (e) {
      debugPrint('[FileShare] 파일 용량 조회 실패: $e');
    }
  }

  void _setEnabled(bool enabled) {
    setState(() => _enabled = enabled);
    // 꺼져 있을 땐 광고/탐색을 돌릴 이유가 없어(배터리 낭비) 켤 때만
    // 시작하고 끌 때 반드시 멈춘다.
    if (enabled) {
      _startAdvertisingAndDiscovery();
    } else {
      _stopAdvertisingAndDiscovery();
    }
  }

  /// 같은 와이파이에 내 기기를 광고하는 동시에, 그 와이파이의 다른
  /// 기기들을 찾기 시작한다. 권한 거부/네트워크 문제 등으로 실패하면
  /// 토글을 다시 꺼진 상태로 되돌리고 이유를 스낵바로 보여준다.
  Future<void> _startAdvertisingAndDiscovery() async {
    nsd.Registration? registration;
    try {
      registration = await nsd.register(
        nsd.Service(
          name: _deviceLabel,
          type: _serviceType,
          port: _placeholderPort,
        ),
      );
      final discovery = await nsd.startDiscovery(_serviceType);
      discovery.addListener(_onDiscoveryChanged);
      if (!mounted) {
        await nsd.unregister(registration);
        await nsd.stopDiscovery(discovery);
        return;
      }
      setState(() {
        _registration = registration;
        _discovery = discovery;
      });
    } catch (e) {
      // 광고(register)는 성공했는데 그다음 탐색 시작이 실패하면, 광고만
      // 켜진 채로 방치되지 않도록 반드시 등록을 해제한다 — 안 그러면
      // 꺼짐으로 보이는 화면 뒤에서 계속 다른 사람에게 광고되는 상태가
      // 남는다.
      if (registration != null) {
        try {
          await nsd.unregister(registration);
        } catch (_) {
          // 등록 해제 실패는 원래 에러(아래 스낵바)를 가릴 필요 없이 무시.
        }
      }
      if (!mounted) return;
      setState(() => _enabled = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('주변 탐색을 시작하지 못했어요: $e')));
    }
  }

  Future<void> _stopAdvertisingAndDiscovery() async {
    final registration = _registration;
    final discovery = _discovery;
    _registration = null;
    _discovery = null;
    discovery?.removeListener(_onDiscoveryChanged);
    if (registration != null) {
      try {
        await nsd.unregister(registration);
      } catch (e) {
        debugPrint('[FileShare] 광고 중지 실패: $e');
      }
    }
    if (discovery != null) {
      try {
        await nsd.stopDiscovery(discovery);
      } catch (e) {
        debugPrint('[FileShare] 탐색 중지 실패: $e');
      }
    }
  }

  void _onDiscoveryChanged() {
    if (mounted) setState(() {});
  }

  /// 탐색된 서비스 중 내 기기 자신을 뺀 목록(같은 와이파이의 다른 사람들).
  List<nsd.Service> get _discoveredPeers {
    final myName = _registration?.service.name ?? _deviceLabel;
    final real = (_discovery?.services ?? const [])
        .where((s) => s.name != myName)
        .toList();
    return _kShowNearbyPeersDemo ? [..._demoNearbyPeers, ...real] : real;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mediaStreamSub?.cancel();
    _stopAdvertisingAndDiscovery();
    super.dispose();
  }

  /// 기기에서 파일을 고른 뒤 OS의 실제 "공유하기" 시트로 넘긴다. 취소/실패는
  /// 조용히 처리하되(사용자가 그냥 마음을 바꾼 흔한 경우), 공유 시트 자체를
  /// 못 띄운 경우에만 스낵바로 알린다. 레이더의 사람별 "보내기"도 특정
  /// 상대에게 보내는 실제 전송이 없어 이 동작을 그대로 재사용한다.
  Future<void> _sendFile() async {
    final PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('파일을 선택하지 못했어요: $e')));
      return;
    }
    if (picked == null) return; // 사용자가 선택 창을 취소함.

    try {
      await SharePlus.instance.share(ShareParams(files: [picked.xFile]));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('공유 시트를 열지 못했어요: $e')));
    }
  }

  /// 받은 파일(지금은 임시 캐시 폴더에만 있는 상태)을 원하는 곳에 저장할
  /// 수 있게 OS "공유하기" 시트로 넘긴다 — [SharePlus]가 iOS에서는 "파일에
  /// 저장"을, 안드로이드에서는 공유 대상 앱들을 보여준다. 앱이 자체
  /// 다운로드 폴더를 만들어 직접 파일을 복사하는 기능은 아직 없다.
  Future<void> _downloadFile(ReceivedFile entry) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(entry.file.path)]),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('파일을 저장하지 못했어요: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final peers = _enabled ? _discoveredPeers : const <nsd.Service>[];
    final hasReceived = _receivedFiles.isNotEmpty;
    // 켜져 있고 받은 파일이 아직 없을 때만 레이더 화면을 보여준다 — 받은
    // 파일이 생기면(꺼졌더라도) 그쪽이 더 쓸모 있어서 우선한다.
    final showRadar = _enabled && !hasReceived;

    return Scaffold(
      // 키보드 양옆 둥근 모서리 틈으로 Scaffold 바탕이 비쳐 파랑이 보이지
      // 않도록, 바탕은 흰색으로 두고 파랑은 body 영역에만 깐다.
      backgroundColor: Colors.white,
      body: ColoredBox(
        color: AppColors.cobalt,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.cobaltDeep,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            '파일공유',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _titleFor(
                            enabled: _enabled,
                            receivedCount: _receivedFiles.length,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.035,
                            height: 1.22,
                          ),
                        ),
                      ],
                    ),
                    const Positioned(
                      top: 20,
                      left: 240,
                      child: MascotSticker(width: 120),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      16 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(peers.length),
                        const SizedBox(height: 16),
                        Expanded(
                          child: showRadar
                              ? _buildDiscoverySection(peers)
                              : _buildReceivedFilesSection(),
                        ),
                        const SizedBox(height: 14),
                        _buildSendButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _titleFor({required bool enabled, required int receivedCount}) {
    if (receivedCount > 0) return '받은 파일\n$receivedCount개';
    if (enabled) return '주변에서\n찾는 중이에요';
    return '주변 친구와\n자료 주고받기';
  }

  Widget _buildStatusCard(int peerCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.cobalt,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_tethering,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _enabled ? '사용 중' : '사용 안 함',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _enabled ? '주변에 내가 보이는 중이에요' : '꺼져 있어요',
                      style: const TextStyle(color: mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                activeTrackColor: AppColors.cobalt,
                activeThumbColor: Colors.white,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD8D8DE),
                trackOutlineColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                onChanged: _setEnabled,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _enabled
                ? '주변 사람 $peerCount명이 발견됐어요.'
                : '파일공유 기능을 활성화하면 발견된 사람이 여기 떠요.',
            style: const TextStyle(color: mutedText, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _enabled ? _sendFile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cobalt,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.cobalt.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.ios_share, size: 18),
        label: const Text(
          '내 파일 보내기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ── 레이더(켜짐 + 받은 파일 0개) ────────────────────────────────────

  Widget _buildDiscoverySection(List<nsd.Service> peers) {
    if (peers.isEmpty) {
      return const Center(
        child: Text(
          '아직 발견된 사람이 없어요.\n상대방도 파일공유 기능을 활성화해야 보여요!',
          textAlign: TextAlign.center,
          style: TextStyle(color: mutedText, fontSize: 13, height: 1.4),
        ),
      );
    }

    return ListView(
      children: [
        SizedBox(height: 220, child: RadarView(peers: peers)),
        const SizedBox(height: 12),
        const Text(
          '주변 사람',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < peers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PeerRow(
              peer: peers[i],
              color: avatarColors[i % avatarColors.length],
              onSend: _sendFile,
            ),
          ),
      ],
    );
  }

  // ── 받은 파일 목록(받은 파일 ≥1개) ──────────────────────────────────

  Widget _buildReceivedFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F0F7),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppColors.ink, fontSize: 14),
            decoration: const InputDecoration(
              icon: Icon(Icons.search, color: mutedText, size: 18),
              hintText: '파일명 검색',
              hintStyle: TextStyle(color: mutedText),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildReceivedFilesList()),
      ],
    );
  }

  Widget _buildReceivedFilesList() {
    final query = _searchController.text.trim();
    final files = query.isEmpty
        ? _receivedFiles
        : _receivedFiles
              .where(
                (f) =>
                    _fileNameFromPath(f.file.path)
                        .toLowerCase()
                        .contains(query.toLowerCase()),
              )
              .toList();

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F0F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.desktop_windows_outlined,
                color: mutedText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              query.isEmpty ? '아직 받은 파일이 없어요' : '검색 결과가 없어요',
              style: const TextStyle(color: mutedText, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: files.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => ReceivedFileRow(
        entry: files[index],
        onDownload: () => _downloadFile(files[index]),
      ),
    );
  }

  String _fileNameFromPath(String path) {
    final idx = path.lastIndexOf('/');
    return idx == -1 ? path : path.substring(idx + 1);
  }
}
