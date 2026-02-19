import 'package:flutter/material.dart';

import '../constants.dart';

enum ScreenClass {
  phone,
  tabletPortrait,
  tabletLandscape,
  tabletUltraWide,
}

ScreenClass screenClassForWidth(double width) {
  if (width < AppConstants.phoneBreakpoint) return ScreenClass.phone;
  if (width < AppConstants.tabletPortraitBreakpoint) return ScreenClass.tabletPortrait;
  if (width < AppConstants.tabletUltraWideBreakpoint) return ScreenClass.tabletLandscape;
  return ScreenClass.tabletUltraWide;
}

extension ScreenClassX on ScreenClass {
  bool get isPhone => this == ScreenClass.phone;
  bool get isTabletPortrait => this == ScreenClass.tabletPortrait;
  bool get isTabletLandscape =>
      this == ScreenClass.tabletLandscape || this == ScreenClass.tabletUltraWide;
  bool get isUltraWide => this == ScreenClass.tabletUltraWide;
}

ScreenClass screenClassOf(BuildContext context) {
  return screenClassForWidth(MediaQuery.of(context).size.width);
}
