import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/theme_helper.dart';

class AppbarTitle extends StatelessWidget {
  AppbarTitle({
    Key? key,
    required this.text,
    this.margin,
    this.onTap,
    this.textColor, // New parameter for default text color
  }) : super(key: key);

  final String text;
  final EdgeInsetsGeometry? margin;
  final Function? onTap;
  final Color? textColor; // New parameter for default text color

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap as void Function()?,
      child: Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Text(
          text,
          style: TextStyle(
            color: textColor ?? appTheme.realBlack, // Use default color if not provided
          ),
        ),
      ),
    );
  }
}
