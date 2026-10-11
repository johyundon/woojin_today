import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/app_colors.dart';

/// "파일공유" 화면 (Figma node 6:112, 스크린샷 3장 평탄화 상태 — 다른 화면과
/// 같은 선례를 따라 눈으로 보고 근사 구현했다).
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
///   **안드로이드 전용이다** — iOS는 별도 Xcode Share Extension 타겟을
///   새로 만들어야 받을 수 있는데, 그건 Xcode 프로젝트 조작이 필요해서 이
///   환경에서 만들고 빌드 검증할 방법이 없다(iOS에서는 조용히 안 받아질
///   뿐 크래시는 안 난다).
///
/// "저장위치 열기"/"파일명 검색"은 여전히 가짜 UI다.
class FileShareScreen extends StatefulWidget {
  const FileShareScreen({super.key});

  @override
  State<FileShareScreen> createState() => _FileShareScreenState();
}

class _FileShareScreenState extends State<FileShareScreen>
    with SingleTickerProviderStateMixin {
  // mDNS 서비스 타입("_라벨._tcp") — 라벨은 영문/숫자/하이픈만, 1~15자여야
  // 한다(nsd 패키지 규칙). 2단계(실제 전송)에서 실제 포트로 등록을 다시
  // 걸기 전까지는 포트 값 자체는 의미 없어 임시 고정값을 쓴다.
  static const _serviceType = '_daejinshare._tcp';
  static const _placeholderPort = 52525;

  bool _enabled = false;
  final _searchController = TextEditingController();
  late final AnimationController _spinController;

  final List<SharedMediaFile> _receivedFiles = [];
  StreamSubscription<List<SharedMediaFile>>? _mediaStreamSub;

  /// 같은 와이파이에 내 기기를 알릴 이름. 여러 명이 동시에 테스트해도
  /// 구분되게 임의 번호를 붙인다. 세션 동안 고정.
  late final String _deviceLabel = '우진이의 하루 - ${Random().nextInt(9000) + 1000}';

  nsd.Registration? _registration;
  nsd.Discovery? _discovery;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 200),
    );
    _loadInitialSharedFiles();
    _mediaStreamSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => setState(() => _receivedFiles.insertAll(0, files)),
      onError: (Object e) => debugPrint('[FileShare] 공유 스트림 오류: $e'),
    );
  }

  /// 앱이 꺼져 있다가 "공유하기"로 실행됐을 때 받은 파일(있다면)을 불러온다.
  Future<void> _loadInitialSharedFiles() async {
    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();
      if (!mounted || files.isEmpty) return;
      setState(() => _receivedFiles.insertAll(0, files));
      await ReceiveSharingIntent.instance.reset();
    } catch (e) {
      debugPrint('[FileShare] 초기 공유 파일 조회 실패: $e');
    }
  }

  void _setEnabled(bool enabled) {
    setState(() => _enabled = enabled);
    // 꺼져 있을 땐 아이콘도 안 보이는데 애니메이션만 계속 돌리면 배터리
    // 낭비라, 켤 때만 돌리고 끌 때 멈춘다. 광고/탐색도 마찬가지 이유로
    // 켤 때만 시작하고 끌 때 반드시 멈춘다.
    if (enabled) {
      _spinController.repeat();
      _startAdvertisingAndDiscovery();
    } else {
      _spinController.stop();
      _stopAdvertisingAndDiscovery();
    }
  }

  /// 같은 와이파이에 내 기기를 광고하는 동시에, 그 와이파이의 다른
  /// 기기들을 찾기 시작한다. 권한 거부/네트워크 문제 등으로 실패하면
  /// 토글을 다시 꺼진 상태로 되돌리고 이유를 스낵바로 보여준다.
  Future<void> _startAdvertisingAndDiscovery() async {
    try {
      final registration = await nsd.register(
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
      if (!mounted) return;
      setState(() => _enabled = false);
      _spinController.stop();
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
    return (_discovery?.services ?? const [])
        .where((s) => s.name != myName)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _spinController.dispose();
    _mediaStreamSub?.cancel();
    _stopAdvertisingAndDiscovery();
    super.dispose();
  }

  void _openStorageLocation() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('저장위치 열기는 지원하지 않아요')));
  }

  /// 기기에서 파일을 고른 뒤 OS의 실제 "공유하기" 시트로 넘긴다. 취소/실패는
  /// 조용히 처리하되(사용자가 그냥 마음을 바꾼 흔한 경우), 공유 시트 자체를
  /// 못 띄운 경우에만 스낵바로 알린다.
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

  Widget _buildReceivedFilesArea() {
    if (_receivedFiles.isEmpty) {
      return const Center(
        child: Text(
          '아직 받은 파일이 없어요.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _receivedFiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final file = _receivedFiles[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _fileNameFromPath(file.path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 공유로 받은 파일 경로("/data/.../abc.pdf")에서 파일명만 뽑는다. 경로
  /// 조작용으로 `package:path`를 새로 받을 만큼 복잡하지 않아 직접 자른다.
  String _fileNameFromPath(String path) {
    final idx = path.lastIndexOf('/');
    return idx == -1 ? path : path.substring(idx + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 4),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildSearchField(),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _openStorageLocation,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '저장위치 열기',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text(
                        '내 파일 보내기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildReceivedFilesArea()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _enabled ? '사용중' : '사용 안 함',
                style: TextStyle(
                  color: _enabled ? AppColors.accent : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_enabled) ...[
                RotationTransition(
                  turns: _spinController,
                  child: const Icon(
                    Icons.refresh,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Switch(
                value: _enabled,
                activeTrackColor: AppColors.accent,
                onChanged: _setEnabled,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          _buildDiscoverySection(),
        ],
      ),
    );
  }

  Widget _buildDiscoverySection() {
    final peers = _enabled ? _discoveredPeers : const <nsd.Service>[];

    if (peers.isEmpty) {
      // 부모 Column이 crossAxisAlignment.start라 Text에 textAlign만 주면
      // 텍스트 박스 자체가 내용 너비로 줄어들어 가운데 정렬처럼 안 보인다
      // — 카드 전체 너비로 늘려야 진짜로 가운데 온다.
      return SizedBox(
        width: double.infinity,
        child: Text(
          _enabled
              ? '아직 발견된 사람이 없어요.\n상대방도 파일공유 기능을 활성화해야 보여요!'
              : '파일공유 기능을 활성화하면 발견된 사람이 여기 떠요.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final peer in peers)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.smartphone, size: 18, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    peer.name ?? '이름 없는 기기',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: '파일명 검색',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}
