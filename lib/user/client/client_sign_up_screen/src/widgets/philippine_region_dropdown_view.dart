import 'package:econaga_prj/components/core/utils/size_utils.dart';
import 'package:flutter/material.dart';
import '../../../../../components/theme/custom_text_style.dart';
import '../../../../../components/widgets/custom_image_view.dart';
import '../philippines_rpcmb.dart';

typedef DropdownItemBuilder<T> = DropdownMenuItem<T> Function(BuildContext context, T value);
typedef SelectedItemBuilder<T> = Widget Function(BuildContext context, T value);

class _PhilippineDropdownView<T> extends StatelessWidget {
  const _PhilippineDropdownView({
    Key? key,
    required this.choices,
    required this.onChanged,
    this.value,
    required this.itemBuilder,
    required this.hint,
    required this.selectedItemBuilder,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    final bool? filled,
    this.contentPadding,
    this.borderDecoration,
    this.prefix,
    this.prefixConstraints,
    this.suffix,
    this.suffixConstraints,
  }) : super(key: key);

  final List<T> choices;
  final ValueChanged<T?> onChanged;
  final T? value;
  final DropdownItemBuilder<T> itemBuilder;
  final SelectedItemBuilder<T> selectedItemBuilder;
  final Widget hint;
  final Color backgroundColor;
  final Color textColor;
  final EdgeInsets? contentPadding;
  final bool filled = true;
  final InputBorder? borderDecoration;
  final Widget? prefix;
  final BoxConstraints? prefixConstraints;
  final Widget? suffix;
  final BoxConstraints? suffixConstraints;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: backgroundColor,
          buttonTheme: ButtonTheme.of(context).copyWith(
            alignedDropdown: true,
            textTheme: ButtonTextTheme.primary,
          ),
        ),
        child: SizedBox(
          width: double.maxFinite,
          child: DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            items: choices.map((e) => itemBuilder.call(context, e)).toList(),
            hint: hint,
            style: TextStyle(color: textColor),
            selectedItemBuilder: (BuildContext context) {
              return choices.map((e) => selectedItemBuilder.call(context, e)).toList();
            },
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint is Text ? (hint as Text).data : "",
              hintStyle: CustomTextStyles.titleMediumBluegray400,
              prefixIcon: prefix,
              prefixIconConstraints: prefixConstraints ?? BoxConstraints(maxHeight: 60.0),
              suffixIcon: suffix,
              suffixIconConstraints: suffixConstraints,
              isDense: true,
              contentPadding: contentPadding ?? EdgeInsets.only(top: 21.0, right: 30.0, bottom: 21.0),
              fillColor: const Color(0xFF86CF64),
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
            ),
          ),
        ),
      ),
    );
  }
}

class PhilippineRegionDropdownView extends StatelessWidget {
  const PhilippineRegionDropdownView({
    Key? key,
    this.regions = philippineRegions,
    required this.onChanged,
    this.value,
    this.itemBuilder,
    this.iconPath, // Add iconPath parameter
  }) : super(key: key);

  final List<Region> regions;
  final ValueChanged<Region?> onChanged;
  final Region? value;
  final DropdownItemBuilder<Region>? itemBuilder;
  final String? iconPath; // Add iconPath parameter

  @override
  Widget build(BuildContext context) {
    return _PhilippineDropdownView(
      choices: regions,
      onChanged: onChanged,
      value: value,
      itemBuilder: (BuildContext context, e) {
        return itemBuilder?.call(context, e) ?? DropdownMenuItem(value: e, child: Text(e.regionName));
      },
      hint: Text(
        'Select Region',
        style: CustomTextStyles.titleMediumBluegray400,
      ),
      selectedItemBuilder: (BuildContext context, Region value) {
        return Text(
          value.regionName,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white),
        );
      },
      prefix: iconPath != null
          ? Container(
        margin: EdgeInsets.fromLTRB(20.0, 20.0, 12.0, 20.0),
        child: CustomImageView(
          imagePath: iconPath!,
          height: 20.0,
          width: 20.0,
        ),
      )
          : null,
      prefixConstraints: BoxConstraints(maxHeight: 60.0),
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Match padding with CustomDropDown
    );
  }
}

class PhilippineProvinceDropdownView extends StatelessWidget {
  const PhilippineProvinceDropdownView({
    Key? key,
    required this.provinces,
    required this.onChanged,
    this.value,
    this.itemBuilder,
    this.iconPath, // Add iconPath parameter
  }) : super(key: key);

  final List<Province> provinces;
  final Province? value;
  final ValueChanged<Province?> onChanged;
  final DropdownItemBuilder<Province>? itemBuilder;
  final String? iconPath; // Add iconPath parameter

  @override
  Widget build(BuildContext context) {
    return _PhilippineDropdownView(
      choices: provinces,
      onChanged: onChanged,
      value: value,
      itemBuilder: (BuildContext context, e) {
        return itemBuilder?.call(context, e) ?? DropdownMenuItem(value: e, child: Text(e.name));
      },
      hint: Text(
        'Select Province',
        style: CustomTextStyles.titleMediumBluegray400,
      ),
      selectedItemBuilder: (BuildContext context, Province value) {
        return Text(
          value.name,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white),
        );
      },
      prefix: iconPath != null
          ? Container(
        margin: EdgeInsets.fromLTRB(20.0, 20.0, 12.0, 20.0),
        child: CustomImageView(
          imagePath: iconPath!,
          height: 20.0,
          width: 20.0,
        ),
      )
          : null,
      prefixConstraints: BoxConstraints(maxHeight: 60.0),
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Match padding with CustomDropDown
    );
  }
}

class PhilippineMunicipalityDropdownView extends StatelessWidget {
  const PhilippineMunicipalityDropdownView({
    Key? key,
    required this.municipalities,
    required this.onChanged,
    this.value,
    this.itemBuilder,
    this.iconPath, // Add iconPath parameter
  }) : super(key: key);

  final List<Municipality> municipalities;
  final Municipality? value;
  final ValueChanged<Municipality?> onChanged;
  final DropdownItemBuilder<Municipality>? itemBuilder;
  final String? iconPath; // Add iconPath parameter

  @override
  Widget build(BuildContext context) {
    return _PhilippineDropdownView(
      choices: municipalities,
      onChanged: onChanged,
      value: value,
      itemBuilder: (BuildContext context, e) {
        return itemBuilder?.call(context, e) ?? DropdownMenuItem(value: e, child: Text(e.name));
      },
      hint: Text(
        'Select Municipality',
        style: CustomTextStyles.titleMediumBluegray400,
      ),
      selectedItemBuilder: (BuildContext context, Municipality value) {
        return Text(
          value.name,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white),
        );
      },
      prefix: iconPath != null
          ? Container(
        margin: EdgeInsets.fromLTRB(20.0, 20.0, 12.0, 20.0),
        child: CustomImageView(
          imagePath: iconPath!,
          height: 20.0,
          width: 20.0,
        ),
      )
          : null,
      prefixConstraints: BoxConstraints(maxHeight: 60.0),
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Match padding with CustomDropDown
    );
  }
}

class PhilippineBarangayDropdownView extends StatelessWidget {
  const PhilippineBarangayDropdownView({
    Key? key,
    required this.barangays,
    required this.onChanged,
    this.value,
    this.itemBuilder,
    this.iconPath, // Add iconPath parameter
  }) : super(key: key);

  final List<String> barangays;
  final String? value;
  final ValueChanged<String?> onChanged;
  final DropdownItemBuilder<String>? itemBuilder;
  final String? iconPath; // Add iconPath parameter

  @override
  Widget build(BuildContext context) {
    return _PhilippineDropdownView(
      choices: barangays,
      onChanged: onChanged,
      value: value,
      itemBuilder: (BuildContext context, e) {
        return itemBuilder?.call(context, e) ?? DropdownMenuItem(value: e, child: Text(e));
      },
      hint: Text(
        'Select Barangay',
        style: CustomTextStyles.titleMediumBluegray400,
      ),
      selectedItemBuilder: (BuildContext context, String value) {
        return Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white),
        );
      },
      prefix: iconPath != null
          ? Container(
        margin: EdgeInsets.fromLTRB(20.0, 20.0, 12.0, 20.0),
        child: CustomImageView(
          imagePath: iconPath!,
          height: 20.0,
          width: 20.0,
        ),
      )
          : null,
      prefixConstraints: BoxConstraints(maxHeight: 60.0),
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Match padding with CustomDropDown
    );
  }
}


