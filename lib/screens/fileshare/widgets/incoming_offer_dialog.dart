import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/file_transfer.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../received_file_format.dart';

/// 누가 파일을 보내려 할 때 "받기/거절"을 묻는다. [timeout] 안에 답하지
/// 않으면 창을 닫고 거절로 친다 — 보내는 쪽이 무한정 기다리지 않게,
/// 보내는 쪽 대기 시간(60초)보다 조금 짧게 잡는다.
Future<bool> showIncomingOfferDialog(
  BuildContext context,
  FileOffer offer, {
  Duration timeout = const Duration(seconds: 50),
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var open = true;
  final timer = Timer(timeout, () {
    if (open) navigator.pop(false);
  });
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => IncomingOfferDialog(offer: offer),
  );
  open = false;
  timer.cancel();
  return result ?? false;
}

class IncomingOfferDialog extends StatelessWidget {
  const IncomingOfferDialog({super.key, required this.offer});

  final FileOffer offer;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '파일을 받을까요?',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${offer.senderName}에서 보내려고 해요.',
              style: const TextStyle(color: AppColors.textSub, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatBytes(offer.sizeBytes),
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: '거절',
                    background: AppColors.fill,
                    foreground: AppColors.textStrong,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: '받기',
                    background: AppColors.blue,
                    foreground: Colors.white,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.96,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
