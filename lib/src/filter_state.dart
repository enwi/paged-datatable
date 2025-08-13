part of 'paged_datatable.dart';

/// Represents the state of a [TableFilter].
final class FilterState<T extends Object> {
  final TableFilter<T> _filter;
  T? value;

  // Set the initial value to the filter's initial value.
  FilterState._(this._filter) : value = _filter.initialValue;
}
