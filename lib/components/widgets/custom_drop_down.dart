import 'package:econaga_prj/components/core/utils/size_utils.dart';
import 'package:flutter/material.dart';
import '../core/app_export.dart';
import '../theme/custom_text_style.dart';

class CustomDropDown extends StatelessWidget {
  final Alignment? alignment;
  final double? width;
  final FocusNode? focusNode;
  final Widget? icon;
  final bool? autofocus;
  final TextStyle? textStyle;
  final List<String>? items;
  final String? hintText;
  final TextStyle? hintStyle;
  final Widget? prefix;
  final BoxConstraints? prefixConstraints;
  final Widget? suffix;
  final BoxConstraints? suffixConstraints;
  final EdgeInsets? contentPadding;
  final InputBorder? borderDecoration;
  final Color? fillColor;
  final bool? filled;
  final FormFieldValidator<String>? validator;
  final Function(String)? onChanged;
  final Color? backgroundColor;
  final Color? textColor;

  CustomDropDown({
    Key? key,
    this.alignment,
    this.width,
    this.focusNode,
    this.icon,
    this.autofocus = true,
    this.textStyle,
    this.items,
    this.hintText,
    this.hintStyle,
    this.prefix,
    this.prefixConstraints,
    this.suffix,
    this.suffixConstraints,
    this.contentPadding,
    this.borderDecoration,
    this.fillColor,
    this.filled = true,
    this.validator,
    this.onChanged,
    required this.backgroundColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
      alignment: alignment!,
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: backgroundColor,
          buttonTheme: ButtonTheme.of(context).copyWith(
            alignedDropdown: true,
            textTheme: ButtonTextTheme.primary,
          ),
        ),
        child: dropDownWidget,
      ),
    )
        : Theme(
      data: Theme.of(context).copyWith(
        canvasColor: backgroundColor,
        buttonTheme: ButtonTheme.of(context).copyWith(
          alignedDropdown: true,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      child: dropDownWidget,
    );
  }

  Widget get dropDownWidget => SizedBox(
    width: width ?? double.maxFinite,
    child: DropdownButtonFormField<String>(
      focusNode: focusNode ?? FocusNode(),
      icon: icon,
      autofocus: autofocus!,
      style: textStyle ?? CustomTextStyles.bodyMediumBluegray100,
      items: items?.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Align(
            alignment: Alignment.centerLeft, // Align text to the left
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
              ),
            ),
          ),
        );
      }).toList(),
      decoration: decoration,
      validator: validator,
      onChanged: (value) {
        if (onChanged != null) {
          onChanged!(value.toString());
        }
      },
    ),
  );

  InputDecoration get decoration => InputDecoration(
    hintText: hintText ?? "",
    hintStyle: CustomTextStyles.titleMediumBluegray400,
    prefixIcon: prefix,
    prefixIconConstraints: prefixConstraints ?? BoxConstraints(maxHeight: 60.0),
    suffixIcon: suffix,
    suffixIconConstraints: suffixConstraints,
    isDense: true,
    contentPadding: contentPadding ?? EdgeInsets.only(top: 21.0, right: 30.0, bottom: 21.0),
    fillColor: fillColor ?? const Color(0xFF86CF64),
    filled: filled,
    border: borderDecoration ??
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.h),
          borderSide: BorderSide.none,
        ),
    enabledBorder: borderDecoration ??
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.h),
          borderSide: BorderSide.none,
        ),
    focusedBorder: borderDecoration ??
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.h),
          borderSide: BorderSide.none,
        ),
  );
}
