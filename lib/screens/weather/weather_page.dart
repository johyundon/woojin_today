import 'package:flutter/material.dart';

import '../../services/air_quality_service.dart';
import '../../services/weather_service.dart';
import '../../theme/app_colors.dart';
import 'weather_screen.dart';

/// 날씨를 직접 조회한 뒤 [WeatherScreen]을 보여주는 진입 화면. 모아보기처럼
/// 날씨 데이터를 들고 있지 않은 곳에서 연다. 조회 중에는 스피너, 실패하면
/// 안내 문구와 "다시 시도" 버튼을 보여준다.
class WeatherPage extends StatefulWidget {
  const WeatherPage({this.service, this.airQualityService, super.key});

  /// 테스트에서 mock을 주입하기 위한 옵션. 기본값은 실제 서비스.
  final WeatherService? service;
  final AirQualityService? airQualityService;

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late final WeatherService _service = widget.service ?? WeatherService();
  late final AirQualityService _airService =
      widget.airQualityService ?? AirQualityService();
  WeatherResponse? _weather;
  AirQuality? _airQuality;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _hasError = false);
    try {
      // 미세먼지는 덤이라 실패해도 날씨 화면은 띄운다(카드에 "-" 표시).
      final airFuture = _airService.fetchAirQuality().then<AirQuality?>(
        (air) => air,
        onError: (Object e) {
          debugPrint('[Weather] 미세먼지 조회 실패: $e');
          return null;
        },
      );
      final weather = await _service.fetchWeather();
      final air = await airFuture;
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _airQuality = air;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    if (weather != null) {
      return WeatherScreen(weather: weather, airQuality: _airQuality);
    }

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 0, 0),
              child: GestureDetector(
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
            ),
            Center(
              child: _hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '날씨를 불러오지 못했어요',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lime,
                            foregroundColor: AppColors.ink,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            '다시 시도',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
