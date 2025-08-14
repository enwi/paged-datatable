import 'package:flutter/material.dart';

class FilterBarThemeData {
  /// The padding of the cell.
  final EdgeInsetsGeometry cellPadding; //

  /// The padding of a entire column, from other columns.
  final EdgeInsetsGeometry padding; //

  /// The filter bar's height.
  final double filterBarHeight; //

  /// The width breakpoint that [PagedDataTable] uses to decide if will render a popup or a bottom sheet when the filter dialog is requested.
  final double filterDialogBreakpoint; //

  /// The [ChipThemeData] to apply to filter chips.
  final ChipThemeData? chipTheme; //

  const FilterBarThemeData({
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.filterBarHeight = 50.0,
    this.filterDialogBreakpoint = 1000.0,
    this.chipTheme,
  });

  @override
  int get hashCode => Object.hash(cellPadding, padding, chipTheme);

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      (other is FilterBarThemeData &&
          other.cellPadding == cellPadding &&
          other.padding == padding &&
          other.chipTheme == chipTheme);
}
