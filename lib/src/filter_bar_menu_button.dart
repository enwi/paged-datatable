part of 'paged_datatable.dart';

/// Filter bar menu button
class FilterBarMenuButton {
  /// Filter bar menu button icon
  final IconData icon;

  /// Filter bar menu button tool tip
  final String? tooltip;

  /// Called when the filter menu remove button is pressed
  final void Function()? onRemoveFilters;

  /// Called when the filter menu cancel button is pressed
  final void Function()? onCancelFilters;

  /// Called when the filter menu apply button is pressed
  final void Function()? onApplyFilters;

  /// Filter bar menu button menu builder
  final Widget Function(BuildContext context) menuBuilder;

  FilterBarMenuButton({
    required this.icon,
    this.tooltip,
    required this.menuBuilder,
    this.onRemoveFilters,
    this.onCancelFilters,
    this.onApplyFilters,
  });
}
