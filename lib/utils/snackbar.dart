import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

enum SnackType { success, error, warning, info }

class AppSnackBar {
  AppSnackBar._();

  static void show(BuildContext context, String message, {SnackType type = SnackType.success}) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final config = _configs[type]!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: config.iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(config.icon, color: config.iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xff1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: config.borderColor, width: 1),
        ),
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: Duration(milliseconds: type == SnackType.error ? 4000 : 2500),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: SnackType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: SnackType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message, type: SnackType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message, type: SnackType.info);
}

class _SnackConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color borderColor;
  const _SnackConfig(this.icon, this.iconColor, this.iconBg, this.borderColor);
}

const _configs = <SnackType, _SnackConfig>{
  SnackType.success: _SnackConfig(
    Iconsax.tick_circle,
    Color(0xff16A34A),
    Color(0xffDCFCE7),
    Color(0xffBBF7D0),
  ),
  SnackType.error: _SnackConfig(
    Iconsax.close_circle,
    Color(0xffDC2626),
    Color(0xffFEE2E2),
    Color(0xffFECACA),
  ),
  SnackType.warning: _SnackConfig(
    Iconsax.warning_2,
    Color(0xffD97706),
    Color(0xffFEF3C7),
    Color(0xffFDE68A),
  ),
  SnackType.info: _SnackConfig(
    Iconsax.info_circle,
    Color(0xff2563EB),
    Color(0xffDBEAFE),
    Color(0xffBFDBFE),
  ),
};
